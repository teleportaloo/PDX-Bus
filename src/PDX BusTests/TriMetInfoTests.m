//
//  TriMetInfoTests.m
//  PDX BusTests
//
//  Created by Andrew Wallace on 9/25/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogTests

#import "../Classes/XMLRoutes.h"
#import "../PDXBusCore/src/TriMetInfo.h"
#import "LinkChecker.h"
#import "NSString+MoreMarkup.h"
#import <XCTest/XCTest.h>

@interface TriMetInfoTests : XCTestCase

@end

@implementation TriMetInfoTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each
    // test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of
    // each test method in the class.
}

+ (bool)tableIsSorted:(const void *)base
                  nel:(size_t)nel
                width:(size_t)width
              compare:(int (*_Nonnull)(const void *, const void *))compare
                table:(NSString *)table {
    const void *p = base;
    const void *c = base + width;
    bool error = NO;

    for (int i = 1; i < nel; i++) {

        XCTAssert((*compare)(p, c) < 0, @"Table: %@ at %d", table, i);

        if ((*compare)(p, c) >= 0) {

            ERROR_LOG(@"%d is less than previous", (int)i);
            error = YES;
        }

        p += width;
        c += width;
    }

    return !error;
}

- (void)test_VEHICLE_INFO_sorted {
    // Build

    // Operate
    bool tableSorted =
        [TriMetInfoTests tableIsSorted:(void *)TriMetInfo_getVehicle()
                                   nel:TriMetInfo_noOfVehicles()
                                 width:sizeof(TriMetInfo_Vehicle)
                               compare:TriMetInfo_compareVehicle
                                 table:@"Vehicle"];

    // Assert
    XCTAssert(tableSorted);
}

- (void)test_TriMetInfo_VehicleSpecial_sorted {
    // Build

    // Operate
    bool tableSorted =
        [TriMetInfoTests tableIsSorted:(void *)TriMetInfo_getVehicleSpecial()
                                   nel:TriMetInfo_noOfVehicleSpecials()
                                 width:sizeof(TriMetInfo_VehicleSpecial)
                               compare:TriMetInfo_compareVehicleSpecial
                                 table:@"VehicleSpecial"];

    // Assert
    XCTAssert(tableSorted);
}

- (void)test_VEHICLE_INFO_links {
    // Build
    LinkChecker *linkChecker = [LinkChecker withContext:NSSTR_FUNC];

    // Operate
    TriMetInfo_VehicleConstPtr vehicles = TriMetInfo_getVehicle();

    for (TriMetInfo_VehicleConstPtr vehicle = vehicles; vehicle->type != nil;
         vehicle++) {

        [linkChecker
            checkLinksInAttributedString:vehicle->markedUpModel
                                             .attributedStringFromMarkUp];
    }

    [linkChecker waitUntilDone];
}

- (void)test_TriMetInfo_VehicleSpecial_links {
    // Build
    LinkChecker *linkChecker = [LinkChecker withContext:NSSTR_FUNC];

    // Operate
    TriMetInfo_VehicleSpecialConstPtr specials = TriMetInfo_getVehicleSpecial();

    for (TriMetInfo_VehicleSpecialConstPtr special = specials;
         special->markedUpSpecialInfo != nil; special++) {
        [linkChecker
            checkLinksInAttributedString:special->markedUpSpecialInfo
                                             .attributedStringFromMarkUp];
    }

    [linkChecker waitUntilDone];
}

- (void)test_VEHICLE_INFO_get {
    // Build

    // Operate
    TriMetInfo_VehicleConstPtr vehicles = TriMetInfo_getVehicle();

    NSInteger count = 0;
    NSInteger records = 0;

    // Assert
    for (TriMetInfo_VehicleConstPtr vehicle = vehicles; vehicle->type != nil;
         vehicle++) {
        NSInteger min = vehicle->vehicleIdMin;
        NSInteger max = vehicle->vehicleIdMax;
        NSInteger mid = (vehicle->vehicleIdMin + vehicle->vehicleIdMax) / 2;

        count += (vehicle->vehicleIdMax - vehicle->vehicleIdMin) + 1;
        records++;

        XCTAssertEqual([TriMetInfo vehicleInfo:min], vehicle, @"Vehicle %ld",
                       min);
        XCTAssertEqual([TriMetInfo vehicleInfo:max], vehicle, @"Vehicle %ld",
                       max);
        XCTAssertEqual([TriMetInfo vehicleInfo:mid], vehicle, @"Vehicle %ld",
                       mid);
    }

    DEBUG_LOG(@"Count %ld in %ld records", (long)count, (long)records);
}

