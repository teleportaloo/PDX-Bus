//
//  WatchArricalsContextNearby.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/10/15.
//  Copyright © 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchArrivalsContextNearby.h"

@implementation WatchArrivalsContextNearby

- (void)dealloc
{
    self.stops = nil;
    [super dealloc];
}

+ (WatchArrivalsContextNearby*)contextFromNearbyStops:(XMLLocateStops *)stops index:(NSInteger)index;
{
    {
        WatchArrivalsContextNearby *context = [[[WatchArrivalsContextNearby alloc] init] autorelease];
        
        StopDistanceData *item = stops[index];
        
        context.locid            = item.locid;
        context.showMap          = YES;
        context.showDistance     = YES;
        context.stops            = stops;
        context.index            = index;
        context.navText          = @"Next nearest";
        context.distance         = item.distance;
       
        return context;
    }
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        self.sceneName  = kArrivalsScene;
    }
    return self;
}

- (bool)hasNext
{
    return self.index < (self.stops.count-1);
}

- (WatchArrivalsContext *)getNext
{
    WatchArrivalsContext *next = nil;
    if (self.hasNext)
    {
        next = [WatchArrivalsContextNearby contextFromNearbyStops:self.stops index:self.index+1];
    }
    return next;
}


- (WatchArrivalsContext *)clone
{
    WatchArrivalsContext *next = nil;
    if (self.hasNext)
    {
        next = [WatchArrivalsContextNearby contextFromNearbyStops:self.stops index:self.index];
    }
    return next;
}


@end
