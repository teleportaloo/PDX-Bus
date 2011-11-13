//
//  TriMetTimesAppDelegate.m
//  TriMetTimes
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"
#import "RootViewController.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "XMLDepartures.h"
#import "XMLRoutes.h"
#import "XMLStops.h"
#import "XMLDetour.h"
#import "UserFaves.h"
#import "StopView.h"
#import "DepartureTimesView.h"
#import "debug.h"
#import "AllRailStationView.h"
#import "AlarmNotification.h"
#import "AlarmTaskList.h"

@implementation TriMetTimesAppDelegate


@synthesize window;
@synthesize navigationController;

@synthesize streetcarMapping		= _streetcarMapping;
@synthesize rootViewController;
@synthesize cleanExitLastTime		= _cleanExitLastTime;
@synthesize pathToCleanExit			= _pathToCleanExit;
@synthesize prefs				    = _prefs;



- (void)dealloc {
	//	[departureList release];
	//	[pathToUserCopyOfPlist release];
	self.navigationController = nil;
	//	[userFaves release];
	[window release];
	[activityView release];
	self.pathToCleanExit = nil;
	self.prefs = nil;

	[super dealloc];
}

#pragma mark Application methods

- (id)init {
	if ((self = [super init])) 
    {
		// 
		activityView = nil;
		self.prefs = [[[UserPrefs alloc] init] autorelease];
	}
	return self;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    bool newWindow = NO;
    
	if (!_suppressCommuterBookmarkOnActivate && self.rootViewController && self.rootViewController.commuterBookmark==nil
		&& _prefs.autoCommute)
	{
		NSDictionary *commuterFave = [self checkForCommuterBookmarkShowOnlyOnce:YES];
	
		if (commuterFave != nil)
		{
			[[self.rootViewController navigationController] popToRootViewControllerAnimated:NO];
		
			DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
			
			[departureViewController fetchTimesForLocationInBackground:self.rootViewController.backgroundTask 
																   loc:[commuterFave valueForKey:kUserFavesLocation]
																 title:[commuterFave valueForKey:kUserFavesChosenName]
			 ];
			[departureViewController release];
            
            newWindow = YES;
		
		}
	}
	_suppressCommuterBookmarkOnActivate = NO;
    
    AlarmTaskList *list = [AlarmTaskList getSingleton];
    [list resumeOnActivate];
    
    if (!newWindow && self.rootViewController)
    {
        UIViewController *topView = [self.rootViewController.navigationController topViewController];
        
        if ([topView respondsToSelector:@selector(didBecomeActive)])
        {
            [topView performSelector:@selector(didBecomeActive)];
        }
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    if (self.rootViewController)
    {
        UIViewController *topView = [self.rootViewController.navigationController topViewController];
        
        if ([topView respondsToSelector:@selector(didEnterBackground)])
        {
            [topView performSelector:@selector(didEnterBackground)];
        }
    }
}


- (void)applicationDidFinishLaunching:(UIApplication *)application {
	
	// Check for data in Documents directory. Copy default appData.plist to Documents if not found.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
	NSError *error = nil;
	
	if ([application respondsToSelector:@selector(cancelAllLocalNotifications)])
	{
		[application cancelAllLocalNotifications];
	}
	self.pathToCleanExit = [documentsDirectory stringByAppendingPathComponent:@"cleanExit.txt"];
	
	if ([fileManager fileExistsAtPath:self.pathToCleanExit] == YES)
	{
		self.cleanExitLastTime = NO;
	}
	else 
	{
		self.cleanExitLastTime = YES;
		NSString * str = [[[NSString alloc] initWithString:@"clean"] autorelease];
		
		[str writeToFile:self.pathToCleanExit atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	}
	
	NSString *oldDatabase1 = [documentsDirectory stringByAppendingPathComponent:kOldDatabase1];
	[fileManager removeItemAtPath:oldDatabase1 error:&error];
	
	NSString *oldDatabase2 = [documentsDirectory stringByAppendingPathComponent:kOldDatabase2];
	[fileManager removeItemAtPath:oldDatabase2 error:&error];
	

	DEBUG_PRINTF("Last arrivals %s clean %d\n", [rootViewController.lastArrivalsShown cStringUsingEncoding:NSUTF8StringEncoding],
				 self.cleanExitLastTime);
	
	
	rootViewController.lastArrivalsShown = [SafeUserData getSingleton].last;
	rootViewController.lastArrivalNames  = [SafeUserData getSingleton].lastNames;
	
	if (_prefs.autoCommute)
	{
		rootViewController.commuterBookmark  = [self checkForCommuterBookmarkShowOnlyOnce:YES];
	}
	
	if ((rootViewController.lastArrivalsShown!=nil && [rootViewController.lastArrivalsShown length] == 0)
		 || !self.cleanExitLastTime
		)
	{
		rootViewController.lastArrivalsShown = nil;
		rootViewController.lastArrivalNames  = nil;
	}

	

	// Configure and show the window
	[window addSubview:[navigationController view]];
	[window makeKeyAndVisible];
		
#if defined(MAXCOLORS) && defined(CREATE_MAX_ARRAYS)
	AllRailStationView *station = [[[AllRailStationView alloc] init] autorelease];
	
	[station generateArrays];
#endif
	
	_suppressCommuterBookmarkOnActivate = YES;
	
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Save data if appropriate
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	[fileManager removeItemAtPath:self.pathToCleanExit error:NULL];
	
	SafeUserData *userData = [SafeUserData getSingleton];
	
	[userData cacheAppData];
	
	[StopLocations quit];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{   
	
	// Debugger();
	// BOOL more = NO;
    // while (more) {
    //     [NSThread sleepForTimeInterval:1.0]; // Set break point on this line
    // }
	
    // And here is the real code for 'handleOpenURL'
    // Set a breakpoint here as well.
	
	
    // You should be extremely careful when handling URL requests.
    // You must take steps to validate the URL before handling it.
    
    if (!url) {
        // The URL is nil. There's nothing more to do.
        return NO;
    }
    
	NSString *strUrl = [url absoluteString];
	
	// we bound the length of the URL to 15K.  This is really big!
	if ([strUrl length] > 15 * 1024)
	{
		return NO;
	}
	
	NSScanner *scanner = [NSScanner scannerWithString:strUrl];
	NSCharacterSet *slash = [NSCharacterSet characterSetWithCharactersInString:@"/"];
	NSString *bookmark;
	
	// skip up to first slash
	[scanner scanUpToCharactersFromSet:slash intoString:&bookmark];
	
	if (![scanner isAtEnd])
	{
		[scanner setScanLocation:[scanner scanLocation]+1];
		
		while (![scanner isAtEnd])
		{	
			// Sometimes we get NO back when there are two slashes in a row, skip that case
			if ([scanner scanUpToCharactersFromSet:slash intoString:&bookmark] && ![self processBookMarkFromURL:bookmark])
			{
				break;
			}
			
			if (![scanner isAtEnd])
			{
				[scanner setScanLocation:[scanner scanLocation]+1];
			}
		}	
	}
	
	if (rootViewController != nil)
	{
		[rootViewController reloadData];
	}
	
    return YES;
}

#pragma mark Application Helper functions


-(void)loadStreetcarMapping
{
	if (self.streetcarMapping == nil)
	{
		self.streetcarMapping = [[[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PortlandStreetcar" ofType:@"plist"]] autorelease];
	}
}

- (NSString *)getStreetcarRoute
{
	[self loadStreetcarMapping];
	return [self.streetcarMapping  objectForKey:@"route"];
}


- (NSDictionary *)getStreetcarPlatforms
{
	[self loadStreetcarMapping];
	
	return [self.streetcarMapping  objectForKey:@"platforms"];
	
}
- (NSDictionary *)getStreetcarDirections
{
	[self loadStreetcarMapping];

	return [self.streetcarMapping  objectForKey:@"directions"];
}

- (NSDictionary *)getStreetcarShortNames
{
	[self loadStreetcarMapping];
	
	return [self.streetcarMapping  objectForKey:@"shortnames"];
	
}

-(void)hideActivityViewer
{
	[[[activityView subviews] objectAtIndex:0] stopAnimating];
	[activityView removeFromSuperview];
	activityView = nil;
}

-(void)showActivityViewer
{
	[activityView release];
	activityView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, window.bounds.size.width, window.bounds.size.height)];
	activityView.backgroundColor = [UIColor blackColor];
	activityView.alpha = 0.5;
	
	UIActivityIndicatorView *activityWheel = [[UIActivityIndicatorView alloc] initWithFrame: CGRectMake(window.bounds.size.width / 2 - 12, window.bounds.size.height / 2 - 12, 24, 24)];
	activityWheel.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
	activityWheel.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
									  UIViewAutoresizingFlexibleRightMargin |
									  UIViewAutoresizingFlexibleTopMargin |
									  UIViewAutoresizingFlexibleBottomMargin);
	[activityView addSubview:activityWheel];
	[activityWheel release];
	
	
//	UILabel *text = [[[UILabel alloc] initWithFrame:CGRectMake(window.bounds.size.width / 2 - 30, window.bounds.size.height / 2 - 30,100 ,35)] autorelease];
//	[activityView addSubview: text];
	
	[window addSubview: activityView];
	[activityView release];
	
	[[[activityView subviews] objectAtIndex:0] startAnimating];
	
//	return text;
}






#define HEX_DIGIT(B) (B <= '9' ?  (B)-'0' : (( (B) < 'G' ) ? (B) - 'A' + 10 : (B) - 'a' + 10))

- (BOOL)processBookMarkFromURL:(NSString *)bookmark
{
	NSScanner *scanner = [NSScanner scannerWithString:bookmark];
	NSCharacterSet *query = [NSCharacterSet characterSetWithCharactersInString:@"?"];
	
	if ([bookmark length] == 0)
	{
		return YES;
	}
	
	
	NSString * name = nil;
	NSString * stops = nil;
	
	[scanner scanUpToCharactersFromSet:query intoString:&name];
	
	if (![scanner isAtEnd])
	{
		stops = [bookmark substringFromIndex:[scanner scanLocation]+1];
	}
	
	SafeUserData *userData = [SafeUserData getSingleton];
	
	// If this is an encoded dictionary we have to decode it
	if ([stops characterAtIndex:0] == 'd')
	{
		DEBUG_LOG(@"dictionary");
		NSMutableData *encodedDictionary = [[[NSMutableData alloc] initWithCapacity:stops.length / 2] autorelease];
	
		char byte;
		
		for (int i=1; i< stops.length; i+=2)
		{
			byte = HEX_DIGIT([stops characterAtIndex:i]) * 16 + HEX_DIGIT([stops characterAtIndex:i+1]);
			[encodedDictionary appendBytes:&byte length:1];
		}
		NSError *error = nil;
		NSPropertyListFormat fmt = NSPropertyListXMLFormat_v1_0;
		
		DEBUG_LOG(@"Stops: %@ %d data length %d stops/2 %d\n", stops, stops.length, encodedDictionary.length, stops.length/2);
		
		
		
		// Check for versions of iOS as this serialization selector has been depricated!
		NSMutableDictionary *d = nil;
		
		// iOS4 version of the selector
		if ([d respondsToSelector:@selector(propertyListWithData:options:format:error:)])
		{
			d = [NSPropertyListSerialization propertyListWithData:encodedDictionary 
														  options:NSPropertyListMutableContainers 
														   format:&fmt 
															error:&error];
		}
		else // iOS3 version
		{
			NSString *errStr = nil;
			d = [NSPropertyListSerialization propertyListFromData:encodedDictionary
												 mutabilityOption:NSPropertyListMutableContainers
														   format:&fmt
												 errorDescription:&errStr];
		}

		
		if (d!=nil)
		{
			@synchronized (userData)
			{
				[userData.faves addObject:d];
			}
		}
	}
	else 
	{
		@synchronized (userData)
		{
			if (name == nil || [name length] == 0)
			{
				name = kNewBookMark;
			}
	
			if (stops !=nil && [stops length]!=0 && [userData.faves count] < kMaxFaves)
			{
				rootViewController.lastArrivalsShown = nil;

				NSString *fullName = [name stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
		
				NSMutableDictionary * newFave = [[ NSMutableDictionary alloc ] init];
				[newFave setObject:fullName forKey:kUserFavesChosenName];
				[newFave setObject:stops forKey:kUserFavesLocation];
				[userData.faves addObject:newFave];
				[newFave release];
			}
		}
	}
	
	return YES;
}

- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notif 
{
	AlarmNotification *notify = [[AlarmNotification alloc] init];
	
	UIApplicationState previousState = app.applicationState;
	
	notify.previousState = previousState;
	
	[notify application:app didReceiveLocalNotification:notif];
	
	[notify release];
	
	if (previousState != UIApplicationStateActive)
	{
		_suppressCommuterBookmarkOnActivate = YES;
	}
}

+ (TriMetTimesAppDelegate*)getSingleton
{
	return (TriMetTimesAppDelegate *)[[UIApplication sharedApplication] delegate];
}

#define IS_MORNING(hour) (hour<12)

- (NSDictionary *)checkForCommuterBookmarkShowOnlyOnce:(bool)onlyOnce
{
	SafeUserData *userData			 = [SafeUserData getSingleton];
	NSDate *lastRun					 = [userData.lastRun retain];
	NSDate *now						 = [NSDate date];
	userData.lastRun				 = now;
	bool firstRunInPeriod			 = YES;
	unsigned unitFlags				 = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | kCFCalendarUnitHour | kCFCalendarUnitWeekday;
	NSCalendar       *cal			 = [NSCalendar currentCalendar];
	NSDateComponents *nowComponents  = [cal components:(NSUInteger)unitFlags fromDate:now];
	
	if (lastRun != nil)
	{
		NSDateComponents *lastComponents = [cal components:(NSUInteger)unitFlags fromDate:lastRun];
	
		if (
				lastComponents.year  == nowComponents.year 
			&&	lastComponents.month == nowComponents.month
			&&  lastComponents.day	 == nowComponents.day
			&&  IS_MORNING(lastComponents.hour) == IS_MORNING(nowComponents.hour) )
		{
			firstRunInPeriod = NO;
		}
		[lastRun release];
	}
	
	if (!onlyOnce || firstRunInPeriod)
	{		
		int todayBit = (0x1 << nowComponents.weekday);
		
		NSArray *faves = [userData faves];
		for (NSDictionary * fave in faves)
		{
			NSNumber *dow = [fave objectForKey:kUserFavesDayOfWeek];
			NSNumber *am  = [fave objectForKey:kUserFavesMorning];
			if (dow && [fave objectForKey:kUserFavesLocation]!=nil)
			{
				// does the day of week match our day of week?
				if (([dow intValue] & todayBit) !=0)
				{
					// Does AM match or PM match?
					if ((  (am == nil ||   [am boolValue]) &&  IS_MORNING(nowComponents.hour))
						 || (![am boolValue] && !IS_MORNING(nowComponents.hour)))
					{
						return [[fave retain] autorelease];
					}
				}
			}
		}
		
		// Didn't find anything - set this to nil just in case the user sets one up 
		userData.lastRun = nil;
	}
	return nil;
}


@end
