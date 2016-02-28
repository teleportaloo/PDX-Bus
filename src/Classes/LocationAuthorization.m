//
//  LocationAuthorization.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/6/16.
//  Copyright © 2016 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "LocationAuthorization.h"
#import "CoreLocation/CoreLocation.h"
#import "DebugLogging.h"
@implementation LocationAuthorization



-(void)dealloc
{
    [super dealloc];
}
+ (void)showLocationAlert:(NSString *)reason
{
    if  ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0)
    {
        LocationAuthorization *alert = [[[ LocationAuthorization alloc ] initWithTitle:NSLocalizedString(@"Location Authorization Needed",@"alarm pop-up title")
                                                                               message:[NSString stringWithFormat:NSLocalizedString(@"%@. Go to the settings app and select PDX Bus to re-enable location services.", @"alarm warning"), reason]
                                                                              delegate:nil
                                                                     cancelButtonTitle:NSLocalizedString(@"OK",@"OK button")
                                                                     otherButtonTitles:@"Go to settings", nil] autorelease];
        
        alert.delegate = alert;
        [alert show];
        
        DEBUG_LOGRC(alert);
    }
    else
    {
        
        UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Location Authorization Needed",@"alarm pop-up title")
                                                           message:[NSString stringWithFormat:NSLocalizedString(@"%@. Go to the settings app and select PDX Bus to re-enable location services.", @"alarm warning"), reason]
                                                          delegate:nil
                                                 cancelButtonTitle:NSLocalizedString(@"OK",@"OK button")
                                                 otherButtonTitles:nil] autorelease];
        [alert show];
    }
}


// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex !=0)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
    
    DEBUG_LOGRC(self);
}

- (void)alertViewCancel:(UIAlertView *)alertView
{
    
    DEBUG_LOGRC(self);
}


+ (bool)locationAuthorizedOrNotDeterminedShowMsg:(bool)msg backgroundRequired:(bool)backgroundRequired
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    NSString *reason = nil;
    
    switch (status)
    {
        default:
            // User has granted authorization to use their location at any time,
            // including monitoring for regions, visits, or significant location changes.
        case kCLAuthorizationStatusAuthorizedAlways:
            // User has not yet made a choice with regards to this application
        case kCLAuthorizationStatusNotDetermined:
            
            // IT'S ALL GOOD SO FAR
            return YES;
            break;
            // This application is not authorized to use location services.  Due
            // to active restrictions on location services, the user cannot change
            // this status, and may not have personally denied authorization
        case kCLAuthorizationStatusRestricted:
            reason = @"as access is restricted";
            break;
            
            // User has explicitly denied authorization for this application, or
            // location services are disabled in Settings.
        case kCLAuthorizationStatusDenied:
            reason = @"as access is denied";
            break;
            
            // User has granted authorization to use their location only when your app
            // is visible to them (it will be made visible to them if you continue to
            // receive location updates while in the background).  Authorization to use
            // launch APIs has not been granted.
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            
            if (backgroundRequired)
            {
                reason = @"as 'always' access is not granted";
            }
            else
            {
                return YES;
            }
            break;
    }
    
    if (reason != nil && msg)
    {
        NSString *fullMessage = nil;
        
        if (backgroundRequired)
        {
            fullMessage = [NSString stringWithFormat:@"PDX Bus is not authorized to get current location information in the background, %@", reason];
        }
        else
        {
            fullMessage = [NSString stringWithFormat:@"PDX Bus is not authorized to get current location information, %@", reason];
        }

        [LocationAuthorization showLocationAlert:fullMessage];
        
    }
    
    return NO;
    
}

@end
