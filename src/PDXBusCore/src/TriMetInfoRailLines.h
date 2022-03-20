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


#ifndef TriMetInfoRailLines_h
#define TriMetInfoRailLines_h

#import <Foundation/Foundation.h>

#define kNoRoute    0
#define kNoDir      0
#define kDir1       -1

typedef unsigned int RailLines;

typedef struct RouteInfoStruct {
    NSInteger route_number;
    RailLines line_bit;
    NSInteger opposite;
    NSInteger interlined_route;
    NSInteger html_color;
    NSInteger html_bg_color;
    NSString *wiki;
    NSString *full_name;
    NSString *short_name;
    bool streetcar;
    int sort_order;
    double dash_phase;
    int dash_pattern;
    NSString *key_words;
    bool hasStops;
    bool optional;
} RouteInfo;

typedef const RouteInfo *PtrConstRouteInfo;


PtrConstRouteInfo getAllTriMetRailLines(void);

NSSet<NSString *> * getAllTriMetCircularRoutes(void);

size_t noOfTriMetRailLines(void);
int compareRouteNumber(const void *first, const void *second);
int compareRouteLineBit(const void *first, const void *second);

#endif /* TriMetInfoRailLines_h */
