//
//  AlarmNotification.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/3/11.
//  Copyright 2011 Teleportaloo. All rights reserved.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */



#import <Foundation/Foundation.h>
#import "MapPinColor.h"
#import <AudioToolbox/AudioToolbox.h>



@interface AlarmNotification : NSObject <UIAlertViewDelegate, MapPinColor> {
	UILocalNotification *_notification;
	UIApplicationState _previousState;
    SystemSoundID _soundID;
}

@property (nonatomic, retain)	UILocalNotification *notification;
@property (nonatomic)			UIApplicationState previousState;

- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notif;

@end