- (void)test_RouteInfo_get {
    // Build

    // Operate
    PtrConstRouteInfo routes = TriMetInfoColoredLines.allLines;

    // Assert
    for (PtrConstRouteInfo route = routes; route->full_name != nil; route++) {
        XCTAssertEqual([TriMetInfo infoForRouteNum:route->route_number], route,
                       @"Route %ld", route->route_number);
        XCTAssertEqual([TriMetInfo infoForLine:route->line_bit], route,
                       @"Line %ld", (long)route->line_bit);
    }
}

- (void)test_RouteInfo_links {
    // Build
    LinkChecker *linkChecker = [LinkChecker withContext:NSSTR_FUNC];

    // Operate
    PtrConstRouteInfo routes = TriMetInfoColoredLines.allLines;

    // Assert
    for (PtrConstRouteInfo route = routes; route->full_name != nil; route++) {
        [linkChecker checkWikiLink:route->wiki];
    }

    [linkChecker waitUntilDone];
}

- (void)test_RouteInfo_sortedByRoute {
    // Build

    // Operate
    bool tableSorted =
        [TriMetInfoTests tableIsSorted:TriMetInfoColoredLines.allLines
                                   nel:TriMetInfoColoredLines.numOfLines
                                 width:sizeof(TriMetInfo_Route)
                               compare:TriMetInfo_compareRouteNumber
                                 table:@"Route Info by route number"];

    // Assert
    XCTAssert(tableSorted);
}

- (void)test_RouteInfo_sortedByLine {
    // Build

    // Operate
    bool tableSorted =
        [TriMetInfoTests tableIsSorted:TriMetInfoColoredLines.allLines
                                   nel:TriMetInfoColoredLines.numOfLines
                                 width:sizeof(TriMetInfo_Route)
                               compare:TriMetInfo_compareRouteLineBit
                                 table:@"Route info by line"];

    // Assert
    XCTAssert(tableSorted);
}

- (void)test_Online_RouteInfo_matches {
    XMLRoutes *sut = [XMLRoutes xml];
    PtrConstRouteInfo info = nil;

    // Operate
    [sut getRoutesCacheAction:TriMetXMLNoCaching];

    // Assert

    for (Route *route in sut) {
        info = [TriMetInfo infoForRoute:route.routeId];

        if (route.routeColor != 0x084C8D && route.routeColor != 0) {
            XCTAssert(info != nil, @"Route: %@", route.desc);
            if (info != nil) {
                // XCTAssert(info->html_color == route.routeColor, @"Route: %@",
                // route.desc);
                DEBUG_ASSERT_WARNING(
                    info->html_color == route.routeColor,
                    @"Route %@,%@ has a different color 0x%06lx 0x%06lx",
                    route.routeId, route.desc, (long)info->html_color,
                    (long)route.routeColor);
                XCTAssertEqualObjects(info->full_name, route.desc);

                XCTAssertEqual(route.routeSortOrder, info->sort_order,
                               @"sort order for %d should be %d",
                               (int)info->route_number,
                               (int)route.routeSortOrder);
            }
        }
    }

    for (info = TriMetInfoColoredLines.allLines; info->short_name != nil;
         info++) {
        bool found = NO;

        for (Route *route in sut) {
            if (route.routeId.integerValue == info->route_number) {
                found = YES;
                break;
            }
        }

        if (info->optional) {
            if (!found) {
                DEBUG_TEST_WARNING(@"Route not found: %@", info->full_name);
            } else {
                DEBUG_LOG(@"Optional route found: %@", info->full_name);
            }
        } else {
            XCTAssert(found, @"Route: %@", info->full_name);
        }
    }
}

- (void)test_Online_RouteInfo_directions {
    XMLRoutes *sut = [XMLRoutes xml];
    PtrConstRouteInfo info = nil;
    PtrConstRouteInfo info_opposite = nil;

    // Operate
    [sut getAllDirectionsCacheAction:TriMetXMLNoCaching];

    // Assert

    for (Route *route in sut) {
        info = [TriMetInfo infoForRoute:route.routeId];

        if (info) {
            if (info->opposite != kDir1) {
                info_opposite = [TriMetInfo infoForRouteNum:info->opposite];

                XCTAssertEqual(info->route_number, info_opposite->opposite);
            }
        }

        if (route.directions.count == 1) {
            if (info != nil) {
                XCTAssert(info->opposite != 0);
            } else if (![TriMetInfo isSingleLoopRoute:route.routeId]) {
                DEBUG_TEST_WARNING(@"Route %@, %@ has one direction",
                                   route.routeId, route.desc);
            }
        }
    }
}

@end
