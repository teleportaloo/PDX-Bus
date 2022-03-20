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
#include "TriMetInfoRailLines.h"
#include "TriMetInfoVehicles.h"

@class UIColor;

#define kBlockName  "trip"
#define kBlockNames kBlockName "s"
#define kBlockNameC "Trip"


@interface TriMetInfo : NSObject {
}

+ (PtrConstRouteInfo)infoForRouteNum:(NSInteger)route;
+ (PtrConstRouteInfo)infoForRoute:(NSString *)route;
+ (PtrConstRouteInfo)infoForLine:(RailLines)line;
+ (PtrConstRouteInfo)infoForKeyword:(NSString *)key;
+ (PtrConstVehicleInfo)vehicleInfo:(NSInteger)vehicleId;
+ (NSString *)markedUpVehicleString:(NSString *)vehicleId;
+ (NSString *)vehicleIdFromStreetcarId:(NSString *)streetcarId;
+ (NSString *)routeString:(PtrConstRouteInfo)info;
+ (NSString *)routeNumberFromInput:(NSString *)input;
+ (NSString *)interlinedRouteString:(PtrConstRouteInfo)info;
+ (UIColor *)colorForRoute:(NSString *)route;
+ (UIColor *)cachedColor:(NSInteger)col;
+ (NSSet<NSString *> *)streetcarRoutes;
+ (NSSet<NSString *> *)triMetRailLines;
+ (PtrConstRouteInfo)allColoredLines;
+ (bool)isSingleLoopRoute:(NSString *)route;


@end
