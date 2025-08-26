//
//  MachineGenerateArrays.m
//  PDX BusTests
//
//  Created by Andrew Wallace on 10/10/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogTests

#define RAILSTATION_SORT

#import "../Classes/AllRailStationViewController.h"
#import "../Classes/RailMapViewController.h"
#import "../Classes/RailStation+Sort.h"
#import "../Classes/XMLRoutes.h"
#import "../PDXBusCore/src/NSString+Core.h"
#import "../PDXBusCore/src/XMLDepartures.h"
#import "CodeWriter.h"
#import <XCTest/XCTest.h>

#include "../Classes/PointInclusionInPolygonTest.h"
#import "../Classes/StationData.h"
#include "../Tables/StaticStationData.c"

#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import <mach-o/ldsyms.h>

@interface MachineGeneratedArrays : XCTestCase

@end

@implementation MachineGeneratedArrays

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each
    // test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of
    // each test method in the class.
}

- (void)addLine:(TriMetInfo_ColoredLines)line
      allRoutes:(XMLRoutes *)allRoutes
          route:(NSString *)routeId
      direction:(NSString *)direction
       stations:(NSArray *)stations
          query:(NSString *)query
      raillines:(TriMetInfo_ColoredLines *)lines {
    NSArray<Stop *> *stops = nil;

    for (Route *route in allRoutes) {
        if ([route.routeId isEqual:routeId]) {
            stops = route.directions[direction].stops;
            break;
        }
    }

    for (Stop *stop in stops) {
        for (RailStation *r in stations) {
            for (NSString *loc in r.stopIdArray) {
                if ([stop.stopId isEqualToString:loc]) {
                    lines[r.index] |= line;
                    break;
                }
            }
        }
    }
}

- (void)checkAlphaStations:(NSArray<RailStation *> *)sortedStations {
    XCTAssertEqual(sortedStations.count,
                   sizeof(stationsAlpha) / sizeof(stationsAlpha[0]));

    for (int i = 0; i < sortedStations.count; i++) {
        RailStation *station = sortedStations[i];
        XCTAssertEqual(station.index, stationsAlpha[i], @"Station: %@",
                       station.name);
    }
}

- (void)checkRouteDirection:(NSArray<RailStation *> *)sortedStations
                      lines:(TriMetInfo_ColoredLines *)lines
                       name:(const TriMetInfo_ColoredLines *)linesToCheck {
    int nHotSpots = HotSpotArrays.sharedInstance.hotSpotCount;

    int i;

    for (i = 0; i < nHotSpots; i++) {
        XCTAssertEqual(linesToCheck[i], lines[i], @"Hotspot: %d", i);
    }
}

- (void)checkRouteColors:(NSArray<RailStation *> *)sortedStations
               allRoutes:(XMLRoutes *)allRoutes {
    NSString *routeNumber = nil;
    TriMetInfo_ColoredLines createRailLines0[MAXHOTSPOTS] = {0};
    TriMetInfo_ColoredLines createRailLines1[MAXHOTSPOTS] = {0};

    for (PtrConstRouteInfo routeInfo = TriMetInfoColoredLines.allLines;
         routeInfo->route_number != kNoRoute; routeInfo++) {
        routeNumber = [TriMetInfo routeIdString:routeInfo];

        [self addLine:routeInfo->line_bit
            allRoutes:allRoutes
                route:routeNumber
            direction:@"0"
             stations:sortedStations
                query:nil
            raillines:createRailLines0];

        if (routeInfo->opposite == kDir1) {
            [self addLine:routeInfo->line_bit
                allRoutes:allRoutes
                    route:routeNumber
                direction:@"1"
                 stations:sortedStations
                    query:nil
                raillines:createRailLines1];
        }
    }

    [self checkRouteDirection:sortedStations
                        lines:createRailLines0
                         name:railLines0];

    [self checkRouteDirection:sortedStations
                        lines:createRailLines1
                         name:railLines1];
}

- (NSString *)sectionForTitle:(NSString *)title {
    NSString *section = [NSString stringWithFormat:@"\"%@\"", title];

    return [section stringByPaddingToLength:6
                                 withString:@" "
                            startingAtIndex:0];
}

