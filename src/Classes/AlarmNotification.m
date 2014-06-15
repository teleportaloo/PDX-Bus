//
//  AlarmNotification.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/3/11.
//  Copyright 2011 Teleportaloo. All rights reserved.
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
	TriMetTimesAppDelegate *app = [TriMetTimesAppDelegate getSingleton];
	NSString *stopId   = [self.notification.userInfo objectForKey:kStopIdNotification];
	NSString *mapDescr = [self.notification.userInfo objectForKey:kStopMapDescription];
	
	if (self.notification.userInfo)
	{
		if (mapDescr)
		{
			[[app.rootViewController navigationController] popToRootViewControllerAnimated:NO];
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
				currentLocation.pinTitle = NSLocalizedString(@"Current Location", @"map pin");
				currentLocation.pinSubtitle = [NSString stringWithFormat:NSLocalizedString(@"as of %@","location as of time {time}"), stamp];
				[currentLocation setCoord:coord];
				[mapPage addPin:currentLocation];
			}
			
			[[app.rootViewController navigationController] pushViewController:mapPage animated:YES];
          	[mapPage release];
			
		}
		else if (stopId)
		{
			[[app.rootViewController navigationController] popToRootViewControllerAnimated:NO];
		
			DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
			NSString *block = [self.notification.userInfo objectForKey:kAlarmBlock];
			[departureViewController fetchTimesForLocationInBackground:app.rootViewController.backgroundTask
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
			
						
			
			UIAlertView *showArrival = [[[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Alarm", @"alarm message title")
																	 message:notif.alertBody
																	delegate:self
														   cancelButtonTitle:NSLocalizedString(@"OK", @"OK button")
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
	return [NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), [self.notification.userInfo objectForKey:kStopIdNotification]];
}

- (NSString *) mapStopId
{
	return [self.notification.userInfo objectForKey:kStopIdNotification];
}


@end
