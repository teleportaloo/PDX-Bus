//
//  PDXBusAppDelegate.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "PDXBusAppDelegate+Methods.h"
#import "RootViewController.h"
#import <SystemConfiguration/SystemConfiguration.h>
#import "XMLDepartures.h"
#import "XMLRoutes.h"
#import "XMLStops.h"
#import "XMLDetours.h"
#import "UserState.h"
#import "StopView.h"
#import "DepartureTimesView.h"
#import "DebugLogging.h"
#import "AllRailStationView.h"
#import "AlarmNotification.h"
#import "AlarmTaskList.h"
#import "WebViewController.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import "KMLRoutes.h"
#import "ArrivalsIntent.h"
#import "FindByLocationView.h"

#if TARGET_OS_MACCATALYST
#import <UserNotifications/UserNotifications.h>
#endif


@implementation PDXBusAppDelegate

#pragma mark Application methods

- (instancetype)init {
    if ((self = [super init])) {
    }
    
    return self;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [self cleanExit];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

- (void)applicationDidBecomeActive:(UIApplication *)application {
    DEBUG_FUNC();
    bool newWindow = NO;
    
    [self cleanStart];
    
    if (!self.cleanExitLastTime) {
        self.rootViewController.lastArrivalsShown = nil;
        self.rootViewController.lastArrivalNames = nil;
    }
    
    if (Settings.autoCommute) {
        self.rootViewController.commuterBookmark = [UserState.sharedInstance checkForCommuterBookmarkShowOnlyOnce:YES];
    }
    
    [self.rootViewController executeInitialAction];
    
    
    AlarmTaskList *list = [AlarmTaskList sharedInstance];
    
    [list resumeOnActivate];
    
    if (!newWindow && self.rootViewController) {
        UIViewController *topView = self.rootViewController.navigationController.topViewController;
        
        if ([topView respondsToSelector:@selector(didBecomeActive)]) {
            [topView performSelector:@selector(didBecomeActive)];
        }
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    if (self.rootViewController) {
        UIViewController *topView = self.rootViewController.navigationController.topViewController;
        
        if ([topView respondsToSelector:@selector(didEnterBackground)]) {
            [topView performSelector:@selector(didEnterBackground)];
        }
    }
    
    AlarmTaskList *list = [AlarmTaskList sharedInstance];
    
    [list updateBadge];
    
    [self cleanExit];
}

#pragma clang diagnostic pop

- (void)cleanExit {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    [fileManager removeItemAtPath:self.pathToCleanExit error:NULL];
    
    UserState *userData = UserState.sharedInstance;
    
    [userData cacheState];
}

- (void)cleanStart {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:self.pathToCleanExit] == YES) {
        self.cleanExitLastTime = NO;
        
        // If the app crashed we should assume the cache file may be bad
        // best to delete it just in case.
        [TriMetXML deleteCacheFile];
        [KMLRoutes deleteCacheFile];
    } else {
        self.cleanExitLastTime = YES;
        NSString *str = @"clean";
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

   
    
    self.pathToCleanExit = [documentsDirectory stringByAppendingPathComponent:@"cleanExit.txt"];
    
    UIDevice *device = [UIDevice currentDevice];
    BOOL backgroundSupported = device.multitaskingSupported;
    
    NSString *oldSql = @"railLocations.sql";
    
    NSString *oldDatabase1 = [documentsDirectory stringByAppendingPathComponent:oldSql];
    
    [fileManager removeItemAtPath:oldDatabase1 error:&error];
    
    
    DEBUG_PRINTF("Last departure %s clean %d\n", [self.rootViewController.lastArrivalsShown cStringUsingEncoding:NSUTF8StringEncoding],
                 self.cleanExitLastTime);
    
    

    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (!error) {
            // NSLog(@"request authorization succeeded!");
            // [self showAlert];
        }
    }];
    
    center.delegate = self;
    
    [center removeAllPendingNotificationRequests];
        
    
    self.rootViewController.lastArrivalsShown = UserState.sharedInstance.last;
    self.rootViewController.lastArrivalNames = UserState.sharedInstance.lastNames;
    
    if ((self.rootViewController.lastArrivalsShown != nil && self.rootViewController.lastArrivalsShown.length == 0)
        || backgroundSupported
        ) {
        self.rootViewController.lastArrivalsShown = nil;
        self.rootViewController.lastArrivalNames = nil;
    }
    
    // Configure and show the window
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    self.window.rootViewController = self.rootViewController;
    
    // drawerController.closeDrawerGestureModeMask = MMCloseDrawerGestureModeTapCenterView | MMCloseDrawerGestureModeTapNavigationBar;
    
    
    self.window.rootViewController = self.navigationController;
    
    NSArray *windows = [UIApplication sharedApplication].windows;
    
    for (UIWindow *win in windows) {
        DEBUG_LOG(@"window: %@", win.description);
        
        if (win.rootViewController == nil) {
            UIViewController *vc = [[UIViewController alloc]initWithNibName:nil bundle:nil];
            win.rootViewController = vc;
        }
    }
    
    [self.window makeKeyAndVisible];
    
