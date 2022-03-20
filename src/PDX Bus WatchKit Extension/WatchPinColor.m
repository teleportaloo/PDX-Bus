//
//  WatchPinColor.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/20/15.
//  Copyright © 2015 Andrew Wallace



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchPinColor.h"

@implementation SimpleWatchPin

- (WKInterfaceMapPinColor)pinColor {
    return self.simplePinColor;
}

- (UIColor *)pinTint {
    return nil;
}

- (bool)pinHasBearing {
    return NO;
}

- (double)pinBearing {
    return 0.0;
}

- (CLLocationCoordinate2D)pinCoord {
    return self.simpleCoord;
}

- (bool)pinHasCoord {
    return YES;
}

@end
