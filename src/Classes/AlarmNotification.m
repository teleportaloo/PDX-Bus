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




#import "AlarmNotification.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"
#import "AlarmTask.h"
#import "DepartureTimesView.h"
#import "RootViewController.h"
#import "MapViewController.h"
#import "SimpleAnnotation.h"
#import <AVFoundation/AVFoundation.h>

@implementation AlarmNotification

@dynamic pinTint;
@dynamic pinColor;

- (void)dealloc
{
    if (_soundID != 0)
    {
        AudioServicesDisposeSystemSoundID(_soundID);
    }
}

- (void)executeAction
{
    TriMetTimesAppDelegate *app = [TriMetTimesAppDelegate sharedInstance];
    NSString *stopId   = self.notification.userInfo[kStopIdNotification];
    NSString *mapDescr = self.notification.userInfo[kStopMapDescription];
    
    if (self.notification.userInfo)
    {
        if (mapDescr)
        {
            [app.rootViewController.navigationController popToRootViewControllerAnimated:NO];
            MapViewController *mapPage = [MapViewController viewController];
            
            
            NSNumber *lat =     self.notification.userInfo[kCurrLocLat];
            NSNumber *lng =     self.notification.userInfo[kCurrLocLng];
            NSString *stamp =   self.notification.userInfo[kCurrTimestamp];
            
            if (lat && lng)
            {
                CLLocationCoordinate2D coord;
                coord.latitude  = lat.doubleValue;
                coord.longitude = lng.doubleValue;
            
                SimpleAnnotation *currentLocation = [SimpleAnnotation annotation];
                currentLocation.pinColor = MAP_PIN_COLOR_PURPLE;
                currentLocation.pinTitle = NSLocalizedString(@"Current Location", @"map pin");
                currentLocation.pinSubtitle = [NSString stringWithFormat:NSLocalizedString(@"as of %@","location as of time {time}"), stamp];
                currentLocation.coordinate = coord;
                [mapPage addPin:currentLocation];
            }
            
            [app.rootViewController.navigationController pushViewController:mapPage animated:YES];
        }
        else if (stopId)
        {
            [app.rootViewController.navigationController popToRootViewControllerAnimated:NO];
        
            NSString *block = self.notification.userInfo[kAlarmBlock];
            
            [[DepartureDetailView viewController] fetchDepartureAsync:app.rootViewController.backgroundTask location:stopId block:block backgroundRefresh:NO];
        }
    }
    
}

- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notif 
{
    DEBUG_LOG(@"notification woke me up\n");
    
    self.notification = notif;
    
    if (self.previousState == UIApplicationStateBackground || self.previousState == UIApplicationStateInactive)
    {
        if (notif.userInfo)
        {
            [self executeAction];
        }
    }
    else 
    {
        if (notif.userInfo!=nil && notif.userInfo[kDoNotDisplayIfActive]==nil)
        {
            AVAudioSession *session = [AVAudioSession sharedInstance];
            
            NSError *setCategoryError = nil;
            if (![session setCategory:AVAudioSessionCategoryPlayback
                          withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                error:&setCategoryError]) {
                // handle error
            }
            
            NSString *soundFile = notif.soundName;
            
            DEBUG_LOG(@"Playing sound %@\n", notif.soundName);
            
            if ([soundFile isEqualToString:@"UILocalNotificationDefaultSoundName"])
            {
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
            
            
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Alarm", @"alarm message title")
                                                                           message:notif.alertBody
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"Button text") style:UIAlertActionStyleCancel handler:^(UIAlertAction* action){
                
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:notif.alertAction style:UIAlertActionStyleDefault handler:^(UIAlertAction* action){
                [self executeAction];
            }]];
            
            
            TriMetTimesAppDelegate *mainApp = [TriMetTimesAppDelegate sharedInstance];
            
            UIView *source = mainApp.navigationController.topViewController.view;
            
            alert.popoverPresentationController.sourceView  = source;
            alert.popoverPresentationController.sourceRect = CGRectMake(source.frame.size.width/2, source.frame.size.height/2, 10, 10);
            
            [mainApp.navigationController presentViewController:alert animated:YES completion:nil];
        }
    }
    
}

- (MapPinColorValue) pinColor
{
    return MAP_PIN_COLOR_GREEN;
}

- (bool) showActionMenu
{
    return YES;
}

- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D coord;
    NSNumber *lat = self.notification.userInfo[kStopMapLat];
    NSNumber *lng = self.notification.userInfo[kStopMapLng];
    coord.latitude  = lat.doubleValue;
    coord.longitude = lng.doubleValue;
    
    return coord;
    
}

- (NSString *)title
{
    return self.notification.userInfo[kStopMapDescription];
}

- (NSString *)subtitle
{
    return [NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), self.notification.userInfo[kStopIdNotification]];
}

- (NSString *) mapStopId
{
    return self.notification.userInfo[kStopIdNotification];
}

- (UIColor *)pinTint
{
    return nil;
}

- (bool)hasBearing
{
    return NO;
}

@end
