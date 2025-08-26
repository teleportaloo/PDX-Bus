//
//  AlarmNotification.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/3/11.
//  Copyright 2011 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogAlarms

#import "AlarmNotification.h"
#import "AlarmTask.h"
#import "DepartureTimesViewController.h"
#import "MapViewController.h"
#import "RootViewController.h"
#import "SimpleAnnotation.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIApplication+Compat.h"
#import "UserInfo.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AlarmNotification () {
    SystemSoundID _soundID;
}

@property(nonatomic, strong) UNNotificationRequest *notification;

@end

@implementation AlarmNotification

@dynamic pinTint;
@dynamic pinColor;

- (void)dealloc {
    if (_soundID != 0) {
        AudioServicesDisposeSystemSoundID(_soundID);
    }
}

+ (void)executeAction:(NSDictionary *)rawUserInfo {
    UIViewController *top = UIApplication.topViewController;

    if (rawUserInfo) {
        UserInfo *userInfo = rawUserInfo.userInfo;
        NSString *stopId = userInfo.valStopId;
        NSString *mapDescr = userInfo.valStopMapDesc;

        if (mapDescr) {
            [top.navigationController popToRootViewControllerAnimated:NO];
            MapViewController *mapPage = [MapViewController viewController];

            NSString *stamp = userInfo.valCurTimestamp;

            if (userInfo.existsCurLat && userInfo.existsCurLng) {
                CLLocationCoordinate2D coord;
                coord.latitude = userInfo.valCurLat;
                coord.longitude = userInfo.valCurLng;

                SimpleAnnotation *currentLocation =
                    [SimpleAnnotation annotation];
                currentLocation.pinColor = MAP_PIN_COLOR_PURPLE;
                currentLocation.pinTitle =
                    NSLocalizedString(@"Current Location", @"map pin");
                currentLocation.pinSubtitle = [NSString
                    stringWithFormat:NSLocalizedString(
                                         @"as of %@",
                                         "location as of time {time}"),
                                     stamp];
                currentLocation.coordinate = coord;
                [mapPage addPin:currentLocation];
            }

            [top.navigationController pushViewController:mapPage animated:YES];
        } else if (stopId) {
            [top.navigationController popToRootViewControllerAnimated:NO];

            NSString *block = userInfo.valAlarmBlock;
            NSString *dir = userInfo.valAlarmDir;

            [[DepartureDetailViewController viewController]
                fetchDepartureAsync:RootViewController.currentRootViewController
                                        .backgroundTask
                             stopId:stopId
                              block:block
                                dir:dir
                  backgroundRefresh:NO];
        }
    }
}

- (void)application:(UIApplication *)app
    didReceiveLocalNotification:(UNNotificationRequest *)notif {
    DEBUG_LOG(@"use clicked on notification and it woke me up\n");

    self.notification = notif;

#if TARGET_OS_MACCATALYST
    if (notif.content.userInfo) {
        [self executeAction:notif.content.userInfo];
    }
#else

    if (notif.content.userInfo) {
        [AlarmNotification executeAction:notif.content.userInfo];
    }
#endif
}

- (MapPinColorValue)pinColor {
    return MAP_PIN_COLOR_GREEN;
}

- (bool)pinActionMenu {
    return YES;
}

- (NSDictionary *)userInfo {
    return self.notification.content.userInfo;
}

- (CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D coord;
    UserInfo *info = self.userInfo.userInfo;

    coord.latitude = info.valMapLat;
    coord.longitude = info.valMapLng;

    return coord;
}

- (NSString *)title {
    return self.userInfo.userInfo.valStopMapDesc;
}

- (NSString *)subtitle {
    return [NSString
        stringWithFormat:NSLocalizedString(@"Stop ID %@",
                                           @"TriMet Stop identifer <number>"),
                         self.userInfo.userInfo.valStopId];
}

- (NSString *)pinStopId {
    return self.userInfo.userInfo.valStopId;
}

- (UIColor *)pinTint {
    return nil;
}

- (bool)pinHasBearing {
    return NO;
}

- (NSString *)pinMarkedUpType {
    return nil;
}

@end
