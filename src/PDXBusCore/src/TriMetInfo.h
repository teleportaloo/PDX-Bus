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


#include "TriMetInfoColoredLines.h"
#include "TriMetInfoVehicles.h"
#import <Foundation/Foundation.h>

#define kBlockName "trip"
#define kBlockNames kBlockName "s"
#define kBlockNameC "Trip"

@interface TriMetInfo : NSObject {
}

+ (NSString *)tinyNameForRoute:(NSString *)route;
+ (PtrConstRouteInfo)infoForRouteNum:(NSInteger)route;
+ (PtrConstRouteInfo)infoForRoute:(NSString *)route;
+ (PtrConstRouteInfo)infoForLine:(TriMetInfo_ColoredLines)line;
+ (PtrConstRouteInfo)infoForKeyword:(NSString *)key;
+ (TriMetInfo_VehicleConstPtr)vehicleInfo:(NSInteger)vehicleId;
+ (NSString *)vehicleInfoSpecial:(NSInteger)vehicleId;
+ (NSString *)markedUpVehicleString:(NSString *)vehicleId;
+ (NSString *)vehicleIdFromStreetcarId:(NSString *)streetcarId;
+ (NSString *)routeIdString:(PtrConstRouteInfo)info;
+ (NSString *)routeNumberFromInput:(NSString *)input;
+ (NSString *)interlinedRouteString:(PtrConstRouteInfo)info;
+ (NSSet<NSString *> *)streetcarRoutes;
+ (NSSet<NSString *> *)triMetRailLines;
+ (bool)isSingleLoopRoute:(NSString *)route;

@end
