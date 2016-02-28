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

#define kRedLine    0x0001
#define kBlueLine   0x0002
#define kGreenLine  0x0004
#define kYellowLine 0x0008
#define kOrangeLine 0x0010
#define kWesLine    0x0020

#define kStreetcarALoop     0x0040
#define kStreetcarBLoop     0x0080
#define kStreetcarNsLine	0x0100

typedef unsigned int RAILLINES;

typedef struct route_cols { 
	NSString *route;
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
+ (ROUTE_COL *)rawColorForLine:(RAILLINES)line;
+ (ROUTE_COL *)rawColorForRoute:(NSString *)route;
+ (NSSet *)streetcarRoutes;
+ (NSSet *)triMetRoutes;

@end
