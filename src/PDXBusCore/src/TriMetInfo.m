//
//  TriMetInfo.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/30/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogDataManagement

#import "TriMetInfo.h"
#import "PDXBusCore.h"
#import "DebugLogging.h"
#import "NSString+Helper.h"

@implementation TriMetInfo

+ (PtrConstVehicleInfo)vehicleInfo:(NSInteger)vehicleId {
    VehicleInfo key = { vehicleId, NO_VEHICLE_ID, nil, nil, nil, nil };
    return bsearch(&key, getTriMetVehicleInfo(), noOfTriMetVehicles(), sizeof(VehicleInfo), compareVehicle);
}

+ (NSString *)markedUpVehicleString:(NSString *)vehicleId {
    NSString *string;
    const VehicleInfo *vehicle = [TriMetInfo vehicleInfo:vehicleId.integerValue];
    
    if (vehicle == nil) {
        if (vehicleId != nil) {
            string = [NSString stringWithFormat:@"Vehicle ID #b%@#b\n#b#RNo vehicle info.#b", vehicleId];
        } else {
            string = @"#b#RNo vehicle info.#b";
        }
    } else {
        string = [NSString stringWithFormat:@"Vehicle ID #D#b%@#b - #b%@#b#D\nMade by #b%@#b#D%@\nIntroduced #b#D%@#b#D%@",
                   vehicleId,
                   vehicle->type,
                   vehicle->markedUpManufacturer,
                   vehicle->markedUpModel.length != 0 ? [NSString stringWithFormat:@"\nModel #D#b%@#b", vehicle->markedUpModel] : @"",
                   vehicle->first_used,
                   vehicle->markedUpSpecialInfo ? [NSString stringWithFormat:@"\n%@", vehicle->markedUpSpecialInfo] : @""
                   ];
    }
    
    return string;
}

+ (NSString *)vehicleIdFromStreetcarId:(NSString *)streetcarId {
    // Streetcar ID is of the form SC024 - we drop the SC
    
    if ([streetcarId hasPrefix:@"SC"]) {
        return [streetcarId substringFromIndex:2];
    }
    
    // Streetcar ID is of the form S024 - we drop the S
    
    if ([streetcarId hasPrefix:@"S"]) {
        return [streetcarId substringFromIndex:1];
    }
    
    // Dunno what this is!  
    return streetcarId;
}

#pragma mark Routes and Lines and Colors

+ (PtrConstRouteInfo)infoForKeyword:(NSString *)key {
    NSString *lower = [key lowercaseString];
    
    for (PtrConstRouteInfo info = getAllTriMetRailLines(); info->route_number != kNoRoute; info++) {
        NSArray<NSString *> *keyWords = info->key_words.mutableArrayFromCommaSeparatedString;
        
        for (NSString *keyWord in keyWords)
        {
            if ([lower containsString:keyWord]) {
                return info;
            }
        }
    }
    
    return nil;
}

+ (PtrConstRouteInfo)infoForLine:(RailLines)line {
    RouteInfo key = { 0, line, 0, 0, 0, 0, nil, nil, nil, NO };
    return bsearch(&key, getAllTriMetRailLines(), noOfTriMetRailLines(), sizeof(RouteInfo), compareRouteLineBit);
}

+ (PtrConstRouteInfo)infoForRouteNum:(NSInteger)route {    
    RouteInfo key = { route, 0, 0, 0, 0, 0, nil, nil, nil, NO };
    return bsearch(&key, getAllTriMetRailLines(), noOfTriMetRailLines(), sizeof(RouteInfo), compareRouteNumber);
}

+ (PtrConstRouteInfo)infoForRoute:(NSString *)route {
    return [TriMetInfo infoForRouteNum:route.integerValue];
}

+ (UIColor *)cachedColor:(NSInteger)col {
    static NSMutableDictionary<NSNumber *, UIColor *> *colorCache;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        colorCache = [NSMutableDictionary dictionary];
        
        for (PtrConstRouteInfo col = getAllTriMetRailLines(); col->route_number != kNoRoute; col++) {
            [colorCache setObject:HTML_COLOR(col->html_color)     forKey:@(col->html_color)];
            [colorCache setObject:HTML_COLOR(col->html_bg_color)  forKey:@(col->html_bg_color)];
        }
    });
    
    return colorCache[@(col)];
}

+ (UIColor *)colorForRoute:(NSString *)route {
    PtrConstRouteInfo routeInfo = [TriMetInfo infoForRoute:route];
    
    if (routeInfo == nil) {
        return nil;
    }
    
    return [TriMetInfo cachedColor:routeInfo->html_color];
}

+ (UIColor *)colorForLine:(RailLines)line {
    PtrConstRouteInfo routeInfo = [TriMetInfo infoForLine:line];
    
    if (routeInfo == nil) {
        return nil;
    }
    
    return [TriMetInfo cachedColor:routeInfo->html_color];
}

+ (NSSet<NSString *> *)streetcarRoutes {
    static NSMutableSet<NSString *> *routeIds = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        routeIds = [NSMutableSet set];
        
        for (PtrConstRouteInfo info = getAllTriMetRailLines(); info->route_number != kNoRoute; info++) {
            if (info->streetcar) {
                [routeIds addObject:[TriMetInfo routeString:info]];
            }
        }
    });
    
    return routeIds;
}

+ (NSSet<NSString *> *)triMetRailLines {
    static NSMutableSet<NSString *> *routeIds = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        routeIds = [NSMutableSet set];
        
        for (PtrConstRouteInfo routeInfo = getAllTriMetRailLines(); routeInfo->route_number != kNoRoute; routeInfo++) {
            if (!routeInfo->streetcar) {
                [routeIds addObject:[TriMetInfo routeString:routeInfo]];
            }
        }
    });
    
    return routeIds;
}

+ (NSString *)routeString:(const RouteInfo *)info {
    if (info) {
        return [NSString stringWithFormat:@"%ld", (long)info->route_number];
    }
    return nil;
}

+ (NSString *)routeNumberFromInput:(NSString *)input {

    if (input != nil)
    {
        NSString *routeNumber = [input justNumbers];
    
        if (routeNumber.length == 0) {
            routeNumber =  [TriMetInfo routeString:[TriMetInfo infoForKeyword:input]];
        }
        
        return routeNumber;
    }
    return nil;
}

+ (NSString *)interlinedRouteString:(const RouteInfo *)info {
    return [NSString stringWithFormat:@"%ld", (long)info->interlined_route];
}

+ (const RouteInfo *)allColoredLines {
    return getAllTriMetRailLines();
}





+ (bool)isSingleLoopRoute:(NSString *)route
{    
    return [getAllTriMetCircularRoutes() containsObject:route];
}

@end
