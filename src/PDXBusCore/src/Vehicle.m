//
//  Vehicle.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Vehicle.h"
#import "DebugLogging.h"

@implementation Vehicle



-(NSComparisonResult)compareUsingDistance:(Vehicle*)inVehicle
{
    if (self.distance < inVehicle.distance)
    {
        return NSOrderedAscending;
    }
    
    if (self.distance > inVehicle.distance)
    {
        return NSOrderedDescending;
    }
    
    return NSOrderedSame;
}

- (bool)typeMatchesMode:(TripMode)mode
{
    if (mode == TripModeAll)
    {
        return YES;
    }
    else if (mode == TripModeBusOnly)
    {
        if ([self.type caseInsensitiveCompare:@"bus"] == NSOrderedSame)
        {
            return YES;
        }
    }
    else if (mode == TripModeTrainOnly)
    {
        if ([self.type caseInsensitiveCompare:@"rail"] == NSOrderedSame)
        {
            return YES;
        }
    }
    return NO;
}

+ (NSString *)locatedSomeTimeAgo:(NSDate *)date
{
    NSString *lastSeen = nil;
    NSInteger seconds = -date.timeIntervalSinceNow;
    
    if (seconds < 0)
    {
        lastSeen = @"";
    }
    else if (seconds == 1)
    {
        lastSeen = @"Located 1s ago";
    }
    else if (seconds < 120)
    {
        lastSeen = [NSString stringWithFormat:@"Located %lus ago", (unsigned long)seconds];
    }
    else if (seconds > (3600))
    {
        lastSeen = @"Located over an hour ago";
    }
    else if (seconds >= 120)
    {
        NSInteger mins = ((seconds+30)/60);
        
        if (mins == 1)
        {
            lastSeen = @"Located 1 min ago";
        }
        else
        {
            lastSeen = [NSString stringWithFormat:@"Located %lu mins ago", (unsigned long)mins];
        }
    }

    return lastSeen;
}


@end
