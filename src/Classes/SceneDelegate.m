//
//  SceneDelegate.m
//  PDX Bus
//
//  Created by Andy Wallace on 7/8/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "SceneDelegate.h"
#import "PDXBusAppDelegate+Methods.h"
#import "RootViewController.h"

#import "KMLRoutes.h"
#import "UserInfo.h"
#import "UserParams.h"
#import "UserState.h"
#import "WebViewController.h"

#import "AlertsForRouteIntent.h"
#import "ArrivalsIntent.h"
#import "SystemWideAlertsIntent.h"

#define DEBUG_LEVEL_FOR_FILE LogUI

@interface SceneDelegate ()

@property(nonatomic) bool cleanExitLastTime;
@property(nonatomic, copy) NSString *pathToCleanExit;

@end

@implementation SceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {

    if ([scene isKindOfClass:[UIWindowScene class]]) {
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        self.window = [[UIWindow alloc] initWithWindowScene:windowScene];

        UIViewController *rootVC =
            [[RootViewController alloc] init]; // customize as needed
        UINavigationController *nav =
            [[UINavigationController alloc] initWithRootViewController:rootVC];
        
        self.window.backgroundColor = [UIColor systemBackgroundColor];
        self.window.rootViewController = nav;
        [self.window makeKeyAndVisible];
    }
}

- (RootViewController *)currentRootViewController {
    return ((UINavigationController *)self.window.rootViewController)
        .viewControllers.firstObject;
}

- (void)scene:(UIScene *)scene
    openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    DEBUG_FUNC();

    NSURL *url = nil;

    RootViewController *rootViewController = self.currentRootViewController;

    if (URLContexts.count > 0) {
        url = URLContexts.anyObject.URL;
    }

    if (!url) {
        // The URL is nil. There's nothing more to do.
        return;
    }

    Class dirClass = (NSClassFromString(@"MKDirectionsRequest"));

    if (dirClass && [MKDirectionsRequest isDirectionsRequestURL:url]) {
        rootViewController.routingURL = url;
        return;
    }

    NSString *strUrl = url.absoluteString;

    // we bound the length of the URL to 15K.  This is really big!
    if (strUrl.length > 15 * 1024) {
        return;
    }

    NSScanner *scanner = [NSScanner scannerWithString:strUrl];
    NSCharacterSet *slash =
        [NSCharacterSet characterSetWithCharactersInString:@"/"];
    NSString *section;
    NSString *protocol;

    // skip up to first slash
    [scanner scanUpToCharactersFromSet:slash intoString:&protocol];

    if ([protocol caseInsensitiveCompare:@"pdxbusroute:"] == NSOrderedSame) {
        rootViewController.routingURL = url;
        return;
    }

    if (!scanner.atEnd) {
        scanner.scanLocation++;

        while (!scanner.atEnd) {
            // Sometimes we get NO back when there are two slashes in a row,
            // skip that case
            if ([scanner scanUpToCharactersFromSet:slash intoString:&section] &&
                ![self processURL:section protocol:protocol]) {
                break;
            }

            if (!scanner.atEnd) {
                scanner.scanLocation++;
            }
        }
    }

    if (rootViewController != nil) {
        [rootViewController reloadData];
    }

    return;
}

#pragma mark Application Helper functions

#define HEX_DIGIT(B)                                                           \
    (B <= '9' ? (B) - '0' : (((B) < 'G') ? (B) - 'A' + 10 : (B) - 'a' + 10))