- (void)checkSections:(NSArray<RailStation *> *)sortedStations {
    int i;
    RailStation *r = sortedStations[0];
    NSString *title =
        [NSString stringWithFormat:@"%c", [r.name characterAtIndex:0]];
    NSString *next = nil;
    int offset = 0;
    int count = 1;
    int line = 0;

    NSArray *specialCases = @[ @"NW", @"NE", @"SW", @"SE", @"S", @"N" ];
    NSCharacterSet *specialCasesStart =
        [NSCharacterSet characterSetWithCharactersInString:@"NS"];

    for (i = 1; i < sortedStations.count; i++) {
        r = [sortedStations objectAtIndex:i];

        next = nil;

        for (NSString *prefix in specialCases) {
            NSString *prefixSpace = [NSString stringWithFormat:@"%@ ", prefix];

            if ([r.name hasPrefix:prefixSpace]) {
                next = prefix;
            }
        }

        unichar first = [r.name characterAtIndex:0];

        if (next == nil && [specialCasesStart characterIsMember:first]) {
            next = [NSString stringWithFormat:@"%c...", first];
        } else if (next == nil) {
            next = [NSString stringWithFormat:@"%c", first];
        }

        if (![next isEqualToString:title]) {
            const TriMetInfo_AlphaSections *section = &alphaSections[line];

            XCTAssertEqualObjects(section->title, title, @"Section: %d", line);
            XCTAssertEqual(section->offset, offset, @"Section: %d %@", line,
                           section->title);
            XCTAssertEqual(section->items, count, @"Section: %d %@", line,
                           section->title);

            title = next;
            offset = i;
            count = 1;
            line++;
        } else {
            count++;
        }
    }

    const TriMetInfo_AlphaSections *section = &alphaSections[line];
    XCTAssertEqualObjects(alphaSections[line].title, title, @"Section: %d",
                          line);
    XCTAssertEqual(alphaSections[line].offset, offset, @"Section: %d %@", line,
                   section->title);
    XCTAssertEqual(alphaSections[line].items, count, @"Section: %d %@", line,
                   section->title);
}

- (void)checkStopIdTable:(NSArray<RailStation *> *)sortedStations
            allRailStops:(NSDictionary<NSString *, Stop *> *)allRailStops
               allRoutes:(XMLRoutes *)allRoutes {
    int i;
    StopInfo stopInfo2[MAXHOTSPOTS * 3] = {0};

    int stopIndex = 0;

    for (RailStation *rs in sortedStations) {
        for (NSString *loc in rs.stopIdArray) {
            stopInfo2[stopIndex].stopId = loc.intValue;
            stopInfo2[stopIndex].hotspot = rs.index;

            stopInfo2[stopIndex].lat =
                allRailStops[loc].location.coordinate.latitude;
            stopInfo2[stopIndex].lng =
                allRailStops[loc].location.coordinate.longitude;
            stopInfo2[stopIndex].tp = allRailStops[loc].timePoint;
            stopInfo2[stopIndex].lines = [self linesForStop:loc
                                                  allRoutes:allRoutes];

            stopIndex++;
        }
    }

    qsort(stopInfo2, stopIndex, sizeof(stopInfo2[0]), compareStopInfos);

    for (i = 0; i < stopIndex; i++) {
        XCTAssertEqual(stopInfo[i].stopId, stopInfo2[i].stopId);
        XCTAssertEqual(stopInfo[i].hotspot, stopInfo2[i].hotspot,
                       @"Item %d Stop Id: %ld", i, stopInfo[i].stopId);
        XCTAssertEqualWithAccuracy(stopInfo[i].lat, stopInfo2[i].lat,
                                   0.0000000001, @"Item %d Stop Id: %ld", i,
                                   stopInfo[i].stopId);
        XCTAssertEqualWithAccuracy(stopInfo[i].lng, stopInfo2[i].lng,
                                   0.0000000001, @"Item %d Stop Id: %ld", i,
                                   stopInfo[i].stopId);
        DEBUG_ASSERT_WARNING(stopInfo[i].tp == stopInfo2[i].tp,
                             @"Time point different - item %d Stop Id: %ld", i,
                             stopInfo[i].stopId);
        XCTAssertEqual(stopInfo[i].lines, stopInfo2[i].lines,
                       @"Item %d Stop Id: %ld", i, stopInfo[i].stopId);
    }
}

- (TriMetInfo_ColoredLines)linesForStop:(NSString *)stopId
                              allRoutes:(XMLRoutes *)allRoutes {
    __block TriMetInfo_ColoredLines lines = 0;
    for (PtrConstRouteInfo routeInfo = TriMetInfoColoredLines.allLines;
         routeInfo->route_number != kNoRoute; routeInfo++) {
        NSString *routeNumber = [TriMetInfo routeIdString:routeInfo];

        for (Route *route in allRoutes) {
            if ([route.routeId isEqualToString:routeNumber]) {
                [route.directions
                    enumerateKeysAndObjectsUsingBlock:^(
                        NSString *_Nonnull key, Direction *_Nonnull direction,
                        BOOL *_Nonnull stopIteration) {
                      for (Stop *stop in direction.stops) {
                          if ([stop.stopId isEqualToString:stopId]) {
                              lines |= routeInfo->line_bit;
                              *stopIteration = YES;
                              break;
                          }
                      }
                    }];
            }
        }
    }
    return lines;
}

