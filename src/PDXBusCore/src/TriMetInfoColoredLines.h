//
//  TriMetInfoRailLines.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#ifndef TriMetInfoColoredLines_h
#define TriMetInfoColoredLines_h

#import <Foundation/Foundation.h>

#define kNoRoute 0
#define kNoDir 0
#define kDir1 -1

typedef enum TriMetInfo_LineTypeEnum {
    LineTypeMAX = 0,
    LineTypeStreetcar = 1,
    LineTypeBus = 2,
    LineTypeTram = 3,
    LineTypeWES = 4,
    LineTypeMAXBus = 5
} TriMetInfo_LineType;

#define RGB_SAME 0xFF000000

typedef uint32_t TriMetInfo_ColoredLines;

typedef struct TriMetInfo_RouteStruct {
    NSInteger route_number;
    TriMetInfo_ColoredLines line_bit;
    NSInteger opposite;
    NSInteger interlined_route;
    uint32_t html_color;
    uint32_t html_bg_color;
    uint32_t html_stroke_color;
    NSString *wiki;
    NSString *full_name;
    NSString *short_name;
    NSString *tiny_name;
    TriMetInfo_LineType lineType;
    int sort_order;
    double dash_phase;
    int dash_pattern;
    NSString *key_words;
    bool includeAsRailStop;
    bool optional;
} TriMetInfo_Route;

typedef struct TriMetInfo_AlphaSectionsStruct {
    NSString *title;
    int offset;
    int items;
} TriMetInfo_AlphaSections;

typedef const TriMetInfo_Route *PtrConstRouteInfo;

@class RailStation;
@class CLLocation;

@interface TriMetInfoColoredLines : NSObject {
}

+ (size_t)numOfLines;
+ (PtrConstRouteInfo)allLines;
+ (NSSet<NSString *> *)allCircularRoutes;

@end

int TriMetInfo_compareRouteNumber(const void *first, const void *second);
int TriMetInfo_compareRouteLineBit(const void *first, const void *second);
int TriMetInfo_compareSortOrder(const void *first, const void *second);

#endif /* TriMetInfoRailLines_h */