- (BOOL)processURL:(NSString *)url protocol:(NSString *)protocol {
    NSScanner *scanner = [NSScanner scannerWithString:url];
    NSCharacterSet *query =
        [NSCharacterSet characterSetWithCharactersInString:@"?"];

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

- (BOOL)processCommandFromURL:(NSString *)command {
    NSScanner *scanner = [NSScanner scannerWithString:command];
    NSCharacterSet *delim =
        [NSCharacterSet characterSetWithCharactersInString:@"=&"];
    NSString *token = nil;
    NSCharacterSet *blankSet = [[NSCharacterSet alloc] init];

    [scanner scanUpToCharactersFromSet:delim intoString:&token];

    RootViewController *rootViewController = self.currentRootViewController;

    if (token == nil) {
        return YES;
    } else if ([token caseInsensitiveCompare:@"locate"] == NSOrderedSame ||
               [token caseInsensitiveCompare:@"nearby"] == NSOrderedSame) {
        rootViewController.initialAction = InitialAction_Locate;

        if (!scanner.atEnd) {
            scanner.scanLocation++;

            [self processLaunchArgs:scanner];
        }
    } else if ([token caseInsensitiveCompare:@"commute"] == NSOrderedSame) {
        rootViewController.initialAction = InitialAction_Commute;
    } else if ([token caseInsensitiveCompare:@"bookmark"] == NSOrderedSame &&
               !scanner.atEnd) {
        scanner.scanLocation++;

        if (!scanner.atEnd) {
            NSString *bookmarkName = nil;
            [scanner scanUpToCharactersFromSet:blankSet
                                    intoString:&bookmarkName];
            rootViewController.initialBookmarkName =
                [bookmarkName stringByRemovingPercentEncoding];
        }
    } else if ([token caseInsensitiveCompare:@"bookmarknumber"] ==
                   NSOrderedSame &&
               !scanner.atEnd) {
        scanner.scanLocation++;

        if (!scanner.atEnd) {
            int bookmarkNumber = 0;

            if ([scanner scanInt:&bookmarkNumber]) {
                rootViewController.initialBookmarkIndex = bookmarkNumber;
                rootViewController.initialAction = InitialAction_BookmarkIndex;
            }
        }
    } else if ([token caseInsensitiveCompare:@"tripplanner"] == NSOrderedSame) {
        rootViewController.initialAction = InitialAction_TripPlanner;
    } else if ([token caseInsensitiveCompare:@"qrcode"] == NSOrderedSame) {
        rootViewController.initialAction = InitialAction_QRCode;
    } else if ([token caseInsensitiveCompare:@"back"] == NSOrderedSame) {
        if ([rootViewController.navigationController.topViewController
                isKindOfClass:[WebViewController class]]) {
            [rootViewController.navigationController
                popViewControllerAnimated:YES];
        }
    } else if ([token caseInsensitiveCompare:@"map"] == NSOrderedSame) {
        rootViewController.initialAction = InitialAction_Map;
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

    self.currentRootViewController.launchStops = safeStopString;

    return YES;
}

- (BOOL)processBookMarkFromURL:(NSString *)bookmark
                      protocol:(NSString *)protocol {
    NSScanner *scanner = [NSScanner scannerWithString:bookmark];
    NSCharacterSet *query =
        [NSCharacterSet characterSetWithCharactersInString:@"?"];

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
    if ([stops characterAtIndex:0] == 'd' &&
        [protocol isEqualToString:@"pdxbus2:"]) {
        DEBUG_LOG(@"dictionary");
        NSMutableData *encodedDictionary =
            [[NSMutableData alloc] initWithCapacity:stops.length / 2];

        unsigned char byte;

        for (int i = 1; i < stops.length; i += 2) {
            unsigned char c0 = [stops characterAtIndex:i];
            unsigned char c1 = [stops characterAtIndex:i + 1];

            byte = HEX_DIGIT(c0) * 16 + HEX_DIGIT(c1);
            [encodedDictionary appendBytes:&byte length:1];
        }

        NSError *error = nil;
        NSPropertyListFormat fmt = NSPropertyListBinaryFormat_v1_0;

        DEBUG_LOG(@"Stops: %@ %ld data length %ld stops/2 %ld\n", stops,
                  (unsigned long)stops.length,
                  (unsigned long)encodedDictionary.length,
                  (unsigned long)stops.length / 2);

        NSMutableDictionary *d = nil;

        d = [NSPropertyListSerialization
            propertyListWithData:encodedDictionary
                         options:NSPropertyListMutableContainers
                          format:&fmt
                           error:&error];

        if (d != nil) {
            @synchronized(userData) {
                [userData.faves addObject:d];
            }
        }
    } else if ([stops characterAtIndex:0] != 'd') {
        @synchronized(userData) {
            if (name == nil || name.length == 0) {
                name = kNewBookMark;
            }

            if (stops != nil && stops.length != 0 &&
                userData.faves.count < kMaxFaves) {

                NSString *fullName = [name stringByRemovingPercentEncoding];

                MutableUserParams *newFave = MutableUserParams.new;
                newFave.valChosenName = fullName;
                newFave.valLocation = stops;
                [userData.faves addObject:newFave.mutableDictionary];
            }
        }
    }

    [userData cacheState];

    return YES;
}

- (void)processLaunchArgs:(NSScanner *)scanner {
    NSMutableDictionary *launchArgs = [NSMutableDictionary dictionary];

    NSCharacterSet *delim =
        [NSCharacterSet characterSetWithCharactersInString:@"&"];
    NSCharacterSet *equals =
        [NSCharacterSet characterSetWithCharactersInString:@"="];

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
    self.currentRootViewController.initialActionArgs = launchArgs;
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    DEBUG_FUNC();
    bool newWindow = NO;

    [PDXBusAppDelegate.sharedInstance cleanStart];


    RootViewController *rootViewController = self.currentRootViewController;

    if (Settings.autoCommute) {
        rootViewController.commuterBookmark =
            [UserState.sharedInstance checkForCommuterBookmarkShowOnlyOnce:YES];
    }

    [rootViewController executeInitialAction];

    AlarmTaskList *list = [AlarmTaskList sharedInstance];

    [list resumeOnActivate];

    if (!newWindow && rootViewController) {
        UIViewController *topView =
            rootViewController.navigationController.topViewController;

        if ([topView respondsToSelector:@selector(didBecomeActive)]) {
            [topView performSelector:@selector(didBecomeActive)];
        }
    }
    
    
}

- (void)scene:(UIScene *)scene
    continueUserActivity:(NSUserActivity *)userActivity {
    DEBUG_FUNC();

    RootViewController *rootViewController = self.currentRootViewController;

    bool siri = NO;

    if ([userActivity.interaction.intent
            isKindOfClass:[ArrivalsIntent class]]) {

        MutableUserParams *params = MutableUserParams.new;
        params.valLocation = userActivity.userInfo.userInfo.valLocs;
        rootViewController.initialActionArgs = params.dictionary;

        rootViewController.initialAction = InitialAction_UserActivityBookmark;

        if (rootViewController != nil) {
            [rootViewController executeInitialAction];
        }

        siri = YES;
    } else if ([userActivity.interaction.intent
                   isKindOfClass:[AlertsForRouteIntent class]]) {
        rootViewController.initialAction = InitialAction_UserActivityAlerts;

        AlertsForRouteIntent *intent =
            (AlertsForRouteIntent *)userActivity.interaction.intent;

        NSString *routeNumber =
            [TriMetInfo routeNumberFromInput:intent.routeNumber];

        if (routeNumber) {
            rootViewController.initialActionArgs =
                @{kUserInfoAlertRoute : routeNumber};
        }

        if (rootViewController != nil) {
            [rootViewController executeInitialAction];
        }

        siri = YES;
    } else if ([userActivity.interaction.intent
                   isKindOfClass:[SystemWideAlertsIntent class]]) {
        rootViewController.initialAction = InitialAction_UserActivityAlerts;

        if (rootViewController != nil) {
            [rootViewController executeInitialAction];
        }

        siri = YES;
    }

    if (siri) {
    } else if ([userActivity.activityType
                   isEqualToString:CSSearchableItemActionType]) {
        rootViewController.initialActionArgs = userActivity.userInfo;

        rootViewController.initialAction = InitialAction_UserActivitySearch;

        if (rootViewController != nil) {
            [rootViewController executeInitialAction];
        }
    } else if ([userActivity.activityType
                   isEqualToString:kHandoffUserActivityBookmark]) {
        rootViewController.initialActionArgs = userActivity.userInfo;

        rootViewController.initialAction = InitialAction_UserActivityBookmark;

        if (rootViewController != nil) {
            [rootViewController executeInitialAction];
        }
    } else if ([userActivity.activityType
                   isEqualToString:kHandoffUserActivityLocation]) {
        rootViewController.initialActionArgs = userActivity.userInfo;

        rootViewController.initialAction = InitialAction_Locate;

        if (rootViewController != nil) {
            [rootViewController executeInitialAction];
        }
    }
}

- (void)scene:(UIScene *)scene
    didFailToContinueUserActivityWithType:(NSString *)userActivityType
                                    error:(NSError *)error {
    NSLog(@"Failed to continue user activity: %@ (%@)", userActivityType,
          error.localizedDescription);

    // Handle fallback UI or error messaging
}

- (void)windowScene:(UIWindowScene *)windowScene
    performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
               completionHandler:(void (^)(BOOL))completionHandler {
    RootViewController *rootViewController = self.currentRootViewController;

    rootViewController.initialActionArgs = shortcutItem.userInfo;

    rootViewController.initialAction = InitialAction_UserActivityBookmark;

    if (rootViewController != nil) {
        [rootViewController executeInitialAction];
    }

    completionHandler(YES);
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
    RootViewController *rootViewController = self.currentRootViewController;

    if (rootViewController) {
        UIViewController *topView =
            rootViewController.navigationController.topViewController;

        if ([topView respondsToSelector:@selector(didEnterBackground)]) {
            [topView performSelector:@selector(didEnterBackground)];
        }
    }

    AlarmTaskList *list = [AlarmTaskList sharedInstance];

    [list updateBadge];

    [PDXBusAppDelegate.sharedInstance cleanExit];
}
@end
