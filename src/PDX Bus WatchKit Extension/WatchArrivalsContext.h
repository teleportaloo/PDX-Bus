//
//  WatchArrivalsContext.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/24/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DepartureData+watchOSUI.h"
#import "WatchContext.h"
#import "XMLDepartures.h"
#import "XMLDetours.h"
#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

#define kArrivalsScene @"Arrivals"

@interface WatchArrivalsContext : WatchContext

@property(nonatomic, copy) NSString *stopDesc;
@property(nonatomic, copy) NSString *navText;
@property(nonatomic, readonly) bool hasNext;
@property(nonatomic) bool showMap;
@property(nonatomic) bool showDistance;
@property(nonatomic) double distance;
@property(nonatomic, copy) NSString *stopId;
@property(nonatomic, copy) NSString *detailBlock;
@property(nonatomic, copy) NSString *detailDir;
@property(nonatomic, strong) XMLDepartures *departures;
@property(nonatomic, readonly, strong) WatchArrivalsContext *next;
@property(nonatomic, readonly, strong) WatchArrivalsContext *clone;

- (void)updateUserActivity:(WKInterfaceController *)controller;

+ (WatchArrivalsContext *)contextWithStopId:(NSString *)stopId;
+ (WatchArrivalsContext *)contextWithStopId:(NSString *)stopId
                                   distance:(double)distance;
+ (WatchArrivalsContext *)contextWithStopId:(NSString *)stopId
                                   distance:(double)distance
                                   stopDesc:(NSString *)stopDesc;

@end
