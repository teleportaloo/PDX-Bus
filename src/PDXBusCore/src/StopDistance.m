//
//  StopDistance.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "StopDistance.h"

@implementation StopDistance

- (instancetype)initWithStopId:(int)stopId
                distanceMeters:(CLLocationDistance)dist
                      accuracy:(CLLocationAccuracy)acc {
    if ((self = [super init])) {
        self.stopId = [NSString stringWithFormat:@"%d", stopId];
        self.distanceMeters = dist;
        self.accuracy = acc;
    }

    return self;
}

- (NSComparisonResult)compareUsingDistance:(StopDistance *)inStop {
    if (self.distanceMeters < inStop.distanceMeters) {
        return NSOrderedAscending;
    }

    if (self.distanceMeters > inStop.distanceMeters) {
        return NSOrderedDescending;
    }

    return [self.stopId compare:inStop.stopId];
}

@end
