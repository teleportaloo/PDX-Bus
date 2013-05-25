//
//  AlarmNotification.m
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



#import "AlarmNotification.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"
#import "AlarmTask.h"
#import "DepartureTimesView.h"
#import "RootViewController.h"
#import "MapViewController.h"
#import "SimpleAnnotation.h"

@implementation AlarmNotification

@synthesize notification = _notification;
@synthesize previousState = _previousState;

- (void)dealloc
{
    if (_soundID != 0)
    {
        AudioServicesDisposeSystemSoundID(_soundID);
    }
	self.notification = nil;
	[super dealloc];
}

- (void)executeAction
{
	TriMetTimesAppDelegate *appDelegate = [TriMetTimesAppDelegate getSingleton];
	NSString *stopId   = [self.notification.userInfo objectForKey:kStopIdNotification];
	NSString *mapDescr = [self.notification.userInfo objectForKey:kStopMapDescription];
	
	if (self.notification.userInfo)
	{
		if (mapDescr)
		{
            DEBUG_LOG(@"Popping stack");
			[[appDelegate.rootViewController navigationController] popToRootViewControllerAnimated:NO];
			MapViewController *mapPage = [[MapViewController alloc] init];
			
			
			NSNumber *lat = [self.notification.userInfo objectForKey:kCurrLocLat];
			NSNumber *lng = [self.notification.userInfo objectForKey:kCurrLocLng];
			NSString *stamp = [self.notification.userInfo objectForKey:kCurrTimestamp];
			
			if (lat && lng)
			{
				CLLocationCoordinate2D coord;
				coord.latitude  = [lat doubleValue];
				coord.longitude = [lng doubleValue];
			
				SimpleAnnotation *currentLocation = [[[SimpleAnnotation alloc] init] autorelease];
				currentLocation.pinColor = MKPinAnnotationColorPurple;
				currentLocation.pinTitle = @"Current Location";
				currentLocation.pinSubtitle = [NSString stringWithFormat:@"as of %@", stamp];
				[currentLocation setCoord:coord];
				[mapPage addPin:currentLocation];
			}
			
			[mapPage addPin:self];
			[[appDelegate.rootViewController navigationController] pushViewController:mapPage animated:YES];
			[mapPage release];
			
		}
		else if (stopId)
		{
            DEBUG_LOG(@"Popping stack");
			[[appDelegate.rootViewController navigationController] popToRootViewControllerAnimated:NO];
			
			DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
			NSString *block = [self.notification.userInfo objectForKey:kAlarmBlock];
			
			[departureViewController fetchTimesForLocationInBackground:appDelegate.rootViewController.backgroundTask 
																   loc:stopId
																 block:block];
			[departureViewController release];
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
		if (notif.userInfo!=nil && [notif.userInfo objectForKey:kDoNotDisplayIfActive]==nil)
		{
            UInt32 sessionCategory = kAudioSessionCategory_AmbientSound;    
            
            AudioSessionSetProperty (
                                     kAudioSessionProperty_AudioCategory,     
                                     sizeof (sessionCategory),                        
                                     &sessionCategory                     
                                     );
            
            
            NSString *soundFile = notif.soundName;
            
            DEBUG_LOG(@"Playing sound %@\n", notif.soundName);
            
            if ([soundFile isEqualToString:@"UILocalNotificationDefaultSoundName"])
            {
                soundFile = @"default_sound.wav";
            }
			
			// UserPrefs *prefs = [UserPrefs getSingleton];
            //Get the filename of the sound file:
            NSString *path = [NSString stringWithFormat:@"%@/%@",
								  [[NSBundle mainBundle] resourcePath],
								  soundFile];
				
            //Get a URL for the sound file
            NSURL *filePath = [NSURL fileURLWithPath:path isDirectory:NO];
				
            //Use audio sevices to create the sound
            AudioServicesCreateSystemSoundID((CFURLRef)filePath, &_soundID);
        
			
			//Use audio services to play the sound
			AudioServicesPlaySystemSound(_soundID);
			// AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
			
						
			
			UIAlertView *showArrival = [[[ UIAlertView alloc ] initWithTitle:@"Alarm"
																	 message:notif.alertBody
																	delegate:self
														   cancelButtonTitle:@"OK"
														   otherButtonTitles:notif.alertAction, nil] autorelease];
			[self retain];
			[showArrival show]; 
		}
	}
	
}

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1)
	{
		[self executeAction];		
	}
	[self release];
}

- (MKPinAnnotationColor) getPinColor
{
	return MKPinAnnotationColorGreen;
}

- (bool) showActionMenu
{
	return YES;
}

- (CLLocationCoordinate2D)coordinate
{
	CLLocationCoordinate2D coord;
	NSNumber *lat = [self.notification.userInfo objectForKey:kStopMapLat];
	NSNumber *lng = [self.notification.userInfo objectForKey:kStopMapLng];
	coord.latitude  = [lat doubleValue];
	coord.longitude = [lng doubleValue];
	
	return coord;
	
}

- (NSString *)title
{
	return [self.notification.userInfo objectForKey:kStopMapDescription];
}

- (NSString *)subtitle
{
	return [NSString stringWithFormat:@"Stop ID %@", [self.notification.userInfo objectForKey:kStopIdNotification]];
}

- (NSString *) mapStopId
{
	return [self.notification.userInfo objectForKey:kStopIdNotification];
}


@end
