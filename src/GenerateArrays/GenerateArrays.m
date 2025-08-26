//
//  GenerateArrays.m
//  GenerateArrays
//
//  Created by Andy Wallace on 3/13/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define RAILSTATION_SORT

#import "GenerateArrays.h"
#import "../Classes/HotSpot.h"
#import "../Classes/PointInclusionInPolygonTest.h"
#import "../Classes/RailStation+Sort.h"
#import "../Classes/StationData.h"
#import "../Classes/XMLRoutes.h"
#import "../PDXBusCore/src/NSString+Core.h"
#import "../PDXBusCore/src/TriMetInfo.h"
#import "../PDXBusCore/src/TriMetInfoColoredLines.h"
#import "../PDXBusCore/src/XMLDepartures.h"
#import "CodeWriter.h"

static NSString *closeBrace = @"};\n";

#define MAX_RAIL_MAPS (3)
static RailMapHotSpots generatedRailMapHotSpots[MAX_RAIL_MAPS];
static RailMap generatedRailMaps[MAX_RAIL_MAPS];

@implementation GenerateArrays

- (void)generateRouteDirection:(NSArray<RailStation *> *)sortedStations
                         lines:(TriMetInfo_ColoredLines *)lines
                          name:(NSString *)name {
    int nHotSpots = HotSpotArrays.sharedInstance.hotSpotCount;
    NSMutableString *codeText = [NSMutableString string];

    [codeText
        appendFormat:@"\nstatic const TriMetInfo_ColoredLines %@[]={\n", name];
    int i;

    for (i = 0; i < nHotSpots; i++) {
        [codeText appendFormat:@"    0x%04x,    ", lines[i]];

        for (RailStation *r in sortedStations) {
            if (r.index == i) {
                [codeText appendFormat:@"/* %@ */", r.name];
                break;
            }
        }

        [codeText appendFormat:@"\n"];
    }

    [codeText appendString:@"};\n"];

    CODE_STRING(codeText);
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

- (void)generateRouteColors:(NSArray<RailStation *> *)sortedStations
                  allRoutes:(XMLRoutes *)allRoutes {
    NSString *routeNumber = nil;
    TriMetInfo_ColoredLines createRailLines0[MAXHOTSPOTS] = {0};
    TriMetInfo_ColoredLines createRailLines1[MAXHOTSPOTS] = {0};

    CODE_COMMENT((@[
        @"//",
        @"// These are the colors for the lines of each rail station in the hotspot array.",
        @"// It is calculated by gettng the stops for each station and merging them in.",
        @"// Much easier than doing it by hand!", @"//",
        @"// There is one array for each direction"
    ]));

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

    [self generateRouteDirection:sortedStations
                           lines:createRailLines0
                            name:@"railLines0"];

    [self generateRouteDirection:sortedStations
                           lines:createRailLines1
                            name:@"railLines1"];
}

- (NSString *)sectionForTitle:(NSString *)title {
    NSString *section = [NSString stringWithFormat:@"@\"%@\"", title];

    return [section stringByPaddingToLength:7
                                 withString:@" "
                            startingAtIndex:0];
}

- (void)generateSections:(NSArray<RailStation *> *)sortedStations {
    NSMutableString *codeText = [NSMutableString string];
    int i;

    CODE_COMMENT((@[
        @"//",
        @"// These are the sections for the rail view screen, only displayed when no",
        @"// searching is happening", @"//", @""
    ]));

    [codeText
        appendFormat:
            @"\nstatic const TriMetInfo_AlphaSections alphaSections[]={\n"];
    [codeText appendFormat:@"//  Section   Offset Count\n"];

    RailStation *r = sortedStations[0];
    NSString *title =
        [NSString stringWithFormat:@"%c", [r.name characterAtIndex:0]];
    NSString *next = nil;
    int offset = 0;
    int count = 1;

    NSArray *specialCases = @[ @"NW", @"NE", @"SW", @"SE", @"NE", @"S", @"N" ];
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
            [codeText appendFormat:@"    { %@, %5d, %5d},\n",
                                   [self sectionForTitle:title], offset, count];
            title = next;
            offset = i;
            count = 1;
        } else {
            count++;
        }
    }

    [codeText appendFormat:@"    { %@, %5d, %5d},\n",
                           [self sectionForTitle:title], offset, count];

    [codeText appendString:closeBrace];

    CODE_STRING(codeText);
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

- (void)generateStopIdTable:(NSArray<RailStation *> *)sortedStations
               allRailStops:(NSDictionary<NSString *, Stop *> *)allRailStops
                  allRoutes:(XMLRoutes *)allRoutes {
    NSMutableString *codeText = [NSMutableString string];
    int i;
    StopInfo stopInfo2[MAXHOTSPOTS * 3] = {0};

    CODE_COMMENT((@[
        @"//",
        @"// This table allows a quick lookup of a hot spot and location from a stop ID.",
        @"// Only the IDs of rail stations are in here.", @"//"
    ]));

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

    [codeText appendString:@"\nstatic const StopInfo stopInfo[]={\n"];
    [codeText appendString:@"//   Stop ID  Index Latitude                 "
                           @"Longitude                  TP Lines\n"];
    for (i = 0; i < stopIndex; i++) {
        [codeText
            appendFormat:@"    { %5d, %5d, %10.20f, %10.20f, %d, 0x%04x},\n",
                         (int)stopInfo2[i].stopId, (int)stopInfo2[i].hotspot,
                         stopInfo2[i].lat, stopInfo2[i].lng, stopInfo2[i].tp,
                         stopInfo2[i].lines];
    }

    [codeText appendString:closeBrace];

    CODE_STRING(codeText);
}

