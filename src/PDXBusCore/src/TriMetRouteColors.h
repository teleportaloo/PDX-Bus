//
//  TriMetRouteColors.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/30/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>

@class UIColor;

// These must be in route number order for fast lookup
#define kRedLine            0x0001 // 90
#define kBlueLine           0x0002 // 100
#define kYellowLine         0x0004 // 190
#define kStreetcarNsLine	0x0008 // 193
#define kStreetcarALoop     0x0010 // 194
#define kStreetcarBLoop     0x0020 // 195
#define kGreenLine          0x0040 // 200
#define kWesLine            0x0080 // 203
#define kOrangeLine         0x0100 // 290
#define kNoLine             0x0000

#define kNoRoute            0

typedef unsigned int RAILLINES;

typedef struct route_cols { 
	NSInteger route;
	RAILLINES line;
	float r;
	float g;
	float b;
    float back_r;
    float back_g;
    float back_b;
	NSString *wiki;
	NSString *name;
	NSString *type;
    bool  square;
} ROUTE_COL;

@interface TriMetRouteColors : NSObject {
	
}

+ (UIColor*)colorForRoute:(NSString *)route;
+ (const ROUTE_COL *)rawColorForLine:(RAILLINES)line;
+ (const ROUTE_COL *)rawColorForRoute:(NSString *)route;
+ (NSSet *)streetcarRoutes;
+ (NSSet *)triMetRoutes;
+ (NSString*)routeString:(const ROUTE_COL*)col;

@end
