//
//  AlarmNotification.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/3/11.
//  Copyright 2011 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */




#import <Foundation/Foundation.h>
#import "MapPinColor.h"
#import <AudioToolbox/AudioToolbox.h>



@interface AlarmNotification : NSObject <UIAlertViewDelegate, MapPinColor> {
	UILocalNotification *   _notification;
	UIApplicationState      _previousState;
    SystemSoundID           _soundID;
}

@property (nonatomic, retain)	UILocalNotification *notification;
@property (nonatomic)			UIApplicationState previousState;

- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notif;

@end
