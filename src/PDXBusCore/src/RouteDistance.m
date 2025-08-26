//
//  RouteDistance.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/9/11.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RouteDistance.h"
#import "StopDistance.h"

@implementation RouteDistance

- (instancetype)init {
    if ((self = [super init])) {
        self.stops = [NSMutableArray array];
    }

    return self;
}

- (void)sortStopsByDistance {
    [_stops sortUsingSelector:@selector(compareUsingDistance:)];
}

- (NSComparisonResult)compareUsingDistance:(RouteDistance *)inRoute {
    StopDistance *stop = self.stops.firstObject;
    StopDistance *inStop = inRoute.stops.firstObject;

    if (stop.distanceMeters < inStop.distanceMeters) {
        return NSOrderedAscending;
    }

    if (stop.distanceMeters > inStop.distanceMeters) {
        return NSOrderedDescending;
    }

    return NSOrderedSame;
}

@end
