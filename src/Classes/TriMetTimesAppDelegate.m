//
//  TriMetTimesAppDelegate.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


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
#import "DebugLogging.h"
#import "AllRailStationView.h"
#import "AlarmNotification.h"
#import "AlarmTaskList.h"
#import <Twitter/TWTweetComposeViewController.h>
#import "WebViewController.h"

@implementation TriMetTimesAppDelegate


@synthesize window;
@synthesize navigationController;


@synthesize rootViewController;
@synthesize cleanExitLastTime		= _cleanExitLastTime;
@synthesize pathToCleanExit			= _pathToCleanExit;

- (void)dealloc {
	//	[departureList release];
	//	[pathToUserCopyOfPlist release];
	self.navigationController = nil;
	//	[userFaves release];
    [window release];
	self.pathToCleanExit = nil;

	[super dealloc];
}

#pragma mark Application methods

- (id)init {
	if ((self = [super init])) 
    {
		 
	}
	return self;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self cleanExit];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    DEBUG_LOG(@"applicationDidBecomeActive\n");
    bool newWindow = NO;
    
    [self cleanStart];
    
    if (!self.cleanExitLastTime)
    {
        rootViewController.lastArrivalsShown = nil;
        rootViewController.lastArrivalNames  = nil;
    }
    
    if ([UserPrefs getSingleton].autoCommute)
	{
        rootViewController.commuterBookmark  = [self checkForCommuterBookmarkShowOnlyOnce:YES];
	}
    
    [rootViewController executeInitialAction];

    
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
    
    AlarmTaskList *list = [AlarmTaskList getSingleton];
    [list checkForLongAlarms];
    [list updateBadge];
    
    [self cleanExit];
}

- (void)cleanExit
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
	
	[fileManager removeItemAtPath:self.pathToCleanExit error:NULL];
	
	SafeUserData *userData = [SafeUserData getSingleton];
	
	[userData cacheAppData];
}

