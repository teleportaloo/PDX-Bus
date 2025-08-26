//
//  PDXBusAppDelegate.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Settings.h"
#import "TriMetTypes.h"
#import <UIKit/UIKit.h>

#import "AlarmNotification.h"

@class RootViewController;

@interface PDXBusAppDelegate
    : NSObject <UIApplicationDelegate, UNUserNotificationCenterDelegate>

@property(nonatomic) bool cleanExitLastTime;
@property(nonatomic, copy) NSString *pathToCleanExit;




@end
