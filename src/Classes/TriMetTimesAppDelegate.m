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
#import "XMLDetours.h"
#import "UserFaves.h"
#import "StopView.h"
#import "DepartureTimesView.h"
#import "DebugLogging.h"
#import "AllRailStationView.h"
#import "AlarmNotification.h"
#import "AlarmTaskList.h"
#import <Twitter/TWTweetComposeViewController.h>
#import "WebViewController.h"
#import <CoreSpotlight/CoreSpotlight.h>

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
    
    [rootViewController release];
	[super dealloc];
}

#pragma mark Application methods

- (instancetype)init {
	if ((self = [super init])) 
    {
		 
	}
	return self;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self cleanExit];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    DEBUG_FUNC();
    bool newWindow = NO;
    
    [self cleanStart];
    
    if (!self.cleanExitLastTime)
    {
        rootViewController.lastArrivalsShown = nil;
        rootViewController.lastArrivalNames  = nil;
    }
    
    if ([UserPrefs singleton].autoCommute)
	{
        rootViewController.commuterBookmark  = [[SafeUserData singleton] checkForCommuterBookmarkShowOnlyOnce:YES];
	}
    
    [rootViewController executeInitialAction];

    
    AlarmTaskList *list = [AlarmTaskList singleton];
    [list resumeOnActivate];
    
    if (!newWindow && self.rootViewController)
    {
            UIViewController *topView = self.rootViewController.navigationController.topViewController;
        
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
        UIViewController *topView = self.rootViewController.navigationController.topViewController;
        
        if ([topView respondsToSelector:@selector(didEnterBackground)])
        {
            [topView performSelector:@selector(didEnterBackground)];
        }
    }
    
    AlarmTaskList *list = [AlarmTaskList singleton];
    [list checkForLongAlarms];
    [list updateBadge];
    
    [self cleanExit];
}

#pragma clang diagnostic pop

- (void)cleanExit
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
	
	[fileManager removeItemAtPath:self.pathToCleanExit error:NULL];
	
	SafeUserData *userData = [SafeUserData singleton];
	
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
		NSString * str = @"clean";
		[str writeToFile:self.pathToCleanExit atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	}
}


- (void)applicationDidFinishLaunching:(UIApplication *)application {
    DEBUG_FUNC();
   // [actualRootViewController initRootWindow];
    
	// Check for data in Documents directory. Copy default appData.plist to Documents if not found.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
	NSError *error = nil;
	
	if ([application respondsToSelector:@selector(cancelAllLocalNotifications)])
	{
		[application cancelAllLocalNotifications];
	}
    
	self.pathToCleanExit = [documentsDirectory stringByAppendingPathComponent:@"cleanExit.txt"];
	
    UIDevice* device = [UIDevice currentDevice];
    BOOL backgroundSupported = device.multitaskingSupported;
	
	NSString *oldDatabase1 = [documentsDirectory stringByAppendingPathComponent:kOldDatabase1];
	[fileManager removeItemAtPath:oldDatabase1 error:&error];
	
	NSString *oldDatabase2 = [documentsDirectory stringByAppendingPathComponent:kOldDatabase2];
	[fileManager removeItemAtPath:oldDatabase2 error:&error];
	

	DEBUG_PRINTF("Last arrivals %s clean %d\n", [rootViewController.lastArrivalsShown cStringUsingEncoding:NSUTF8StringEncoding],
				 self.cleanExitLastTime);
    


    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert
                                                                                             | UIUserNotificationTypeBadge
                                                                                             | UIUserNotificationTypeSound) categories:nil];
    [application registerUserNotificationSettings:settings];
    
    
    
    rootViewController.lastArrivalsShown = [SafeUserData singleton].last;
	rootViewController.lastArrivalNames  = [SafeUserData singleton].lastNames;
    
	if ((rootViewController.lastArrivalsShown!=nil && rootViewController.lastArrivalsShown.length == 0)
            || backgroundSupported
		)
	{
		rootViewController.lastArrivalsShown = nil;
		rootViewController.lastArrivalNames  = nil;
	}

    
    // Configure and show the window
    
    self.window = [[[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds] autorelease];
    
    self.window.rootViewController = self.rootViewController;
    
    // drawerController.closeDrawerGestureModeMask = MMCloseDrawerGestureModeTapCenterView | MMCloseDrawerGestureModeTapNavigationBar;

    
    window.rootViewController = self.navigationController ;
    
    NSArray *windows = [UIApplication sharedApplication].windows;
    for(UIWindow *win in windows) {
        DEBUG_LOG(@"window: %@",win.description);
        if(win.rootViewController == nil){
            UIViewController* vc = [[UIViewController alloc]initWithNibName:nil bundle:nil];
            win.rootViewController = vc;
        }
    }
    
   	[window makeKeyAndVisible];
		
#if defined(MAXCOLORS) && defined(CREATE_MAX_ARRAYS)
    AllRailStationView *station = [AllRailStationView viewController];
    
	[station generateArrays];
#endif
}

