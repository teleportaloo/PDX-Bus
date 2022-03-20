//
//  GenerateArrays.m
//  PDX BusTests
//
//  Created by Andrew Wallace on 10/10/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//

#define DEBUG_LEVEL_FOR_FILE kLogTests

#import <XCTest/XCTest.h>
#import "../Classes/RailMapView.h"
#import "../Classes/RailStation.h"
#import "../PDXBusCore/src/NSString+Helper.h"
#import "../PDXBusCore/src/XMLDepartures.h"
#import "../Classes/CodeWriter.h"
#import "../Classes/AllRailStationView.h"
#import "../Classes/XMLRoutes.h"

#include "../Classes/StaticStationData.m"
#include "../Classes/PointInclusionInPolygonTest.h"

@interface MachineGeneratedArrays : XCTestCase

@end

@implementation MachineGeneratedArrays

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)addLine:(RailLines)line allRoutes:(XMLRoutes *)allRoutes route:(NSString *)routeId direction:(NSString *)direction stations:(NSArray *)stations query:(NSString *)query raillines:(RailLines *)lines {
    NSArray <Stop *> *stops = nil;
    
    for (Route *route in allRoutes) {
        if ([route.route isEqual:routeId]) {
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

- (NSArray<RailStation *> *)sortStations {
    NSMutableArray<RailStation *> *stations = [NSMutableArray array];
    int i;
    int nHotSpots = [RailMapView nHotspotRecords];
    HotSpot *hotSpotRegions = [RailMapView hotspotRecords];
    
    for (i = 0; i < nHotSpots; i++) {
        if (hotSpotRegions[i].action.firstUnichar == kLinkTypeStop) {
            [stations addObject:[RailStation fromHotSpot:hotSpotRegions + i index:i]];
        }
    }
    
    [stations sortUsingSelector:@selector(compareUsingStation:)];
    
    return stations;
}

- (void)checkAlphaStations:(NSArray<RailStation *> *)sortedStations {
    XCTAssertEqual(sortedStations.count, sizeof(stationsAlpha) / sizeof(stationsAlpha[0]));
    
    for (int i = 0; i < sortedStations.count; i++) {
        RailStation *station = sortedStations[i];
        XCTAssertEqual(station.index, stationsAlpha[i], @"Station: %@", station.station);
    }
}

- (void)generateAlphaStations:(NSArray<RailStation *> *)sortedStations {
    int i;
    NSMutableString *codeText = [NSMutableString string];
    
    CODE_COMMENT((@[
        @"//",
        @"// This is an index into the hotspot arrays of the stations in alphabetical",
        @"// order, this is calculated by the software so the developer does not have to!",
        @"//"]));
    
    
    [codeText appendString:@"\nint const stationsAlpha[]={\n"];
    
    for (i = 0; i < sortedStations.count; i++) {
        [codeText appendFormat:@"    %3d,     /* %@ */\n", sortedStations[i].index, sortedStations[i].station];
    }
    
    [codeText appendString:@"};\n"];
    
    CODE_STRING(codeText);
}

- (void)checkRouteDirection:(NSArray<RailStation *> *)sortedStations lines:(RailLines *)lines name:(const RailLines *)linesToCheck {
    int nHotSpots = [RailMapView nHotspotRecords];
    
    int i;
    
    for (i = 0; i < nHotSpots; i++) {
        XCTAssertEqual(linesToCheck[i], lines[i], @"Hotspot: %d", i);
    }
}

- (void)generateRouteDirection:(NSArray<RailStation *> *)sortedStations lines:(RailLines *)lines name:(NSString *)name {
    int nHotSpots = [RailMapView nHotspotRecords];
    NSMutableString *codeText = [NSMutableString string];
    
    [codeText appendFormat:@"\nstatic const RailLines %@[]={\n", name];
    int i;
    
    for (i = 0; i < nHotSpots; i++) {
        [codeText appendFormat:@"    0x%04x,    ", lines[i]];
        
        for (RailStation *r in sortedStations) {
            if (r.index == i) {
                [codeText appendFormat:@"/* %@ */", r.station];
                break;
            }
        }
        
        [codeText appendFormat:@"\n"];
    }
    
    [codeText appendString:@"};\n"];
    
    CODE_STRING(codeText);
}

- (void)checkRouteColors:(NSArray<RailStation *> *)sortedStations allRoutes:(XMLRoutes *)allRoutes {
    NSString *routeNumber = nil;
    RailLines createRailLines0[MAXHOTSPOTS] = { 0 };
    RailLines createRailLines1[MAXHOTSPOTS] = { 0 };
    
    for (PtrConstRouteInfo routeInfo = [TriMetInfo allColoredLines]; routeInfo->route_number != kNoRoute; routeInfo++) {
        routeNumber = [TriMetInfo routeString:routeInfo];
        
        [self addLine:routeInfo->line_bit allRoutes:allRoutes route:routeNumber direction:@"0" stations:sortedStations query:nil raillines:createRailLines0];
        
        if (routeInfo->opposite == kDir1) {
            [self addLine:routeInfo->line_bit allRoutes:allRoutes route:routeNumber direction:@"1" stations:sortedStations query:nil raillines:createRailLines1];
        }
    }
    
    [self checkRouteDirection:sortedStations lines:createRailLines0 name:railLines0];
    
    [self checkRouteDirection:sortedStations lines:createRailLines1 name:railLines1];
}

- (void)generateRouteColors:(NSArray<RailStation *> *)sortedStations allRoutes:(XMLRoutes *)allRoutes {
    NSString *routeNumber = nil;
    RailLines createRailLines0[MAXHOTSPOTS] = { 0 };
    RailLines createRailLines1[MAXHOTSPOTS] = { 0 };
    
    CODE_COMMENT((@[
        @"//",
        @"// These are the colors for the lines of each rail station in the hotspot array.",
        @"// It is calculated by gettng the stops for each station and merging them in.",
        @"// Much easier than doing it by hand!",
        @"//",
        @"// There is one array for each direction"]));
    
    for (PtrConstRouteInfo routeInfo = [TriMetInfo allColoredLines]; routeInfo->route_number != kNoRoute; routeInfo++) {
        routeNumber = [TriMetInfo routeString:routeInfo];
        
        [self addLine:routeInfo->line_bit allRoutes:allRoutes route:routeNumber direction:@"0" stations:sortedStations query:nil raillines:createRailLines0];
        
        if (routeInfo->opposite == kDir1) {
            [self addLine:routeInfo->line_bit allRoutes:allRoutes route:routeNumber direction:@"1" stations:sortedStations query:nil raillines:createRailLines1];
        }
    }
    
    [self generateRouteDirection:sortedStations lines:createRailLines0 name:@"railLines0"];
    
    [self generateRouteDirection:sortedStations lines:createRailLines1 name:@"railLines1"];
}

- (NSString *)sectionForTitle:(NSString *)title {
    NSString *section = [NSString stringWithFormat:@"\"%@\"", title];
    
    return [section stringByPaddingToLength:6 withString:@" " startingAtIndex:0];
}

- (void)checkSections:(NSArray<RailStation *> *)sortedStations {
    int i;
    RailStation *r = sortedStations[0];
    NSString *title = [NSString stringWithFormat:@"%c", [r.station characterAtIndex:0]];
    NSString *next = nil;
    int offset = 0;
    int count = 1;
    int line = 0;
    
    NSArray *specialCases = @[@"NW", @"NE", @"SW", @"SE", @"S", @"N"];
    NSCharacterSet* specialCasesStart = [NSCharacterSet characterSetWithCharactersInString:@"NS"];
    
    for (i = 1; i < sortedStations.count; i++) {
        r = [sortedStations objectAtIndex:i];
        
        next = nil;
        
        for (NSString *prefix in specialCases) {
            NSString *prefixSpace = [NSString stringWithFormat:@"%@ ", prefix];
            
            if ([r.station hasPrefix:prefixSpace]) {
                next = prefix;
            }
        }
        
        unichar first = [r.station characterAtIndex:0];
        
        if (next == nil && [specialCasesStart characterIsMember:first]) {
            next = [NSString stringWithFormat:@"%c...", first];
        } else  if (next == nil) {
            next = [NSString stringWithFormat:@"%c", first];
        }
        
        if (![next isEqualToString:title]) {
            const AlphaSections *section = &alphaSections[line];
            
            XCTAssertEqualObjects([NSString stringWithUTF8String:section->title], title, @"Section: %d", line);
            XCTAssertEqual(section->offset, offset, @"Section: %d %s", line, section->title);
            XCTAssertEqual(section->items, count, @"Section: %d %s", line, section->title);
            
            title = next;
            offset = i;
            count = 1;
            line++;
        } else {
            count++;
        }
    }
    
    const AlphaSections *section = &alphaSections[line];
    XCTAssertEqualObjects([NSString stringWithUTF8String:alphaSections[line].title], title, @"Section: %d", line);
    XCTAssertEqual(alphaSections[line].offset, offset, @"Section: %d %s", line, section->title);
    XCTAssertEqual(alphaSections[line].items, count, @"Section: %d %s", line, section->title);
}

- (void)generateSections:(NSArray<RailStation *> *)sortedStations {
    NSMutableString *codeText = [NSMutableString string];
    int i;
    
    CODE_COMMENT((@[
        @"//",
        @"// These are the sections for the rail view screen, only displayed when no",
        @"// searching is happening",
        @"//",
        @"",
        @"#define ALPHA_SECTIONS_CNT (sizeof(alphaSections)/sizeof(alphaSections[0]))"
                  ]));
    
    [codeText appendFormat:@"\nstatic const AlphaSections alphaSections[]={\n"];
    [codeText appendFormat:@"//  Section   Offset Count\n"];
    
    RailStation *r = sortedStations[0];
    NSString *title = [NSString stringWithFormat:@"%c", [r.station characterAtIndex:0]];
    NSString *next = nil;
    int offset = 0;
    int count = 1;
    
    NSArray *specialCases = @[@"NW", @"NE", @"SW", @"SE", @"NE", @"S", @"N"];
    NSCharacterSet* specialCasesStart = [NSCharacterSet characterSetWithCharactersInString:@"NS"];
    
    for (i = 1; i < sortedStations.count; i++) {
        r = [sortedStations objectAtIndex:i];
        
        next = nil;
        
        for (NSString *prefix in specialCases) {
            NSString *prefixSpace = [NSString stringWithFormat:@"%@ ", prefix];
            
            if ([r.station hasPrefix:prefixSpace]) {
                next = prefix;
            }
        }
        
        unichar first = [r.station characterAtIndex:0];
        
        if (next == nil && [specialCasesStart characterIsMember:first]) {
            next = [NSString stringWithFormat:@"%c...", first];
        } else if (next == nil) {
            next = [NSString stringWithFormat:@"%c", first];
        }

        if (![next isEqualToString:title]) {
            [codeText appendFormat:@"    { %@, %5d, %5d},\n", [self sectionForTitle:title], offset, count];
            title = next;
            offset = i;
            count = 1;
        } else {
            count++;
        }
    }
    
    [codeText appendFormat:@"    { %@, %5d, %5d},\n", [self sectionForTitle:title], offset, count];
    
    [codeText appendFormat:@"};\n"];
    
    CODE_STRING(codeText);
}

- (void)checkStopIdTable:(NSArray<RailStation *> *)sortedStations allRailStops:(NSDictionary<NSString *, Stop *> *)allRailStops allRoutes:(XMLRoutes *)allRoutes {
    int i;
    StopInfo stopInfo2[MAXHOTSPOTS * 3] = { 0 };
    
    int stopIndex = 0;
    
    for (RailStation *rs in sortedStations) {
        for (NSString *loc in rs.stopIdArray) {
            stopInfo2[stopIndex].stopId = loc.intValue;
            stopInfo2[stopIndex].hotspot = rs.index;
            
            stopInfo2[stopIndex].lat = allRailStops[loc].location.coordinate.latitude;
            stopInfo2[stopIndex].lng = allRailStops[loc].location.coordinate.longitude;
            stopInfo2[stopIndex].tp = allRailStops[loc].timePoint;
            stopInfo2[stopIndex].lines = [self linesForStop:loc allRoutes:allRoutes];
            
            stopIndex++;
        }
    }
    
    qsort(stopInfo2, stopIndex, sizeof(stopInfo2[0]), [AllRailStationView compareStopInfos]);
    
    for (i = 0; i < stopIndex; i++) {
        XCTAssertEqual(stopInfo[i].stopId, stopInfo2[i].stopId);
        XCTAssertEqual(stopInfo[i].hotspot, stopInfo2[i].hotspot, @"Item %d Stop Id: %ld", i, stopInfo[i].stopId);
        XCTAssertEqualWithAccuracy(stopInfo[i].lat, stopInfo2[i].lat, 0.0000000001, @"Item %d Stop Id: %ld", i, stopInfo[i].stopId);
        XCTAssertEqualWithAccuracy(stopInfo[i].lng, stopInfo2[i].lng, 0.0000000001, @"Item %d Stop Id: %ld", i, stopInfo[i].stopId);
        XCTAssertEqual(stopInfo[i].tp, stopInfo2[i].tp, @"Item %d Stop Id: %ld", i, stopInfo[i].stopId);
        XCTAssertEqual(stopInfo[i].lines, stopInfo2[i].lines, @"Item %d Stop Id: %ld", i, stopInfo[i].stopId);
    }
}

- (RailLines)linesForStop:(NSString *)stopId allRoutes:(XMLRoutes *)allRoutes {
    __block RailLines lines = 0;
    for (PtrConstRouteInfo routeInfo = [TriMetInfo allColoredLines]; routeInfo->route_number != kNoRoute; routeInfo++) {
        NSString *routeNumber = [TriMetInfo routeString:routeInfo];
        
        for (Route *route in allRoutes) {
            if ([route.route isEqualToString:routeNumber]) {
                [route.directions enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Direction * _Nonnull direction, BOOL * _Nonnull stopIteration) {
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

- (void)generateStopIdTable:(NSArray<RailStation *> *)sortedStations allRailStops:(NSDictionary<NSString *, Stop *> *)allRailStops allRoutes:(XMLRoutes *)allRoutes {
    NSMutableString *codeText = [NSMutableString string];
    int i;
    StopInfo stopInfo2[MAXHOTSPOTS * 3] = { 0 };
    
    CODE_COMMENT((@[
        @"//",
        @"// This table allows a quick lookup of a hot spot and location from a stop ID.",
        @"// Only the IDs of rail stations are in here.",
        @"//"]));
    
    int stopIndex = 0;
    
    for (RailStation *rs in sortedStations) {
        for (NSString *loc in rs.stopIdArray) {
            stopInfo2[stopIndex].stopId = loc.intValue;
            stopInfo2[stopIndex].hotspot = rs.index;
            
            stopInfo2[stopIndex].lat = allRailStops[loc].location.coordinate.latitude;
            stopInfo2[stopIndex].lng = allRailStops[loc].location.coordinate.longitude;
            stopInfo2[stopIndex].tp = allRailStops[loc].timePoint;
            stopInfo2[stopIndex].lines = [self linesForStop:loc allRoutes:allRoutes];
            
            stopIndex++;
        }
    }
    
    qsort(stopInfo2, stopIndex, sizeof(stopInfo2[0]), [AllRailStationView compareStopInfos]);
    
    [codeText appendString:@"\nstatic const StopInfo stopInfo[]={\n"];
    [codeText appendString:@"//   Stop ID  Index Latitude                 Longitude                  TP Lines\n"];
    for (i = 0; i < stopIndex; i++) {
        [codeText appendFormat:@"    { %5d, %5d, %10.20f, %10.20f, %d, 0x%04x},\n", (int)stopInfo2[i].stopId, (int)stopInfo2[i].hotspot, stopInfo2[i].lat, stopInfo2[i].lng, stopInfo2[i].tp, stopInfo2[i].lines];
    }
    
    [codeText appendFormat:@"};\n"];
    
    CODE_STRING(codeText);
}

// Note - for the full outout to be logged, you may need this command to make the logging deal with longer strings
// setting set target.max-string-summary-length 100000

- (void)test_Online_GenerateStaticArrays {
    [RailMapView initHotspotData];
    
    NSArray<RailStation *> *sortedStations = [self sortStations];
    
    CODE_FILE(@"StaticStationData.m");
    
    XMLRoutes *allRoutes = [XMLRoutes xml];
    NSDictionary<NSString *, Stop *> *allRailStops =  allRoutes.getAllRailStops;
    
    [self generateAlphaStations:sortedStations];
    
    [self generateRouteColors:sortedStations allRoutes:allRoutes];
    
    [self generateSections:sortedStations];
    
    [self generateStopIdTable:sortedStations allRailStops:allRailStops allRoutes:allRoutes];
    
    CODE_LOG_FILE_END;
}

- (void)test_Online_CheckStaticArrays {
    [RailMapView initHotspotData];
    
    NSArray<RailStation *> *sortedStations = [self sortStations];
    XMLRoutes *allRoutes = [XMLRoutes xml];
    NSDictionary<NSString *, Stop *> *allRailStops =  allRoutes.getAllRailStops;
    
    [self checkAlphaStations:sortedStations];
    
    [self checkRouteColors:sortedStations allRoutes:allRoutes];
    
    [self checkSections:sortedStations];
    
    [self checkStopIdTable:sortedStations allRailStops:allRailStops allRoutes:allRoutes];
}

+ (void)dumpTiles:(NSArray<NSArray<NSSet<NSNumber *> *> *> *)tiles
              map:(RailMap *)map
           output:(NSMutableString *)output {
    [output appendFormat:@"\n/* tiles for %@ (total hotspots: %d) */\n", map->title, map->lastHotspot - map->firstHotspot + 1];
    int total = 0;
    
    [output appendFormat:@"/* -- */ MAP_TILE_ALLOCATE_ARRAY(%d)\n", (int)tiles.count];
    
    int x, y;
    
    for (x = 0; x < tiles.count; x++) {
        NSArray<NSSet<NSNumber *> *> *ya = tiles[x];
        // DEBUG_LOG(@"Stripe size %lu\n", (unsigned long)stripeSet.count);
        
        [output appendFormat:@"/* -- */ MAP_TILE_ALLOCATE_ROW(%d,%d)\n", x, (int)ya.count];
        
        for (y = 0; y < ya.count; y++) {
            NSSet<NSNumber *> *set = ya[y];
            
            
            // NSArray *orderedTiles = [set sortedArrayUsingDescriptors:(nonnull NSArray<NSSortDescriptor *> *)
            NSMutableArray<NSNumber *> *items = [NSMutableArray array];
            
            
            [set enumerateObjectsUsingBlock:^(NSNumber *_Nonnull obj, BOOL *_Nonnull stop) {
                [items addObject:obj];
            }];
            
            [items sortUsingSelector:@selector(compare:)];
        
            [output appendFormat:@"/* %02d */ MAP_START_TILE ", (int)set.count];
            total += set.count;
            
            for (NSNumber *n in items) {
                [output appendFormat:@"%d,", n.intValue - map->firstHotspot];
            }
            
            [output appendFormat:@"MAP_LAST_INDEX MAP_END_TILE(%d,%d)\n", x, y];
        }
    }
    
    [output appendFormat:@"/* Total %d */\n", total];
}

+ (void)makeTiles:(RailMap *)map {
    NSMutableString *output = [NSMutableString string];
    NSArray<NSArray<NSSet<NSNumber *> *> *> *tiles = [MachineGeneratedArrays tileScan:map];
    
    [MachineGeneratedArrays dumpTiles:tiles map:map output:output];
    
    CODE_STRING(output);
}

- (void)test_generate_HotSpot_Tiles {
    [RailMapView initHotspotData];
    CODE_FILE(@"MaxHotSpotTiles.txt");
    [MachineGeneratedArrays makeTiles:[RailMapView railMap:kRailMapMaxWes]];
    CODE_RULE;
    CODE_LOG_FILE_END;
    
    CODE_FILE(@"StreetcarHotSpotTiles.txt");
    [MachineGeneratedArrays makeTiles:[RailMapView railMap:kRailMapPdxStreetcar]];
    CODE_RULE;
    CODE_LOG_FILE_END;
}

+ (NSMutableArray *)tileScan:(RailMap *)map {
    int x, y, i;
    CGPoint p;
    
    HotSpot *hotSpotRegions = [RailMapView hotspotRecords];
    
    NSMutableArray<NSMutableArray<NSMutableSet<NSNumber *> *> *> *xTiles = [NSMutableArray array];
    
    for (x = 0; x < map->xTiles; x++) {
        NSMutableArray<NSMutableSet<NSNumber *> *> *yTiles = [NSMutableArray array];
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
            
            for (i = map->firstHotspot; i <= map->lastHotspot; i++) {
                if (HOTSPOT_HIT((&hotSpotRegions[i]), p)) {
                    [set addObject:@(i)];
                }
            }
        }
    }
    
    return xTiles;
}

+ (bool)checkTile:(RailMap *)map {
    int x, y;
    CGPoint p;
    bool ok = YES;
    
    HotSpot *hotSpotRegions = [RailMapView hotspotRecords];
    
    
    // Make a big fake tile
    RailMapTile allHotSpots;
    
    HotSpotIndex *hotspots = malloc(sizeof(HotSpotIndex) * (map->lastHotspot -  map->firstHotspot + 2));
    
    allHotSpots.hotspots = hotspots;
    
    HotSpotIndex *ptr = hotspots;
    int j = 0;
    
    for (int i = map->firstHotspot; i <= map->lastHotspot; i++) {
        *ptr = j;
        ptr++;
        j++;
    }
    
    *ptr = MAP_LAST_INDEX;
    
    for (x = 0; x < map->size.width; x++) {
        for (y = 0; y < map->size.height; y++) {
            int tx = x /  map->tileSize.width;
            int ty = y /  map->tileSize.height;
            
            RailMapTile *tile = &map->tiles[tx][ty];
            
            p.x = x;
            p.y = y;
            
            int hs1 = [RailMapView findHotSpotInMap:map tile:tile point:p];
            int hs2 = [RailMapView findHotSpotInMap:map tile:&allHotSpots point:p];
            
            if (hs1 != hs2) {
                if (hs1 != NO_HOTSPOT_FOUND) {
                    DEBUG_LOGS(hotSpotRegions[hs1].action);
                }
                
                if (hs2 != NO_HOTSPOT_FOUND) {
                    DEBUG_LOGS(hotSpotRegions[hs2].action);
                }
                
                ok =  NO;
            }
        }
    }
    
    free(hotspots);
    
    return ok;
}

- (void)test_check_HotSpot_MaxTiles {
    [RailMapView initHotspotData];
    XCTAssert([MachineGeneratedArrays checkTile:[RailMapView railMap:kRailMapMaxWes]]);
}

- (void)test_check_HotSpot_StreetcarTiles {
    [RailMapView initHotspotData];
    XCTAssert([MachineGeneratedArrays checkTile:[RailMapView railMap:kRailMapPdxStreetcar]]);
}

@end