- (void)generateStaticStationData {
    NSArray<RailStation *> *sortedStations = [RailStation sortedStations];

    CODE_FILE(@"StaticStationData.c");
    
    CODE_LICENSE;

    CODE_STRING(@"#ifndef ONLY_RAILMAP_DATA\n");

    CODE_COMMENT((@[
        @"// Machine Generated File, generated using the GenerateArrays app."
    ]));

    [self generateAlphaStations:sortedStations];

    XMLRoutes *allRoutes = [XMLRoutes xml];
    NSDictionary<NSString *, Stop *> *allRailStops = allRoutes.getAllRailStops;

    [self generateRouteColors:sortedStations allRoutes:allRoutes];

    [self generateSections:sortedStations];

    [self generateStopIdTable:sortedStations
                 allRailStops:allRailStops
                    allRoutes:allRoutes];

    [self generateLinesInOrder];

    CODE_STRING(@"#else\n");

    [self generationRailMapData];

    CODE_STRING(@"#endif\n");

    CODE_LOG_FILE_END;
}

- (void)generateLinesInOrder {
    NSMutableArray<NSNumber *> *sortedLines = NSMutableArray.array;

    PtrConstRouteInfo lines = TriMetInfoColoredLines.allLines;
    size_t noOfLines = TriMetInfoColoredLines.numOfLines;

    for (NSInteger i = 0; i < noOfLines; i++) {
        [sortedLines addObject:@(i)];
    }

    [sortedLines sortUsingComparator:^NSComparisonResult(
                     NSNumber *_Nonnull obj1, NSNumber *_Nonnull obj2) {
      PtrConstRouteInfo i1 = lines + obj1.integerValue;
      PtrConstRouteInfo i2 = lines + obj2.integerValue;

      return TriMetInfo_compareSortOrder(i1, i2);
    }];

    CODE_COMMENT((@[
        @"//", @"// These are the TriMet Colored Lines in the sort order", @"//"
    ]));

    NSMutableString *codeText = [NSMutableString string];

    [codeText appendString:@"\nstatic const int sortedColoredLines[]={\n"];

    for (int i = 0; i < noOfLines; i++) {
        [codeText
            appendFormat:@"    %ld,\n", (long)sortedLines[i].integerValue];
    }

    [codeText appendString:closeBrace];

    CODE_STRING(codeText);
}

- (void)generationRailMapData {

    int nHotSpots = HotSpotArrays.sharedInstance.hotSpotCount;
    PtrConstHotSpot hotSpotRegions = HotSpotArrays.sharedInstance.hotSpots;

    PtrConstRailMap railMaps = HotSpotArrays.sharedInstance.railMaps;

    int nRailMaps = 0;

    for (nRailMaps = 0; railMaps[nRailMaps].title != nil; nRailMaps++) {
        generatedRailMaps[nRailMaps] = railMaps[nRailMaps];
    }

    int railMap = 0;

    generatedRailMapHotSpots[railMap].first = 0;

    int i = 0;
    int map = 0;
    for (i = 0; i < nHotSpots; i++) {
        if (hotSpotRegions[i].nMap != map) {
            generatedRailMapHotSpots[railMap].last = i - 1;
            map = hotSpotRegions[i].nMap;
            railMap++;

            ASSERT(railMap < nRailMaps);

            generatedRailMapHotSpots[railMap].first = i;
        }
    }

    generatedRailMapHotSpots[railMap].last = nHotSpots - 1;

    CODE_COMMENT(
        (@[ @"//", @"// These are the hot spots for each map", @"//" ]));

    NSMutableString *codeText = [NSMutableString string];

    [codeText
        appendString:@"\nstatic const RailMapHotSpots railMapHotSpots[]={\n"];

    for (int i = 0; i < nRailMaps; i++) {

        [codeText appendFormat:@"    { %ld, %ld },\n",
                               (long)generatedRailMapHotSpots[i].first,
                               (long)generatedRailMapHotSpots[i].last];

        generatedRailMaps[i].hotSpots = &generatedRailMapHotSpots[i];
    }
    [codeText appendString:@"    { -1, -1 }\n"];

    [codeText appendString:closeBrace];

    CODE_STRING(codeText);
}

