//
//  AlarmNotification.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/3/11.
//  Copyright 2011 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapPin.h"
#import <Foundation/Foundation.h>
#import <UserNotifications/UserNotifications.h>

@interface AlarmNotification : NSObject <MapPin>

@property(nonatomic) UIApplicationState previousState;

- (void)application:(UIApplication *)app
    didReceiveLocalNotification:(UNNotificationRequest *)notif;
+ (void)executeAction:(NSDictionary *)userInfo;

@end
