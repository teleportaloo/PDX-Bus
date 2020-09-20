#define MAXCOLORS 1

//
//  AllRailStationView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/5/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import <Foundation/Foundation.h>
#import "TableViewWithToolbar.h"
#import "ReturnStopId.h"
#import "Stop.h"
#import "RailStation.h"

#define kSearchItemStation @"org.teleportaloo.pdxbus.station"

@interface AllRailStationView : TableViewWithToolbar <ReturnStop>

- (void)generateArrays;
- (void)indexStations;

+ (RailStation *)railstationFromStopId:(NSString *)stopId;
+ (CLLocation *)locationFromStopId:(NSString *)stopId;
+ (RAILLINES)railLines:(int)index;
+ (RAILLINES)railLines0:(int)index;
+ (RAILLINES)railLines1:(int)index;

@end