- (void)applicationWillTerminate:(UIApplication *)application {
	
    [self cleanExit];
	[StopLocations quit];
}

- (BOOL)application:(UIApplication *)application willContinueUserActivityWithType:(NSString *)userActivityType
{
    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray * __nullable restorableObjects))restorationHandler
{
    DEBUG_FUNC();
    
    if ([userActivity.activityType isEqualToString:CSSearchableItemActionType])
    {
        self.rootViewController.initialActionArgs = userActivity.userInfo;
        
        self.rootViewController.initialAction = InitialAction_UserActivitySearch;
        
        if (rootViewController != nil)
        {
            [rootViewController executeInitialAction];
        }
    }
    else if ([userActivity.activityType isEqualToString:kHandoffUserActivityBookmark])
    {
    
        self.rootViewController.initialActionArgs = userActivity.userInfo;
    
        self.rootViewController.initialAction = InitialAction_UserActivityBookmark;
    
        if (rootViewController != nil)
        {
            [rootViewController executeInitialAction];
        }
    }
    
    return YES;
}

- (void)application:(UIApplication *)application didFailToContinueUserActivityWithType:(NSString *)userActivityType error:(NSError *)error
{
    
}

- (void)application:(UIApplication *)application
performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
  completionHandler:(void (^)(BOOL succeeded))completionHandler
{
    self.rootViewController.initialActionArgs = shortcutItem.userInfo;
    
    self.rootViewController.initialAction = InitialAction_UserActivityBookmark;
    
    if (rootViewController != nil)
    {
        [rootViewController executeInitialAction];
    }
    
    completionHandler(YES);
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
    
    
    
	NSString *strUrl = url.absoluteString;
	
	// we bound the length of the URL to 15K.  This is really big!
	if (strUrl.length > 15 * 1024)
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
	
	if (!scanner.atEnd)
	{
		scanner.scanLocation++;
		
		while (!scanner.atEnd)
		{	
			// Sometimes we get NO back when there are two slashes in a row, skip that case
			if ([scanner scanUpToCharactersFromSet:slash intoString:&section] && ![self processURL:section protocol:protocol])
			{
				break;
			}
			
			if (!scanner.atEnd)
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
	
	if (url.length == 0)
	{
		return YES;
	}
	
	
	NSString * name = nil;

	[scanner scanUpToCharactersFromSet:query intoString:&name];
	
	if (!scanner.atEnd)
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
    NSMutableDictionary *launchArgs = [NSMutableDictionary dictionary];
    
    NSCharacterSet *delim = [NSCharacterSet characterSetWithCharactersInString:@"&"];
    NSCharacterSet *equals = [NSCharacterSet characterSetWithCharactersInString:@"="];
    
    
    while (!scanner.atEnd)
    {
        NSString *option = nil;
        [scanner scanUpToCharactersFromSet:equals intoString:&option];
        
        if (!scanner.atEnd)
        {
            scanner.scanLocation++;
            NSString *value = nil;
            [scanner scanUpToCharactersFromSet:delim intoString:&value];
            
            if (option!=nil && value!=nil)
            {
                launchArgs[option] = value;
            }
            
            if (!scanner.atEnd)
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
        
        if (!scanner.atEnd)
        {
            scanner.scanLocation++;
    
            [self processLaunchArgs:scanner];
        }
    }
    else if ([token caseInsensitiveCompare:@"commute"]==NSOrderedSame)
    {
        self.rootViewController.initialAction = InitialAction_Commute;
    }
    else if ([token caseInsensitiveCompare:@"bookmark"]==NSOrderedSame && !scanner.atEnd)
    {
        scanner.scanLocation++;
        
        if (!scanner.atEnd)
        {
            NSString *bookmarkName = nil;
            [scanner scanUpToCharactersFromSet:blankSet intoString:&bookmarkName];
            self.rootViewController.initialBookmarkName = [bookmarkName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
    }
    else if ([token caseInsensitiveCompare:@"bookmarknumber"]==NSOrderedSame && !scanner.atEnd)
    {
        scanner.scanLocation++;
        
        if (!scanner.atEnd)
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
        if ([self.navigationController.topViewController isKindOfClass:[WebViewController class]])
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    return YES;
}

- (BOOL)processStopFromURL:(NSString *)stops
{
    DEBUG_FUNC();
	if (stops.length == 0)
	{
		return YES;
	}
	
	NSMutableString *safeStopString = [NSMutableString string];
    
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
	
	if (bookmark.length == 0)
	{
		return YES;
	}
	
	NSString * name = nil;
	NSString * stops = nil;
	
	[scanner scanUpToCharactersFromSet:query intoString:&name];
	
	if (!scanner.atEnd)
	{
		stops = [bookmark substringFromIndex:scanner.scanLocation+1];
	}
	
	SafeUserData *userData = [SafeUserData singleton];
	
	// If this is an encoded dictionary we have to decode it
	if ([stops characterAtIndex:0] == 'd' && [protocol isEqualToString:@"pdxbus2:"])
	{
		DEBUG_LOG(@"dictionary");
		NSMutableData *encodedDictionary = [[[NSMutableData alloc] initWithCapacity:stops.length / 2] autorelease];
	
		unsigned char byte;
		
		for (int i=1; i< stops.length; i+=2)
		{
            unsigned char c0 = [stops characterAtIndex:i];
            unsigned char c1 = [stops characterAtIndex:i+1];
            
			byte = HEX_DIGIT(c0) * 16 + HEX_DIGIT(c1);
			[encodedDictionary appendBytes:&byte length:1];
		}
		NSError *error = nil;
		NSPropertyListFormat fmt = NSPropertyListBinaryFormat_v1_0;
		
		DEBUG_LOG(@"Stops: %@ %ld data length %ld stops/2 %ld\n", stops, (unsigned long)stops.length, (unsigned long)encodedDictionary.length, (unsigned long)stops.length/2);
		
		
		NSMutableDictionary *d = nil;
		
        d = [NSPropertyListSerialization propertyListWithData:encodedDictionary
														  options:NSPropertyListMutableContainers 
														   format:&fmt 
															error:&error];

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
			if (name == nil || name.length == 0)
			{
				name = kNewBookMark;
			}
	
			if (stops !=nil && stops.length!=0 && userData.faves.count < kMaxFaves)
			{
				rootViewController = nil;

				NSString *fullName = [name stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
		
                NSMutableDictionary * newFave = [NSMutableDictionary dictionary];
				newFave[kUserFavesChosenName] = fullName;
				newFave[kUserFavesLocation] = stops;
				[userData.faves addObject:newFave];                
			}
		}
	}
    
    [userData cacheAppData];
	
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

+ (TriMetTimesAppDelegate*)singleton
{
	return (TriMetTimesAppDelegate *)[UIApplication sharedApplication].delegate;
}





@end