- (void)cleanStart
{
    NSFileManager *fileManager = [NSFileManager defaultManager];

	if ([fileManager fileExistsAtPath:self.pathToCleanExit] == YES)
	{
		self.cleanExitLastTime = NO;
        
        // If the app crashed we should assume the cache file may be bad
        // best to delete it just in case.
        [TriMetXML deleteCacheFile];
	}
	else 
	{
		self.cleanExitLastTime = YES;
		NSString * str = [[[NSString alloc] initWithString:@"clean"] autorelease];
		
		[str writeToFile:self.pathToCleanExit atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	}
  
}


- (void)applicationDidFinishLaunching:(UIApplication *)application {
    DEBUG_LOG(@"applicationDidFinishLaunching\n");
    
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
	
    UIDevice* device = [UIDevice currentDevice];
    BOOL backgroundSupported = NO;
    if ([device respondsToSelector:@selector(isMultitaskingSupported)])
        backgroundSupported = device.multitaskingSupported;
	
	NSString *oldDatabase1 = [documentsDirectory stringByAppendingPathComponent:kOldDatabase1];
	[fileManager removeItemAtPath:oldDatabase1 error:&error];
	
	NSString *oldDatabase2 = [documentsDirectory stringByAppendingPathComponent:kOldDatabase2];
	[fileManager removeItemAtPath:oldDatabase2 error:&error];
	

	DEBUG_PRINTF("Last arrivals %s clean %d\n", [rootViewController.lastArrivalsShown cStringUsingEncoding:NSUTF8StringEncoding],
				 self.cleanExitLastTime);
    
    rootViewController.lastArrivalsShown = [SafeUserData getSingleton].last;
	rootViewController.lastArrivalNames  = [SafeUserData getSingleton].lastNames;
    
	if ((rootViewController.lastArrivalsShown!=nil && [rootViewController.lastArrivalsShown length] == 0)
            || backgroundSupported
		)
	{
		rootViewController.lastArrivalsShown = nil;
		rootViewController.lastArrivalNames  = nil;
	}

    
    // Configure and show the window
    
    // self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [self.window setRootViewController:self.rootViewController];
    
    // drawerController.closeDrawerGestureModeMask = MMCloseDrawerGestureModeTapCenterView | MMCloseDrawerGestureModeTapNavigationBar;

    
    window.rootViewController = self.navigationController ;
    
   	[window makeKeyAndVisible];
		
#if defined(MAXCOLORS) && defined(CREATE_MAX_ARRAYS)
	AllRailStationView *station = [[[AllRailStationView alloc] init] autorelease];
    
	[station generateArrays];
#endif
}

- (void)applicationWillTerminate:(UIApplication *)application {
	
    [self cleanExit];
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
    
    Class dirClass = (NSClassFromString(@"MKDirectionsRequest"));
        
    if (dirClass && [MKDirectionsRequest isDirectionsRequestURL:url]) {
        rootViewController.routingURL = url;
        return YES;
    }
    
    
    
	NSString *strUrl = [url absoluteString];
	
	// we bound the length of the URL to 15K.  This is really big!
	if ([strUrl length] > 15 * 1024)
	{
		return NO;
	}
	
	NSScanner *scanner = [NSScanner scannerWithString:strUrl];
	NSCharacterSet *slash = [NSCharacterSet characterSetWithCharactersInString:@"/"];
	NSString *section;
    NSString *protocol;
	
	// skip up to first slash
	[scanner scanUpToCharactersFromSet:slash intoString:&protocol];
    
    if ([protocol caseInsensitiveCompare:@"pdxbusroute:"]==NSOrderedSame)
    {
        rootViewController.routingURL = url;
        return YES;
    }
	
	if (![scanner isAtEnd])
	{
		scanner.scanLocation++;
		
		while (![scanner isAtEnd])
		{	
			// Sometimes we get NO back when there are two slashes in a row, skip that case
			if ([scanner scanUpToCharactersFromSet:slash intoString:&section] && ![self processURL:section protocol:protocol])
			{
				break;
			}
			
			if (![scanner isAtEnd])
			{
				scanner.scanLocation++;
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



#define HEX_DIGIT(B) (B <= '9' ?  (B)-'0' : (( (B) < 'G' ) ? (B) - 'A' + 10 : (B) - 'a' + 10))

- (BOOL)processURL:(NSString *)url protocol:(NSString *)protocol
{
    NSScanner *scanner = [NSScanner scannerWithString:url];
	NSCharacterSet *query = [NSCharacterSet characterSetWithCharactersInString:@"?"];
	
	if ([url length] == 0)
	{
		return YES;
	}
	
	
	NSString * name = nil;

	[scanner scanUpToCharactersFromSet:query intoString:&name];
	
	if (![scanner isAtEnd])
	{
		return [self processBookMarkFromURL:url protocol:protocol];
	}
    else if (isalpha([url characterAtIndex:0]))
    {
       return [self processCommandFromURL:url];
    }
    
    return [self processStopFromURL:name];
}

- (void)processLaunchArgs:(NSScanner*)scanner
{
    NSMutableDictionary *launchArgs = [[[NSMutableDictionary alloc] init] autorelease];
    
    NSCharacterSet *delim = [NSCharacterSet characterSetWithCharactersInString:@"&"];
    NSCharacterSet *equals = [NSCharacterSet characterSetWithCharactersInString:@"="];
    
    
    while (![scanner isAtEnd])
    {
        NSString *option = nil;
        [scanner scanUpToCharactersFromSet:equals intoString:&option];
        
        if (![scanner isAtEnd])
        {
            scanner.scanLocation++;
            NSString *value = nil;
            [scanner scanUpToCharactersFromSet:delim intoString:&value];
            
            if (option!=nil && value!=nil)
            {
                [launchArgs setObject:value
                               forKey:option];
            }
            
            if (![scanner isAtEnd])
            {
                scanner.scanLocation++;
            }
        }
    }
    self.rootViewController.initialActionArgs = launchArgs;
}

- (BOOL)processCommandFromURL:(NSString *)command
{
    NSScanner *scanner = [NSScanner scannerWithString:command];
    NSCharacterSet *delim = [NSCharacterSet characterSetWithCharactersInString:@"=&"];
    NSString * token = nil;
    NSCharacterSet *blankSet = [[[NSCharacterSet alloc] init] autorelease];
    
	[scanner scanUpToCharactersFromSet:delim intoString:&token];
        
    if (token==nil)
    {
        return YES;
    }
    else if ([token caseInsensitiveCompare:@"locate"]==NSOrderedSame || [token caseInsensitiveCompare:@"nearby"]==NSOrderedSame)
    {
        
        self.rootViewController.initialAction = InitialAction_Locate;
        
        if (![scanner isAtEnd])
        {
            scanner.scanLocation++;
    
            [self processLaunchArgs:scanner];
        }
    }
    else if ([token caseInsensitiveCompare:@"commute"]==NSOrderedSame)
    {
        self.rootViewController.initialAction = InitialAction_Commute;
    }
    else if ([token caseInsensitiveCompare:@"bookmark"]==NSOrderedSame && ![scanner isAtEnd])
    {
        scanner.scanLocation++;
        
        if (![scanner isAtEnd])
        {
            NSString *bookmarkName = nil;
            [scanner scanUpToCharactersFromSet:blankSet intoString:&bookmarkName];
            self.rootViewController.initialBookmarkName = [bookmarkName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
    }
    else if ([token caseInsensitiveCompare:@"bookmarknumber"]==NSOrderedSame && ![scanner isAtEnd])
    {
        scanner.scanLocation++;
        
        if (![scanner isAtEnd])
        {
            int bookmarkNumber=0;
            if ([scanner scanInt:&bookmarkNumber])
            {
                    self.rootViewController.initialBookmarkIndex = bookmarkNumber;
                    self.rootViewController.initialAction = InitialAction_BookmarkIndex;
            }
        }
    }
    else if ([token caseInsensitiveCompare:@"tripplanner"]==NSOrderedSame)
    {
         self.rootViewController.initialAction = InitialAction_TripPlanner;
    }
    else if ([token caseInsensitiveCompare:@"qrcode"]==NSOrderedSame)
    {
        self.rootViewController.initialAction = InitialAction_QRCode;
    }
    else if ([token caseInsensitiveCompare:@"back"]==NSOrderedSame)
    {
        if ([[self.navigationController topViewController] isKindOfClass:[WebViewController class]])
        {
            [[self navigationController] popViewControllerAnimated:YES];
        }
    }
    return YES;
}

- (BOOL)processStopFromURL:(NSString *)stops
{
    DEBUG_LOG(@"processStopFromURL\n");
	if ([stops length] == 0)
	{
		return YES;
	}
	
	NSMutableString *safeStopString = [[[NSMutableString alloc] init] autorelease];
    
    int i;
    unichar item;
    for (i=0; i<stops.length; i++)
    {
        item = [stops characterAtIndex:i];
        if (item == ',' || (item <= '9' && item >= '0'))
        {
            [safeStopString appendFormat:@"%c", item];
        }
    }
    
    self.rootViewController.launchStops = safeStopString;
    
	return YES;
}

- (BOOL)processBookMarkFromURL:(NSString *)bookmark protocol:(NSString *)protocol
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
	if ([stops characterAtIndex:0] == 'd' && [protocol isEqualToString:@"pdxbus2:"])
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
		
		DEBUG_LOG(@"Stops: %@ %ld data length %ld stops/2 %ld\n", stops, (unsigned long)stops.length, (unsigned long)encodedDictionary.length, (unsigned long)stops.length/2);
		
		
		
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
	else if ([stops characterAtIndex:0] != 'd')
	{
		@synchronized (userData)
		{
			if (name == nil || [name length] == 0)
			{
				name = kNewBookMark;
			}
	
			if (stops !=nil && [stops length]!=0 && [userData.faves count] < kMaxFaves)
			{
				rootViewController = nil;

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
					if ((   (am == nil ||  [am boolValue]) &&  IS_MORNING(nowComponents.hour))
						 || (am != nil && ![am boolValue]  && !IS_MORNING(nowComponents.hour)))
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
