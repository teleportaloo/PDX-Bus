//
//  WatchArricalsContextNearby.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/10/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchArrivalsContextNearby.h"

@interface WatchArrivalsContextNearby ()

@property (nonatomic, strong) XMLLocateStops *stops;
@property (nonatomic)         NSInteger index;

@end

@implementation WatchArrivalsContextNearby

+ (WatchArrivalsContextNearby *)contextFromNearbyStops:(XMLLocateStops *)stops index:(NSInteger)index; {
    {
        WatchArrivalsContextNearby *context = [[WatchArrivalsContextNearby alloc] init];
        
        StopDistance *item = stops[index];
        
        context.stopId = item.stopId;
        context.showMap = YES;
        context.showDistance = YES;
        context.stops = stops;
        context.index = index;
        context.navText = @"Next nearest swipe ←";
        context.distance = item.distance;
        
        return context;
    }
}

- (instancetype)init {
    if ((self = [super init])) {
        self.sceneName = kArrivalsScene;
    }
    
    return self;
}

- (bool)hasNext {
    return self.index < (self.stops.count - 1);
}

- (WatchArrivalsContext *)next {
    WatchArrivalsContext *next = nil;
    
    if (self.hasNext) {
        next = [WatchArrivalsContextNearby contextFromNearbyStops:self.stops index:self.index + 1];
    }
    
    return next;
}

- (WatchArrivalsContext *)clone {
    WatchArrivalsContext *next = nil;
    
    if (self.hasNext) {
        next = [WatchArrivalsContextNearby contextFromNearbyStops:self.stops index:self.index];
    }
    
    return next;
}

@end
