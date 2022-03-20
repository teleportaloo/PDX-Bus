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
#import "UserState.h"
#import "WatchArrivalsInterfaceController.h"

@interface WatchArrivalsContext ()

@end

@implementation WatchArrivalsContext

+ (WatchArrivalsContext *)contextWithStopId:(NSString *)stopId {
    WatchArrivalsContext *context = [[WatchArrivalsContext alloc] init];
    
    context.stopId = stopId;
    context.showMap = NO;
    context.showDistance = NO;
    context.navText = nil;
    
    return context;
}

+ (WatchArrivalsContext *)contextWithStopId:(NSString *)stopId distance:(double)distance {
    WatchArrivalsContext *context = [[WatchArrivalsContext alloc] init];
    
    context.stopId = stopId;
    context.showMap = YES;
    context.showDistance = YES;
    context.distance = distance;
    
    return context;
}

+ (WatchArrivalsContext *)contextWithStopId:(NSString *)stopId distance:(double)distance stopDesc:(NSString *)stopDesc {
    WatchArrivalsContext *context = [[WatchArrivalsContext alloc] init];
    
    context.stopId = stopId;
    context.showMap = YES;
    context.showDistance = YES;
    context.distance = distance;
    context.stopDesc = stopDesc;
    
    return context;
}

- (instancetype)init {
    if ((self = [super initWithSceneName:kArrivalsScene])) {

    }    
    return self;
}

- (void)updateUserActivity:(WKInterfaceController *)controller {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    info[kUserFavesChosenName] = self.stopId;
    info[kUserFavesLocation] = self.stopId;
    
    if (self.detailBlock) {
        info[kUserFavesBlock] = self.detailBlock;
    }
    
    if (self.detailDir) {
        info[kUserFavesDir] = self.detailDir;
    }
    
    [controller updateUserActivity:kHandoffUserActivityBookmark userInfo:info webpageURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://trimet.org/arrivals/small/tracker?locationID=%@", self.stopId]]];
}

- (bool)hasNext {
    return NO;
}

- (WatchArrivalsContext *)next {
    return nil;
}

- (WatchArrivalsContext *)clone {
    return nil;
}

@end
