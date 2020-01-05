//
//  StopDistanceUI.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/21/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "StopDistance+iOSUI.h"

@implementation StopDistance (iOSUI)


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
    return self.location.coordinate;
}

- (NSString *)title
{
    
    return self.desc;
}

- (NSString *)subtitle
{
    NSString *dir = @"";
    
    if (self.dir != nil)
    {
        dir = self.dir;
    }
    
    return [NSString stringWithFormat:NSLocalizedString(@"Stop ID %@ %@", @"TriMet Stop identifer <number>"), self.locid, dir];
}

- (NSString *) mapStopId
{
    return self.locid;
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
