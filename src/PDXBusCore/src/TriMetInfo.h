//
//  TriMetRouteInfo.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/30/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "UIColor+DarkMode.h"

@class UIColor;

#define kBlockName  "trip"
#define kBlockNames  kBlockName "s"
#define kBlockNameC "Trip"
#define kNoRoute     0

#define kNoDir       0
#define kDir1       -1




typedef unsigned int RAILLINES;

typedef struct route_info {
	NSInteger       route_number;
	RAILLINES       line_bit;
    NSInteger       opposite;
    NSInteger       interlined_route;
    NSInteger       html_color;
    NSInteger       html_bg_color;
	NSString *      wiki;
	NSString *      full_name;
	NSString *      short_name;
    bool            streetcar;
    int             sort_order;
    double          dash_phase;
    int             dash_pattern;
} ROUTE_INFO;

typedef const ROUTE_INFO *PC_ROUTE_INFO;

typedef struct vehicle_info {
    NSInteger       min;
    NSInteger       max;
    NSString *      type;
    NSString *      manufacturer;
    NSString *      model;
    NSString *      first_used;
    bool            check_for_multiple;
    NSString *      specialInfo;
} VEHICLE_INFO;

typedef const VEHICLE_INFO *PC_VEHICLE_INFO;

@interface TriMetInfo : NSObject {
	
}

+ (PC_ROUTE_INFO)infoForRouteNum:(NSInteger)route;
+ (PC_ROUTE_INFO)infoForRoute:(NSString *)route;
+ (PC_ROUTE_INFO)infoForLine:(RAILLINES)line;

+ (PC_VEHICLE_INFO)vehicleInfo:(NSInteger)vehicleId;
+ (NSString *)vehicleString:(NSString *)vehicleId;
+ (NSString*)vehicleIdFromStreetcarId:(NSString*)streetcarId;
+ (NSString*)routeString:(PC_ROUTE_INFO)info;
+ (NSString*)interlinedRouteString:(PC_ROUTE_INFO)info;
+ (UIColor*)colorForRoute:(NSString *)route;
+ (UIColor*)cachedColor:(NSInteger)col;
+ (NSSet<NSString*> *)streetcarRoutes;
+ (NSSet<NSString*> *)triMetRailLines;
+ (PC_ROUTE_INFO)allColoredLines;


@end