#if defined(MAXCOLORS) && defined(CREATE_MAX_ARRAYS)
    AllRailStationView *station = [AllRailStationView viewController];
    
    [station generateArrays];
#endif
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self cleanExit];
}

- (BOOL)application:(UIApplication *)application willContinueUserActivityWithType:(NSString *)userActivityType {
    return YES;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring> > *__nullable restorableObjects))restorationHandler {
    DEBUG_FUNC();
    
    bool siri = NO;
    
    if (@available(ios 12.0, *)) {
        if ([userActivity.interaction.intent isKindOfClass:[ArrivalsIntent class]]) {
            self.rootViewController.initialActionArgs = @{ kUserFavesLocation: userActivity.userInfo[@"locs"] };
            
            self.rootViewController.initialAction = InitialAction_UserActivityBookmark;
            
            if (self.rootViewController != nil) {
                [self.rootViewController executeInitialAction];
            }
            
            siri = YES;
        }
    }
    
    if (siri) {
    } else if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
        self.rootViewController.initialActionArgs = userActivity.userInfo;
        
        self.rootViewController.initialAction = InitialAction_UserActivitySearch;
        
        if (self.rootViewController != nil) {
            [self.rootViewController executeInitialAction];
        }
    } else if ([userActivity.activityType isEqualToString:kHandoffUserActivityBookmark]) {
        self.rootViewController.initialActionArgs = userActivity.userInfo;
        
        self.rootViewController.initialAction = InitialAction_UserActivityBookmark;
        
        if (self.rootViewController != nil) {
            [self.rootViewController executeInitialAction];
        }
    } else if ([userActivity.activityType isEqualToString:kHandoffUserActivityLocation]) {
        self.rootViewController.initialActionArgs = userActivity.userInfo;
        
        self.rootViewController.initialAction = InitialAction_Locate;
        
        if (self.rootViewController != nil) {
            [self.rootViewController executeInitialAction];
        }
    }
    
    return YES;
}

- (void)                      application:(UIApplication *)application
    didFailToContinueUserActivityWithType:(NSString *)userActivityType
                                    error:(NSError *)error {
}

- (void)             application:(UIApplication *)application
    performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
               completionHandler:(void (^)(BOOL succeeded))completionHandler {
    self.rootViewController.initialActionArgs = shortcutItem.userInfo;
    
    self.rootViewController.initialAction = InitialAction_UserActivityBookmark;
    
    if (self.rootViewController != nil) {
        [self.rootViewController executeInitialAction];
    }
    
    completionHandler(YES);
}



- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    return [self compatApplication:application handleOpenURL:url];
}

- (BOOL)compatApplication:(UIApplication *)application handleOpenURL:(NSURL *)url {
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
        self.rootViewController.routingURL = url;
        return YES;
    }
    
    NSString *strUrl = url.absoluteString;
    
    // we bound the length of the URL to 15K.  This is really big!
    if (strUrl.length > 15 * 1024) {
        return NO;
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:strUrl];
    NSCharacterSet *slash = [NSCharacterSet characterSetWithCharactersInString:@"/"];
    NSString *section;
    NSString *protocol;
    
    // skip up to first slash
    [scanner scanUpToCharactersFromSet:slash intoString:&protocol];
    
    if ([protocol caseInsensitiveCompare:@"pdxbusroute:"] == NSOrderedSame) {
        self.rootViewController.routingURL = url;
        return YES;
    }
    
    if (!scanner.atEnd) {
        scanner.scanLocation++;
        
        while (!scanner.atEnd) {
            // Sometimes we get NO back when there are two slashes in a row, skip that case
            if ([scanner scanUpToCharactersFromSet:slash intoString:&section] && ![self processURL:section protocol:protocol]) {
                break;
            }
            
            if (!scanner.atEnd) {
                scanner.scanLocation++;
            }
        }
    }
    
    if (self.rootViewController != nil) {
        [self.rootViewController reloadData];
    }
    
    return YES;
}

#pragma mark Application Helper functions

#define HEX_DIGIT(B) (B <= '9' ? (B) - '0' : (( (B) < 'G') ? (B) - 'A' + 10 : (B) - 'a' + 10))