- (void)generateAlphaStations:(NSArray<RailStation *> *)sortedStations {
    int i;
    NSMutableString *codeText = [NSMutableString string];

    CODE_COMMENT((@[
        @"//",
        @"// This is an index into the hotspot arrays of the stations in alphabetical",
        @"// order, this is calculated by the software so the developer does not have to!",
        @"//"
    ]));

    [codeText appendString:@"\nstatic int const stationsAlpha[]={\n"];

    for (i = 0; i < sortedStations.count; i++) {
        [codeText appendFormat:@"    %3d,     /* %@ */\n",
                               sortedStations[i].index, sortedStations[i].name];
    }

    [codeText appendString:closeBrace];

    CODE_STRING(codeText);
}

+ (NSMutableArray *)tileScan:(PtrConstRailMap)map {
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

+ (void)dumpTiles:(NSArray<NSArray<NSSet<NSNumber *> *> *> *)tiles
              map:(PtrConstRailMap)map
           output:(NSMutableString *)output {
    [output appendFormat:@"\n/* tiles for %@ (total hotspots: %d) */\n",
                         map->title,
                         map->hotSpots->last - map->hotSpots->first + 1];
    int total = 0;
    NSInteger max = 0;

    [output
        appendFormat:@"/* -- */ MAP_TILE_STATIC_ARRAY(%d)\n", (int)tiles.count];

    int x, y;

    for (x = 0; x < tiles.count; x++) {
        NSArray<NSSet<NSNumber *> *> *ya = tiles[x];
        // DEBUG_LOG(@"Stripe size %lu\n", (unsigned long)stripeSet.count);

        [output appendFormat:@"/* -- */ MAP_TILE_STATIC_ROW(%d,%d)\n", x,
                             (int)ya.count];

        for (y = 0; y < ya.count; y++) {
            NSSet<NSNumber *> *set = ya[y];

            // NSArray *orderedTiles = [set sortedArrayUsingDescriptors:(nonnull
            // NSArray<NSSortDescriptor *> *)
            NSMutableArray<NSNumber *> *items = [NSMutableArray array];

            [set enumerateObjectsUsingBlock:^(NSNumber *_Nonnull obj,
                                              BOOL *_Nonnull stop) {
              [items addObject:obj];
            }];

            if (items.count > 0) {
                [items sortUsingSelector:@selector(compare:)];

                [output appendFormat:@"/* %02d */ MAP_TILES( %2d, %2d, (",
                                     (int)set.count, x, y];
                total += set.count;

                if (set.count > max) {
                    max = set.count;
                }

                bool first = true;
                for (NSNumber *n in items) {
                    if (!first) {
                        [output appendString:@","];
                    }
                    first = false;
                    [output
                        appendFormat:@"%d", n.intValue - map->hotSpots->first];
                }

                [output appendFormat:@") )\n"];
            } else {
                [output appendFormat:@"/* %02d */ MAP_NONE(  %2d, %2d )\n",
                                     (int)set.count, x, y];
            }
        }

        [output appendFormat:@"/* -- */ MAP_TILE_STATIC_END_ROW\n"];
    }

    [output appendFormat:@"/* -- */ MAP_TILE_STATIC_END_ARRAY\n"];

    [output appendFormat:@"/* Total %d */\n", total];
    [output appendFormat:@"/* Max per tile %ld */\n", (NSInteger)max];
}

+ (void)makeTiles:(PtrConstRailMap)map {
    NSMutableString *output = [NSMutableString string];
    NSArray<NSArray<NSSet<NSNumber *> *> *> *tiles =
        [GenerateArrays tileScan:map];

    [GenerateArrays dumpTiles:tiles map:map output:output];

    CODE_STRING(output);
}

- (void)generateHotSpotTiles {
    CODE_FILE(@"MaxHotSpotTiles.c");
    
    CODE_LICENSE;

    CODE_COMMENT((@[
        @"// Machine Generated File, generated using the GenerateArrays app.",
        @"// This table divides a map into smaller rectangles, and lists which",
        @"// hotspots are in each rectable. This shortens the search time",
        @"// when a user touches a map."
    ]));

    [GenerateArrays makeTiles:&generatedRailMaps[kRailMapMaxWes]];
    CODE_RULE;
    CODE_LOG_FILE_END;

    CODE_FILE(@"StreetcarHotSpotTiles.c");
    
    CODE_LICENSE;

    CODE_COMMENT((@[
        @"// Machine Generated File, generated using the GenerateArrays app.",
        @"// This table divides a map into smaller rectangles, and lists which",
        @"// hotspots are in each rectable. This shortens the search time",
        @"// when a user touches a map."
    ]));

    [GenerateArrays makeTiles:&generatedRailMaps[kRailMapPdxStreetcar]];
    CODE_RULE;
    CODE_LOG_FILE_END;
}

- (void)generateCopySh {
    CODE_FILE(@"copy.sh");

    NSString *path = @__FILE__;

    path = path.stringByDeletingLastPathComponent;
    path = path.stringByDeletingLastPathComponent;

    CODE_LOG(@"cp MaxHotSpotTiles.c %@/Tables/.", path);
    CODE_LOG(@"cp StreetcarHotSpotTiles.c %@/Tables/.", path);
    CODE_LOG(@"cp StaticStationData.c %@/Tables/.", path);
    CODE_LOG_FILE_END;
}

@end
