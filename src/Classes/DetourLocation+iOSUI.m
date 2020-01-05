//
//  DetourLocation+DetourLocation_iOSUI.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/7/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DetourLocation+iOSUI.h"

@implementation DetourLocation (iOSUI)


- (CLLocationCoordinate2D) coordinate
{
    return self.location.coordinate;
}

- (NSString*)title
{
    return self.desc;
}


- (NSString*)subtitle
{
    if (self.noServiceFlag)
    {
        return [NSString stringWithFormat:@"No service at Stop ID %@", self.locid];
    }
    return [NSString stringWithFormat:@"Stop ID %@", self.locid];
}

// From MapPinColor
- (MapPinColorValue) pinColor
{
    if (self.noServiceFlag)
    {
        return MAP_PIN_COLOR_RED;
    }
    return MAP_PIN_COLOR_GREEN;
}
- (bool)showActionMenu
{
    return YES;
}



- (NSString *)mapStopId
{
    return self.locid;
}

- (NSString *)mapStopIdText
{
    if (self.noServiceFlag)
    {
        return [NSString stringWithFormat:@"No service at ID %@", self.locid];
    }
    
     return [NSString stringWithFormat:@"Departures at Stop ID %@", self.locid];
}

- (UIColor *)pinTint
{
    return nil;
}


- (bool)hasBearing
{
    return NO;
}

- (double)doubleBearing
{
    return 0.0;
}

@end
