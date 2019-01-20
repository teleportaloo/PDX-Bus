//
//  WatchArrivalsContext.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/24/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>
#import "DepartureData+watchOSUI.h"
#import "WatchContext.h"
#import "XMLDepartures.h"
#import "XMLDetours.h"

#define kArrivalsScene @"Arrivals"

@interface WatchArrivalsContext : WatchContext

@property (copy, nonatomic)   NSString *locid;
@property (nonatomic)         bool     showMap;
@property (nonatomic)         double   distance;
@property (nonatomic)         bool     showDistance;
@property (nonatomic, copy)   NSString *stopDesc;
@property (nonatomic, copy)   NSString *navText;
@property (nonatomic, copy)   NSString *detailBlock;
@property (nonatomic, retain) XMLDepartures *departures;

+ (WatchArrivalsContext*)contextWithLocation:(NSString *)location;
+ (WatchArrivalsContext*)contextWithLocation:(NSString *)location distance:(double)distance;
+ (WatchArrivalsContext*)contextWithLocation:(NSString *)location distance:(double)distance stopDesc:(NSString*)stopDesc;

- (void)updateUserActivity:(WKInterfaceController *)controller;


@property (nonatomic, readonly) bool hasNext;
@property (nonatomic, readonly, strong) WatchArrivalsContext *next;
@property (nonatomic, readonly, strong) WatchArrivalsContext *clone; 


@end