- (BOOL)processURL:(NSString *)url protocol:(NSString *)protocol {
    NSScanner *scanner = [NSScanner scannerWithString:url];
    NSCharacterSet *query = [NSCharacterSet characterSetWithCharactersInString:@"?"];
    
    if (url.length == 0) {
        return YES;
    }
    
    NSString *name = nil;
    
    [scanner scanUpToCharactersFromSet:query intoString:&name];
    
    if (!scanner.atEnd) {
        return [self processBookMarkFromURL:url protocol:protocol];
    } else if (isalpha([url characterAtIndex:0])) {
        return [self processCommandFromURL:url];
    }
    
    return [self processStopFromURL:name];
}

- (void)processLaunchArgs:(NSScanner *)scanner {
    NSMutableDictionary *launchArgs = [NSMutableDictionary dictionary];
    
    NSCharacterSet *delim = [NSCharacterSet characterSetWithCharactersInString:@"&"];
    NSCharacterSet *equals = [NSCharacterSet characterSetWithCharactersInString:@"="];
    
    
    while (!scanner.atEnd) {
        NSString *option = nil;
        [scanner scanUpToCharactersFromSet:equals intoString:&option];
        
        if (!scanner.atEnd) {
            scanner.scanLocation++;
            NSString *value = nil;
            [scanner scanUpToCharactersFromSet:delim intoString:&value];
            
            if (option != nil && value != nil) {
                launchArgs[option] = value;
            }
            
            if (!scanner.atEnd) {
                scanner.scanLocation++;
            }
        }
    }
    self.rootViewController.initialActionArgs = launchArgs;
}

