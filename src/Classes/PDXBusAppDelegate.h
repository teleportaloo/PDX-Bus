//
//  PDXBusAppDelegate.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TriMetTypes.h"
#import "Settings.h"

#import "AlarmNotification.h"

@class RootViewController;

@interface PDXBusAppDelegate : NSObject <UIApplicationDelegate, UNUserNotificationCenterDelegate>

@property (nonatomic) bool cleanExitLastTime;
@property (nonatomic, copy)   NSString *pathToCleanExit;
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) IBOutlet UINavigationController *navigationController;
@property (nonatomic, strong) RootViewController *rootViewController;

@end
