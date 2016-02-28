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
#import "WatchDepartureUI.h"
#import "WatchContext.h"

#define kArrivalsScene @"Arrivals"

@interface WatchArrivalsContext : WatchContext

@property (retain, nonatomic) NSString *locid;
@property (nonatomic)         bool     showMap;
@property (nonatomic)         double   distance;
@property (nonatomic)         bool     showDistance;
@property (nonatomic, retain) NSString *stopDesc;
@property (nonatomic, retain) NSString *navText;
@property (nonatomic, retain) NSString *detailBlock;

+ (WatchArrivalsContext*)contextWithLocation:(NSString *)location;
+ (WatchArrivalsContext*)contextWithLocation:(NSString *)location distance:(double)distance;
+ (WatchArrivalsContext*)contextWithLocation:(NSString *)location distance:(double)distance stopDesc:(NSString*)stopDesc;

- (void)updateUserActivity:(WKInterfaceController *)controller;


- (bool)hasNext;
- (WatchArrivalsContext *)getNext;


@end
