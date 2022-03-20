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


#define DEBUG_LEVEL_FOR_FILE kLogAlarms

#import "AlarmNotification.h"
#import "PDXBusAppDelegate+Methods.h"
#import "AlarmTask.h"
#import "DepartureTimesView.h"
#import "RootViewController.h"
#import "MapViewController.h"
#import "SimpleAnnotation.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "UIAlertController+SimpleMessages.h"

@interface AlarmNotification () {
    SystemSoundID _soundID;
}

@property (nonatomic, strong)    UNNotificationRequest *notification;

@end

@implementation AlarmNotification

@dynamic pinTint;
@dynamic pinColor;

- (void)dealloc {
    if (_soundID != 0) {
        AudioServicesDisposeSystemSoundID(_soundID);
    }
}

- (void)executeAction:(NSDictionary *)userInfo {
    PDXBusAppDelegate *app = PDXBusAppDelegate.sharedInstance;
    NSString *stopId = userInfo[kStopIdNotification];
    NSString *mapDescr = userInfo[kStopMapDescription];
    
    if (userInfo) {
        if (mapDescr) {
            [app.rootViewController.navigationController popToRootViewControllerAnimated:NO];
            MapViewController *mapPage = [MapViewController viewController];
            
            
            NSNumber *lat = userInfo[kCurrLocLat];
            NSNumber *lng = userInfo[kCurrLocLng];
            NSString *stamp = userInfo[kCurrTimestamp];
            
            if (lat && lng) {
                CLLocationCoordinate2D coord;
                coord.latitude = lat.doubleValue;
                coord.longitude = lng.doubleValue;
                
                SimpleAnnotation *currentLocation = [SimpleAnnotation annotation];
                currentLocation.pinColor = MAP_PIN_COLOR_PURPLE;
                currentLocation.pinTitle = NSLocalizedString(@"Current Location", @"map pin");
                currentLocation.pinSubtitle = [NSString stringWithFormat:NSLocalizedString(@"as of %@", "location as of time {time}"), stamp];
                currentLocation.coordinate = coord;
                [mapPage addPin:currentLocation];
            }
            
            [app.rootViewController.navigationController pushViewController:mapPage animated:YES];
        } else if (stopId) {
            [app.rootViewController.navigationController popToRootViewControllerAnimated:NO];
            
            NSString *block = userInfo[kAlarmBlock];
            NSString *dir   = userInfo[kAlarmDir];
            
            [[DepartureDetailView viewController] fetchDepartureAsync:app.rootViewController.backgroundTask stopId:stopId block:block dir:dir backgroundRefresh:NO];
        }
    }
}


- (void)application:(UIApplication *)app didReceiveLocalNotification:(UNNotificationRequest *)notif {
    DEBUG_LOG(@"notification woke me up\n");
    
    self.notification = notif;
    
    
#if TARGET_OS_MACCATALYST
    if (notif.content.userInfo) {
        [self executeAction:notif.content.userInfo];
    }
#else
    
    if (self.previousState == UIApplicationStateBackground || self.previousState == UIApplicationStateInactive) {
        if (notif.content.userInfo) {
            [self executeAction:notif.content.userInfo];
        }
    } else {
        if (notif.content.userInfo != nil && notif.content.userInfo[kDoNotDisplayIfActive] == nil) {
            AVAudioSession *session = [AVAudioSession sharedInstance];
            
            NSError *setCategoryError = nil;
            
            if (![session setCategory:AVAudioSessionCategoryPlayback
                          withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                error:&setCategoryError]) {
                // handle error
            }
            
            /*
            NSString *soundFile = notif.soundName;
            
            DEBUG_LOG(@"Playing sound %@\n", notif.soundName);
            
            if ([soundFile isEqualToString:@"UILocalNotificationDefaultSoundName"]) {
                soundFile = @"default_sound.wav";
            }
             
            
            // UserPrefs *prefs = [UserPrefs sharedInstance];
            //Get the filename of the sound file:
            NSString *path = [NSString stringWithFormat:@"%@/%@",
                              [NSBundle mainBundle].resourcePath,
                              soundFile];
            
            //Get a URL for the sound file
            NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
            
            
            AudioServicesCreateSystemSoundID((__bridge CFURLRef)filePath, &_soundID);
            
            
            //Use audio services to play the sound
            AudioServicesPlaySystemSound(_soundID);
            // AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            */
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Alarm", @"alarm message title")
                                                                           message:notif.content.body
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:kAlertViewOK style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            }]];
            
            /*
            [alert addAction:[UIAlertAction actionWithTitle:notif.alertAction style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self executeAction];
            }]];
             */
            
            
            PDXBusAppDelegate *app = PDXBusAppDelegate.sharedInstance;
            
            UIView *source = app.navigationController.topViewController.view;
            
            alert.popoverPresentationController.sourceView = source;
            alert.popoverPresentationController.sourceRect = CGRectMake(source.frame.size.width / 2, source.frame.size.height / 2, 10, 10);
            
            [app.navigationController presentViewController:alert animated:YES completion:nil];
        }
    }
#endif
}



- (MapPinColorValue)pinColor {
    return MAP_PIN_COLOR_GREEN;
}

- (bool)pinActionMenu {
    return YES;
}


- (NSDictionary *)userInfo
{
    return self.notification.content.userInfo;
}


- (CLLocationCoordinate2D)coordinate {
    CLLocationCoordinate2D coord;
    NSNumber *lat = self.userInfo[kStopMapLat];
    NSNumber *lng = self.userInfo[kStopMapLng];
    
    coord.latitude = lat.doubleValue;
    coord.longitude = lng.doubleValue;
    
    return coord;
}

- (NSString *)title {
    return self.userInfo[kStopMapDescription];
}

- (NSString *)subtitle {
    return [NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), self.userInfo[kStopIdNotification]];
}

- (NSString *)pinStopId {
    return self.userInfo[kStopIdNotification];
}

- (UIColor *)pinTint {
    return nil;
}

- (bool)pinHasBearing {
    return NO;
}

- (NSString *)pinMarkedUpType
{
    return nil;
}



@end
