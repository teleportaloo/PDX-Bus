//
//  CLLocation+Helper.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/25/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "CLLocation+Helper.h"

@implementation CLLocation (Helper)

+ (instancetype)fromStringsLat:(NSString *)lat lng:(NSString *)lng {
    return [[[self class] alloc] initWithLatitude:lat.doubleValue
                                        longitude:lng.doubleValue];
}

+ (instancetype)withLat:(CLLocationDegrees)lat lng:(CLLocationDegrees)lng {
    return [[[self class] alloc] initWithLatitude:lat
                                        longitude:lng];
}

@end