- (BOOL)processCommandFromURL:(NSString *)command {
    NSScanner *scanner = [NSScanner scannerWithString:command];
    NSCharacterSet *delim = [NSCharacterSet characterSetWithCharactersInString:@"=&"];
    NSString *token = nil;
    NSCharacterSet *blankSet = [[NSCharacterSet alloc] init];
    
    [scanner scanUpToCharactersFromSet:delim intoString:&token];
    
    if (token == nil) {
        return YES;
    } else if ([token caseInsensitiveCompare:@"locate"] == NSOrderedSame || [token caseInsensitiveCompare:@"nearby"] == NSOrderedSame) {
        self.rootViewController.initialAction = InitialAction_Locate;
        
        if (!scanner.atEnd) {
            scanner.scanLocation++;
            
            [self processLaunchArgs:scanner];
        }
    } else if ([token caseInsensitiveCompare:@"commute"] == NSOrderedSame) {
        self.rootViewController.initialAction = InitialAction_Commute;
    } else if ([token caseInsensitiveCompare:@"bookmark"] == NSOrderedSame && !scanner.atEnd) {
        scanner.scanLocation++;
        
        if (!scanner.atEnd) {
            NSString *bookmarkName = nil;
            [scanner scanUpToCharactersFromSet:blankSet intoString:&bookmarkName];
            self.rootViewController.initialBookmarkName = [bookmarkName stringByRemovingPercentEncoding];
        }
    } else if ([token caseInsensitiveCompare:@"bookmarknumber"] == NSOrderedSame && !scanner.atEnd) {
        scanner.scanLocation++;
        
        if (!scanner.atEnd) {
            int bookmarkNumber = 0;
            
            if ([scanner scanInt:&bookmarkNumber]) {
                self.rootViewController.initialBookmarkIndex = bookmarkNumber;
                self.rootViewController.initialAction = InitialAction_BookmarkIndex;
            }
        }
    } else if ([token caseInsensitiveCompare:@"tripplanner"] == NSOrderedSame) {
        self.rootViewController.initialAction = InitialAction_TripPlanner;
    } else if ([token caseInsensitiveCompare:@"qrcode"] == NSOrderedSame) {
        self.rootViewController.initialAction = InitialAction_QRCode;
    } else if ([token caseInsensitiveCompare:@"back"] == NSOrderedSame) {
        if ([self.navigationController.topViewController isKindOfClass:[WebViewController class]]) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else if ([token caseInsensitiveCompare:@"map"] == NSOrderedSame) {
        self.rootViewController.initialAction = InitialAction_Map;
    }
    
    return YES;
}

- (BOOL)processStopFromURL:(NSString *)stops {
    DEBUG_FUNC();
    
    if (stops.length == 0) {
        return YES;
    }
    
    NSMutableString *safeStopString = [NSMutableString string];
    
    int i;
    unichar item;
    
    for (i = 0; i < stops.length; i++) {
        item = [stops characterAtIndex:i];
        
        if (item == ',' || (item <= '9' && item >= '0')) {
            [safeStopString appendFormat:@"%c", item];
        }
    }
    
    self.rootViewController.launchStops = safeStopString;
    
    return YES;
}

- (BOOL)processBookMarkFromURL:(NSString *)bookmark protocol:(NSString *)protocol {
    NSScanner *scanner = [NSScanner scannerWithString:bookmark];
    NSCharacterSet *query = [NSCharacterSet characterSetWithCharactersInString:@"?"];
    
    if (bookmark.length == 0) {
        return YES;
    }
    
    NSString *name = nil;
    NSString *stops = nil;
    
    [scanner scanUpToCharactersFromSet:query intoString:&name];
    
    if (!scanner.atEnd) {
        stops = [bookmark substringFromIndex:scanner.scanLocation + 1];
    }
    
    UserState *userData = UserState.sharedInstance;
    
    // If this is an encoded dictionary we have to decode it
    if ([stops characterAtIndex:0] == 'd' && [protocol isEqualToString:@"pdxbus2:"]) {
        DEBUG_LOG(@"dictionary");
        NSMutableData *encodedDictionary = [[NSMutableData alloc] initWithCapacity:stops.length / 2];
        
        unsigned char byte;
        
        for (int i = 1; i < stops.length; i += 2) {
            unsigned char c0 = [stops characterAtIndex:i];
            unsigned char c1 = [stops characterAtIndex:i + 1];
            
            byte = HEX_DIGIT(c0) * 16 + HEX_DIGIT(c1);
            [encodedDictionary appendBytes:&byte length:1];
        }
        
        NSError *error = nil;
        NSPropertyListFormat fmt = NSPropertyListBinaryFormat_v1_0;
        
        DEBUG_LOG(@"Stops: %@ %ld data length %ld stops/2 %ld\n", stops, (unsigned long)stops.length, (unsigned long)encodedDictionary.length, (unsigned long)stops.length / 2);
        
        
        NSMutableDictionary *d = nil;
        
        d = [NSPropertyListSerialization propertyListWithData:encodedDictionary
                                                      options:NSPropertyListMutableContainers
                                                       format:&fmt
                                                        error:&error];
        
        if (d != nil) {
            @synchronized (userData)
            {
                [userData.faves addObject:d];
            }
        }
    } else if ([stops characterAtIndex:0] != 'd') {
        @synchronized (userData)
        {
            if (name == nil || name.length == 0) {
                name = kNewBookMark;
            }
            
            if (stops != nil && stops.length != 0 && userData.faves.count < kMaxFaves) {
                self.rootViewController = nil;
                
                NSString *fullName = [name stringByRemovingPercentEncoding];
                
                
                NSMutableDictionary *newFave = [NSMutableDictionary dictionary];
                newFave[kUserFavesChosenName] = fullName;
                newFave[kUserFavesLocation] = stops;
                [userData.faves addObject:newFave];
            }
        }
    }
    
    [userData cacheState];
    
    return YES;
}


// The method will be called on the delegate only if the application is in the foreground. If the method is not implemented or the handler is not called in a timely manner then the notification will not be presented. The application can choose to have the notification presented as a sound, badge, alert and/or in the notification list. This decision should be based on whether the information in the notification is otherwise visible to the user.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
{
    AlarmNotification *notify = [[AlarmNotification alloc] init];
    
    UIApplicationState previousState = [UIApplication sharedApplication].applicationState;
    
    notify.previousState = previousState;
    
    [notify application:[UIApplication sharedApplication] didReceiveLocalNotification:notification.request];
    
    completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
}

// The method will be called on the delegate when the user responded to the notification by opening the application, dismissing the notification or choosing a UNNotificationAction. The delegate must be set before the application returns from application:didFinishLaunchingWithOptions:.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler
{
    AlarmNotification *notify = [[AlarmNotification alloc] init];

    
    UIApplicationState previousState = [UIApplication sharedApplication].applicationState;
    
    notify.previousState = previousState;
    
    [notify application:[UIApplication sharedApplication] didReceiveLocalNotification:response.notification.request];
     
    completionHandler();
}

// The method will be called on the delegate when the application is launched in response to the user's request to view in-app notification settings. Add UNAuthorizationOptionProvidesAppNotificationSettings as an option in requestAuthorizationWithOptions:completionHandler: to add a button to inline notification settings view and the notification settings view in Settings. The notification will be nil when opened from Settings.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center openSettingsForNotification:(nullable UNNotification *)notification
{
    AlarmNotification *notify = [[AlarmNotification alloc] init];
    
    UIApplicationState previousState = [UIApplication sharedApplication].applicationState;
    
    notify.previousState = previousState;
    
    [notify application:[UIApplication sharedApplication] didReceiveLocalNotification:notification.request];
}


+ (PDXBusAppDelegate *)sharedInstance {
    return (PDXBusAppDelegate *)[UIApplication sharedApplication].delegate;
}

@end
