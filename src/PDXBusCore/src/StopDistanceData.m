//
//  StopDistance.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "StopDistanceData.h"


@implementation StopDistanceData



-(instancetype)initWithLocId:(int)loc distance:(CLLocationDistance)dist accuracy:(CLLocationAccuracy)acc
{
    if ((self = [super init]))
    {
        
        self.locid = [NSString stringWithFormat:@"%d", loc];
        self.distance = dist;        
        self.accuracy = acc;
    }
    return self;
}

-(NSComparisonResult)compareUsingDistance:(StopDistanceData*)inStop
{
    if (self.distance < inStop.distance)
    {
        return NSOrderedAscending;
    }
    
    if (self.distance > inStop.distance)
    {
        return NSOrderedDescending;
    }
    
    return [self.locid compare:inStop.locid];
}

@end
