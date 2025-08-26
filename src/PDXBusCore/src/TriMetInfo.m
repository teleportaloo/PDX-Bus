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


#define DEBUG_LEVEL_FOR_FILE LogData

#import "TriMetInfo.h"
#import "DebugLogging.h"
#import "NSString+Core.h"
#import "PDXBusCore.h"
#import "TaskDispatch.h"

@implementation TriMetInfo

+ (TriMetInfo_VehicleConstPtr)vehicleInfo:(NSInteger)vehicleId {
    TriMetInfo_Vehicle key = {vehicleId, NO_VEHICLE_ID, nil, nil, nil, nil};
    return (TriMetInfo_VehicleConstPtr)bsearch(
        &key, TriMetInfo_getVehicle(), TriMetInfo_noOfVehicles(),
        sizeof(TriMetInfo_Vehicle), TriMetInfo_compareVehicle);
}

+ (NSString *)vehicleInfoSpecial:(NSInteger)vehicleId {

    TriMetInfo_VehicleSpecial key = {vehicleId, nil};

    TriMetInfo_VehicleSpecialConstPtr found =
        (TriMetInfo_VehicleSpecialConstPtr)bsearch(
            &key, TriMetInfo_getVehicleSpecial(),
            TriMetInfo_noOfVehicleSpecials(), sizeof(TriMetInfo_VehicleSpecial),
            TriMetInfo_compareVehicleSpecial);

    if (found) {
        return found->markedUpSpecialInfo;
    }
    return nil;
}

+ (NSString *)markedUpVehicleString:(NSString *)vehicleId {
    NSString *string;
    const TriMetInfo_Vehicle *vehicle =
        [TriMetInfo vehicleInfo:vehicleId.integerValue];

    if (vehicle == nil) {
        if (vehicleId != nil) {
            string = [NSString
                stringWithFormat:@"Vehicle ID #b%@#b\n#b#RNo vehicle info.#b",
                                 vehicleId];
        } else {
            string = @"#b#RNo vehicle info.#b";
        }
    } else {
        NSString *markedUpSpecialInfo =
            [self vehicleInfoSpecial:vehicleId.integerValue];
        string = [NSString
            stringWithFormat:@"Vehicle ID #D#b%@#b - #b%@#b#D\nMade by "
                             @"#b%@#b#D%@%@\nIntroduced #b#D%@#b#D%@",
                             vehicleId, vehicle->type,
                             vehicle->markedUpManufacturer,
                             vehicle->markedUpModel.length != 0
                                 ? [NSString
                                       stringWithFormat:@"\nModel #D#b%@#b",
                                                        vehicle->markedUpModel]
                                 : @"",
                             vehicle->fuel == nil
                                 ? @""
                                 : [NSString stringWithFormat:@" #D#b%@#b",
                                                              vehicle->fuel],
                             vehicle -> first_used,
                             markedUpSpecialInfo
                                 ? [NSString
                                       stringWithFormat:@"\n%@",
                                                        markedUpSpecialInfo]
                                 : @""];
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

    for (PtrConstRouteInfo info = [TriMetInfoColoredLines allLines];
         info->route_number != kNoRoute; info++) {
        NSArray<NSString *> *keyWords =
            info->key_words.mutableArrayFromCommaSeparatedString;

        for (NSString *keyWord in keyWords) {
            if ([lower containsString:keyWord]) {
                return info;
            }
        }
    }

    return nil;
}

+ (PtrConstRouteInfo)infoForLine:(TriMetInfo_ColoredLines)line {
    TriMetInfo_Route key = {0, line, 0, 0, 0, 0, 0, nil, nil, nil, nil, NO};
    return bsearch(&key, [TriMetInfoColoredLines allLines],
                   [TriMetInfoColoredLines numOfLines],
                   sizeof(TriMetInfo_Route), TriMetInfo_compareRouteLineBit);
}

+ (PtrConstRouteInfo)infoForRouteNum:(NSInteger)route {
    TriMetInfo_Route key = {route, 0, 0, 0, 0, 0, 0, nil, nil, nil, nil, NO};
    return bsearch(&key, [TriMetInfoColoredLines allLines],
                   [TriMetInfoColoredLines numOfLines],
                   sizeof(TriMetInfo_Route), TriMetInfo_compareRouteNumber);
}

+ (PtrConstRouteInfo)infoForRoute:(NSString *)route {
    return [TriMetInfo infoForRouteNum:route.integerValue];
}

+ (NSString *)tinyNameForRoute:(NSString *)route {
    PtrConstRouteInfo info = [TriMetInfo infoForRoute:route];
    if (info) {
        return  info->tiny_name;
    }
    return route;
}

+ (NSSet<NSString *> *)streetcarRoutes {
    static NSMutableSet<NSString *> *routeIds = nil;
    DoOnce(^{
      routeIds = [NSMutableSet set];

      for (PtrConstRouteInfo info = [TriMetInfoColoredLines allLines];
           info->route_number != kNoRoute; info++) {
          if (info->lineType == LineTypeStreetcar) {
              [routeIds addObject:[TriMetInfo routeIdString:info]];
          }
      }
    });

    return routeIds;
}

+ (NSSet<NSString *> *)triMetRailLines {
    static NSMutableSet<NSString *> *routeIds = nil;
    DoOnce(^{
      routeIds = [NSMutableSet set];
      // HERE
      for (PtrConstRouteInfo routeInfo = [TriMetInfoColoredLines allLines];
           routeInfo->route_number != kNoRoute; routeInfo++) {
          if (routeInfo->lineType == LineTypeMAX ||
              routeInfo->lineType == LineTypeWES) {
              [routeIds addObject:[TriMetInfo routeIdString:routeInfo]];
          }
      }
    });

    return routeIds;
}

+ (NSString *)routeIdString:(const TriMetInfo_Route *)info {
    if (info) {
        return [NSString stringWithFormat:@"%ld", (long)info->route_number];
    }
    return nil;
}

+ (NSString *)routeNumberFromInput:(NSString *)input {

    if (input != nil) {
        NSString *routeNumber = [input justNumbers];

        if (routeNumber.length == 0) {
            routeNumber =
                [TriMetInfo routeIdString:[TriMetInfo infoForKeyword:input]];
        }

        return routeNumber;
    }
    return nil;
}

+ (NSString *)interlinedRouteString:(const TriMetInfo_Route *)info {
    return [NSString stringWithFormat:@"%ld", (long)info->interlined_route];
}

+ (bool)isSingleLoopRoute:(NSString *)route {
    return [[TriMetInfoColoredLines allCircularRoutes] containsObject:route];
}

@end
