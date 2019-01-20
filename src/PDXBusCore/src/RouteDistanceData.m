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


#import "RouteDistanceData.h"
#import "StopDistanceData.h"

@implementation RouteDistanceData

- (instancetype)init
{
    if ((self = [super init]))
    {    
        self.stops = [NSMutableArray array];
    }
    return self;
}




-(void)sortStopsByDistance
{
    [_stops sortUsingSelector:@selector(compareUsingDistance:)];
}

-(NSComparisonResult)compareUsingDistance:(RouteDistanceData*)inRoute
{
    StopDistanceData *stop =   self.stops.firstObject;
    StopDistanceData *inStop = inRoute.stops.firstObject;
    
    if (stop.distance < inStop.distance)
    {
        return NSOrderedAscending;
    }

    if (stop.distance > inStop.distance)
    {
        return NSOrderedDescending;
    }

    return NSOrderedSame;
}


@end
