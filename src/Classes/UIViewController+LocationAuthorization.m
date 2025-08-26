//
//  UIViewController+LocationAuthorization.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/6/16.
//  Copyright © 2016 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "CoreLocation/CoreLocation.h"
#import "DebugLogging.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIApplication+Compat.h"
#import "UIViewController+LocationAuthorization.h"

@implementation UIViewController (LocationAuthorization)

- (void)showLocationAlert:(NSString *)reason {

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:NSLocalizedString(
                                     @"Location Authorization Needed",
                                     @"alarm pop-up title")
                         message:[NSString
                                     stringWithFormat:
                                         NSLocalizedString(
                                             @"%@. Go to the settings app and "
                                             @"select PDX Bus to re-enable "
                                             @"location services.",
                                             @"alarm warning"),
                                         reason]
                  preferredStyle:UIAlertControllerStyleAlert];

    [alert
        addAction:
            [UIAlertAction
                actionWithTitle:kAlertViewOK
                          style:UIAlertActionStyleDestructive
                        handler:^(UIAlertAction *action) {
                          [[UIApplication sharedApplication]
                              compatOpenURL:
                                  [NSURL
                                      URLWithString:
                                          UIApplicationOpenSettingsURLString]];
                        }]];

    [alert addAction:[UIAlertAction actionWithTitle:kAlertViewCancel
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action){

                                            }]];

    [self presentViewController:alert animated:YES completion:nil];
}

+ (bool)locationAuthorizedOrNotDeterminedWithBackground:
    (bool)backgroundRequired {
    return [UIViewController
        locationAuthorizedOrNotDeterminedBackgroundRequired:backgroundRequired
                                             viewController:nil];
}

- (bool)locationAuthorizedOrNotDeterminedAlertWithBackground:
    (bool)backgroundRequired {
    return [UIViewController
        locationAuthorizedOrNotDeterminedBackgroundRequired:backgroundRequired
                                             viewController:self];
}

+ (bool)
    locationAuthorizedOrNotDeterminedBackgroundRequired:(bool)backgroundRequired
                                         viewController:
                                             (UIViewController *)controller {

    CLLocationManager *locMan = [[CLLocationManager alloc] init];
    CLAuthorizationStatus status = locMan.authorizationStatus;

    NSString *reason = nil;

    switch (status) {
    default:
        // User has granted authorization to use their location at any time,
        // including monitoring for regions, visits, or significant location
        // changes.
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

        // User has granted authorization to use their location only when your
        // app is visible to them (it will be made visible to them if you
        // continue to receive location updates while in the background).
        // Authorization to use launch APIs has not been granted.
    case kCLAuthorizationStatusAuthorizedWhenInUse:

        if (backgroundRequired) {
            reason = @"as 'always' access is not granted";
        } else {
            return YES;
        }

        break;
    }

    if (reason != nil && controller) {
        NSString *fullMessage = nil;

        if (backgroundRequired) {
            fullMessage = [NSString
                stringWithFormat:@"PDX Bus is not authorized to get current "
                                 @"location information in the background, %@",
                                 reason];
        } else {
            fullMessage =
                [NSString stringWithFormat:@"PDX Bus is not authorized to get "
                                           @"current location information, %@",
                                           reason];
        }

        [controller showLocationAlert:fullMessage];
    }

    return NO;
}

@end
