//
//  StationData.m
//  PDX Bus
//
//  Created by Andy Wallace on 3/8/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "StationData.h"
#import "CLLocation+Helper.h"
#import "RailStation.h"

#ifndef GENERATE_ARRAYS

#import "../Tables/StaticStationData.c"

#else

// This is dummy data in place for when we are generating the real thing
static const int stationsAlpha[] = {0};
static const TriMetInfo_ColoredLines railLines0[] = {0};
static const TriMetInfo_ColoredLines railLines1[] = {0};
static const TriMetInfo_AlphaSections alphaSections[] = {{@"A", 0, 2}};
static const StopInfo stopInfo[] = {
    //   Stop ID  Index Latitude                 Longitude TP Lines
    {2167, 176, 45.52281035015929688825, -122.66062095890700334166, 0, 0x0040},
};

static const int sortedColoredLines[] = {0};

#endif

int compareStopInfos(const void *first, const void *second) {
    return (int)(((StopInfo *)first)->stopId - ((StopInfo *)second)->stopId);
}

@implementation StationData

+ (const int *)getStationAlphaAndCount:(size_t *)count {
    if (count != NULL) {
        *count = sizeof(stationsAlpha) / sizeof(stationsAlpha[0]);
    }
    return stationsAlpha;
}

+ (const int *)getSortedColoredLines {
    return sortedColoredLines;
}

+ (TriMetInfo_ColoredLines)railLines:(int)index {
    return railLines0[index] | railLines1[index];
}

+ (TriMetInfo_ColoredLines)railLines0:(int)index {
    return railLines0[index];
}

+ (TriMetInfo_ColoredLines)railLines1:(int)index {
    return railLines1[index];
}

+ (const TriMetInfo_AlphaSections *)getAlphaSectionsAndCount:(size_t *)count {
    if (count != nil) {
        *count = sizeof(alphaSections) / sizeof(alphaSections[0]);
    }
    return alphaSections;
}

+ (RailStation *)railstationFromStopId:(NSString *)stopId {
    RailStation *res = nil;
    StopInfo key = {(long)stopId.longLongValue, 0, 0, 0};

    StopInfo *result = (StopInfo *)bsearch(
        &key, stopInfo, sizeof(stopInfo) / sizeof(stopInfo[0]),
        sizeof(stopInfo[0]), compareStopInfos);

    if (result) {
        res = [RailStation fromHotSpotIndex:result->hotspot];
    }

    return res;
}

+ (CLLocation *)locationFromStopId:(NSString *)stopId {
    CLLocation *res = nil;

    StopInfo key = {(long)stopId.longLongValue, 0};

    StopInfo *result = (StopInfo *)bsearch(
        &key, stopInfo, sizeof(stopInfo) / sizeof(stopInfo[0]),
        sizeof(stopInfo[0]), compareStopInfos);

    if (result) {
        res = [CLLocation withLat:result->lat lng:result->lng];
    }

    return res;
}

+ (TriMetInfo_ColoredLines)railLinesForStopId:(NSString *)stopId {
    TriMetInfo_ColoredLines lines = 0;

    StopInfo key = {(long)stopId.longLongValue, 0};

    StopInfo *result = (StopInfo *)bsearch(
        &key, stopInfo, sizeof(stopInfo) / sizeof(stopInfo[0]),
        sizeof(stopInfo[0]), compareStopInfos);

    if (result) {
        lines = result->lines;
    }

    return lines;
}

+ (bool)tpFromStopId:(NSString *)stopId {
    StopInfo key = {(long)stopId.longLongValue, 0};

    StopInfo *result = (StopInfo *)bsearch(
        &key, stopInfo, sizeof(stopInfo) / sizeof(stopInfo[0]),
        sizeof(stopInfo[0]), compareStopInfos);

    if (result) {
        return result->tp;
    }

    return NO;
}

@end
