//
//  WatchPinColor.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/20/15.
//  Copyright © 2015 Teleportaloo. All rights reserved.



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchPinColor.h"

@implementation SimpleWatchPin

- (WKInterfaceMapPinColor)pinColor
{
    return self.simplePinColor;
}

- (UIColor*)pinTint
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
- (CLLocationCoordinate2D)coord
{
    return self.simpleCoord;
}

- (bool)hasCoord
{
    return YES;
}


@end

