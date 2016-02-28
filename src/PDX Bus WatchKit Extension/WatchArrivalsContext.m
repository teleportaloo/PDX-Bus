//
//  WatchArrivalsContext.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/24/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchArrivalsContext.h"
#import "UserFaves.h"
#import "WatchArrivalsInterfaceController.h"

@implementation WatchArrivalsContext

+ (WatchArrivalsContext*)contextWithLocation:(NSString *)location
{
    WatchArrivalsContext *context = [[[WatchArrivalsContext alloc] init] autorelease];
    
    context.locid           = location;
    context.showMap         = NO;
    context.showDistance    = NO;
    context.navText         = nil;
    
    return context;
}
+ (WatchArrivalsContext*)contextWithLocation:(NSString *)location distance:(double)distance
{
    WatchArrivalsContext *context = [[[WatchArrivalsContext alloc] init] autorelease];

    context.locid           = location;
    context.showMap         = YES;
    context.showDistance    = YES;
    context.distance        = distance;
    
    return context;
}


+ (WatchArrivalsContext*)contextWithLocation:(NSString *)location distance:(double)distance stopDesc:(NSString *)stopDesc
{
    WatchArrivalsContext *context = [[[WatchArrivalsContext alloc] init] autorelease];
    
    context.locid           = location;
    context.showMap         = YES;
    context.showDistance    = YES;
    context.distance        = distance;
    context.stopDesc        = stopDesc;
    
    return context;
}

- (id)init
{
    if ((self = [super init]))
    {
        self.sceneName  = kArrivalsScene;
    }
    return self;
}

- (void)updateUserActivity:(WKInterfaceController *)controller
{
    
    NSMutableDictionary *info = [[[NSMutableDictionary alloc] init] autorelease];
    
    [info setObject:self.locid forKey:kUserFavesChosenName];
    [info setObject:self.locid forKey:kUserFavesLocation];
    
    if (self.detailBlock)
    {
        [info setObject:self.detailBlock forKey:kUserFavesBlock];
    }
    
    [controller updateUserActivity:kHandoffUserActivityBookmark userInfo:info webpageURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://trimet.org/arrivals/small/tracker?locationID=%@", self.locid]]];

}

- (bool)hasNext
{
    return NO;
}

- (WatchArrivalsContext *)getNext
{
    return nil;
}



@end
