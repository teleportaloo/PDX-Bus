//
//  PDXBusAppDelegate.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "AlarmNotification.h"
#import "AlarmTaskList.h"

#import "AllRailStationViewController.h"

#import "DebugLogging.h"
#import "DepartureTimesViewController.h"
#import "FindByLocationViewController.h"
#import "KMLRoutes.h"
#import "NSString+Core.h"
#import "NSString+DocPath.h"
#import "PDXBusAppDelegate+Methods.h"
#import "RootViewController.h"
#import "StopView.h"

#import "UserInfo.h"
#import "UserParams.h"
#import "UserState.h"
#import "WebViewController.h"
#import "XMLDepartures.h"
#import "XMLDetours.h"
#import "XMLRoutes.h"
#import "XMLStops.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "UIApplication+Compat.h"

#if TARGET_OS_MACCATALYST
#import <UserNotifications/UserNotifications.h>
#endif

// Xcode 14 Beta 5: [<_UINavigationBarContentViewLayout valueForUndefinedKey:]:
// this class is not key value coding-compliant for the key inlineTitleView.
// https://developer.apple.com/forums/thread/712240
#if DEBUG
#import <objc/runtime.h>
@interface Xcode14Beta4Fixer : NSObject
@end

@implementation Xcode14Beta4Fixer

+ (void)load {
    Class cls = NSClassFromString(@"_UINavigationBarContentViewLayout");
    SEL selector = @selector(valueForUndefinedKey:);
    Method impMethod = class_getInstanceMethod([self class], selector);

    if (impMethod) {
        class_addMethod(cls, selector, method_getImplementation(impMethod),
                        method_getTypeEncoding(impMethod));
    }
}

- (id)valueForUndefinedKey:(NSString *)key {
    return nil;
}

@end
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

        if (Settings.clearCacheOnUnexpectedRestart) {
            [TriMetXML deleteCacheFile];
            [KMLRoutes deleteCacheFile];
        }
    } else {
        self.cleanExitLastTime = YES;
        NSString *str = @"clean";
        [str writeToFile:self.pathToCleanExit
              atomically:YES
                encoding:NSUTF8StringEncoding
                   error:NULL];
    }
}

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    DEBUG_FUNC();
    // [actualRootViewController initRootWindow];

    // Check for data in Documents directory. Copy default appData.plist to
    // Documents if not found.
    
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSError *error = nil;

    self.pathToCleanExit = @"cleanExit.txt".fullDocPath;

    NSString *oldSql = @"railLocations.sql";

    NSString *oldDatabase1 = oldSql.fullDocPath;

    [fileManager removeItemAtPath:oldDatabase1 error:&error];

    UNUserNotificationCenter *center =
        [UNUserNotificationCenter currentNotificationCenter];

    [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge |
                                             UNAuthorizationOptionSound |
                                             UNAuthorizationOptionAlert)
                          completionHandler:^(BOOL granted,
                                              NSError *_Nullable error) {
                            if (!error) {
                                // NSLog(@"request authorization succeeded!");
                                // [self showAlert];
                            }
                          }];

    center.delegate = self;

    [center removeAllPendingNotificationRequests];
    
    return true;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self cleanExit];
}

// The method will be called on the delegate only if the application is in the
// foreground. If the method is not implemented or the handler is not called in
// a timely manner then the notification will not be presented. The application
// can choose to have the notification presented as a sound, badge, alert and/or
// in the notification list. This decision should be based on whether the
// information in the notification is otherwise visible to the user.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:
             (void (^)(UNNotificationPresentationOptions options))
                 completionHandler {
    completionHandler(UNNotificationPresentationOptionBadge |
                      UNNotificationPresentationOptionSound |
                      UNNotificationPresentationOptionBanner);
}

// The method will be called on the delegate when the user responded to the
// notification by opening the application, dismissing the notification or
// choosing a UNNotificationAction. The delegate must be set before the
// application returns from application:didFinishLaunchingWithOptions:.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
    didReceiveNotificationResponse:(UNNotificationResponse *)response
             withCompletionHandler:(void (^)(void))completionHandler {
    AlarmNotification *notify = [[AlarmNotification alloc] init];

    UIApplicationState previousState =
        [UIApplication sharedApplication].applicationState;

    notify.previousState = previousState;

    [notify application:[UIApplication sharedApplication]
        didReceiveLocalNotification:response.notification.request];

    completionHandler();
}

// The method will be called on the delegate when the application is launched in
// response to the user's request to view in-app notification settings. Add
// UNAuthorizationOptionProvidesAppNotificationSettings as an option in
// requestAuthorizationWithOptions:completionHandler: to add a button to inline
// notification settings view and the notification settings view in Settings.
// The notification will be nil when opened from Settings.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
    openSettingsForNotification:(nullable UNNotification *)notification {
    AlarmNotification *notify = [[AlarmNotification alloc] init];

    UIApplicationState previousState =
        [UIApplication sharedApplication].applicationState;

    notify.previousState = previousState;

    [notify application:[UIApplication sharedApplication]
        didReceiveLocalNotification:notification.request];
}

+ (PDXBusAppDelegate *)sharedInstance {
    return (PDXBusAppDelegate *)[UIApplication sharedApplication].delegate;
}

@end
