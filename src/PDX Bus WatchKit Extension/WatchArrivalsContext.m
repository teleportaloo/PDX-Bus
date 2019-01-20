//
//  WatchArrivalsContext.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/24/15.
//  Copyright (c) 2015 Andrew Wallace
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
    WatchArrivalsContext *context = [[WatchArrivalsContext alloc] init];
    
    context.locid           = location;
    context.showMap         = NO;
    context.showDistance    = NO;
    context.navText         = nil;
    
    return context;
}
+ (WatchArrivalsContext*)contextWithLocation:(NSString *)location distance:(double)distance
{
    WatchArrivalsContext *context = [[WatchArrivalsContext alloc] init];

    context.locid           = location;
    context.showMap         = YES;
    context.showDistance    = YES;
    context.distance        = distance;
    
    return context;
}


+ (WatchArrivalsContext*)contextWithLocation:(NSString *)location distance:(double)distance stopDesc:(NSString *)stopDesc
{
    WatchArrivalsContext *context = [[WatchArrivalsContext alloc] init];
    
    context.locid           = location;
    context.showMap         = YES;
    context.showDistance    = YES;
    context.distance        = distance;
    context.stopDesc        = stopDesc;
    
    return context;
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        self.sceneName  = kArrivalsScene;
    }
    return self;
}

- (void)updateUserActivity:(WKInterfaceController *)controller
{
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    info[kUserFavesChosenName] = self.locid;
    info[kUserFavesLocation]   = self.locid;
    
    if (self.detailBlock)
    {
        info[kUserFavesBlock] = self.detailBlock;
    }
    
    [controller updateUserActivity:kHandoffUserActivityBookmark userInfo:info webpageURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://trimet.org/arrivals/small/tracker?locationID=%@", self.locid]]];

}

- (bool)hasNext
{
    return NO;
}

- (WatchArrivalsContext *)next
{
    return nil;
}

- (WatchArrivalsContext *)clone
{
    return nil;
}



@end
