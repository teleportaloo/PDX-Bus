//
//  StationData.h
//  PDX Bus
//
//  Created by Andy Wallace on 3/8/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "HotSpot.h"
#include "TriMetInfoColoredLines.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface StationData : NSObject

+ (const int *)getStationAlphaAndCount:(size_t *__nullable)count;
+ (TriMetInfo_ColoredLines)railLines:(int)index;
+ (TriMetInfo_ColoredLines)railLines0:(int)index;
+ (TriMetInfo_ColoredLines)railLines1:(int)index;
+ (const int *)getSortedColoredLines;
+ (const TriMetInfo_AlphaSections *)getAlphaSectionsAndCount:
    (size_t *__nullable)count;
+ (RailStation *_Nullable)railstationFromStopId:(NSString *)stopId;
+ (CLLocation *_Nullable)locationFromStopId:(NSString *)stopId;
+ (TriMetInfo_ColoredLines)railLinesForStopId:(NSString *)stopId;
+ (bool)tpFromStopId:(NSString *)stopId;

@end

int compareStopInfos(const void *first, const void *second);

NS_ASSUME_NONNULL_END