- (void)test_Online_CheckStaticArrays {
    NSArray<RailStation *> *sortedStations = [RailStation sortedStations];
    XMLRoutes *allRoutes = [XMLRoutes xml];
    NSDictionary<NSString *, Stop *> *allRailStops = allRoutes.getAllRailStops;

    [self checkAlphaStations:sortedStations];

    [self checkRouteColors:sortedStations allRoutes:allRoutes];

    [self checkSections:sortedStations];

    [self checkStopIdTable:sortedStations
              allRailStops:allRailStops
                 allRoutes:allRoutes];
}

+ (NSMutableArray *)tileScan:(RailMap *)map {
    int x, y, i;
    CGPoint p;

    PtrConstHotSpot hotSpotRegions = HotSpotArrays.sharedInstance.hotSpots;

    NSMutableArray<NSMutableArray<NSMutableSet<NSNumber *> *> *> *xTiles =
        [NSMutableArray array];

    for (x = 0; x < map->xTiles; x++) {
        NSMutableArray<NSMutableSet<NSNumber *> *> *yTiles =
            [NSMutableArray array];
        [xTiles addObject:yTiles];

        for (y = 0; y < map->yTiles; y++) {
            [yTiles addObject:[[NSMutableSet alloc] init]];
        }
    }

    for (x = 0; x < map->size.width; x++) {
        int xs = x / map->tileSize.width;

        NSMutableArray<NSMutableSet<NSNumber *> *> *yTiles = xTiles[xs];

        for (y = 0; y < map->size.height; y++) {
            int ys = y / map->tileSize.height;

            NSMutableSet<NSNumber *> *set = yTiles[ys];

            p.x = x;
            p.y = y;

            for (i = map->hotSpots->first; i <= map->hotSpots->last; i++) {
                if (HOTSPOT_HIT((hotSpotRegions + i), p)) {
                    [set addObject:@(i)];
                }
            }
        }
    }

    return xTiles;
}

+ (bool)checkTile:(PtrConstRailMap)map {
    int x, y;
    CGPoint p;
    bool ok = YES;

    PtrConstHotSpot hotSpotRegions = HotSpotArrays.sharedInstance.hotSpots;

    // Make a big fake tile
    RailMapTile allHotSpots;

    HotSpotIndex *hotspots =
        malloc(sizeof(HotSpotIndex) *
               (map->hotSpots->last - map->hotSpots->first + 2));

    allHotSpots.hotspots = hotspots;

    HotSpotIndex *ptr = hotspots;
    int j = 0;

    for (int i = map->hotSpots->first; i <= map->hotSpots->last; i++) {
        *ptr = j;
        ptr++;
        j++;
    }

    *ptr = MAP_END;

    for (x = 0; x < map->size.width; x++) {
        for (y = 0; y < map->size.height; y++) {
            int tx = x / map->tileSize.width;
            int ty = y / map->tileSize.height;

            const RailMapTile *tile = &map->tiles[tx][ty];

            p.x = x;
            p.y = y;

            int hs1 = [RailMapViewController findHotSpotInMap:map
                                                         tile:tile
                                                        point:p];
            int hs2 = [RailMapViewController findHotSpotInMap:map
                                                         tile:&allHotSpots
                                                        point:p];

            if (hs1 != hs2) {
                if (hs1 != NO_HOTSPOT_FOUND) {
                    DEBUG_LOG_NSString(HS_ACTION(hotSpotRegions[hs1]));
                }

                if (hs2 != NO_HOTSPOT_FOUND) {
                    DEBUG_LOG_NSString(HS_ACTION(hotSpotRegions[hs2]));
                }

                ok = NO;
            }
        }
    }

    free(hotspots);

    return ok;
}

- (void)test_check_HotSpot_MaxTiles {
    XCTAssert([MachineGeneratedArrays
        checkTile:[RailMapViewController railMap:kRailMapMaxWes]]);
}

- (void)test_check_HotSpot_StreetcarTiles {
    XCTAssert([MachineGeneratedArrays
        checkTile:[RailMapViewController railMap:kRailMapPdxStreetcar]]);
}

@end
