//
//  WatchArrivalsContext.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/24/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

#import "WatchArrivalsContext.h"

@implementation WatchArrivalsContext

+ (WatchArrivalsContext*)contextWithLocation:(NSString *)location
{
    WatchArrivalsContext *context = [[[WatchArrivalsContext alloc] init] autorelease];
    
    context.locid           = location;
    context.showMap         = NO;
    context.showDistance    = NO;
    
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

@end
