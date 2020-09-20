//
//  AllRailStationView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/5/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AllRailStationView.h"
#import "DepartureTimesView.h"

#import "HotSpot.h"
#import "RailStation.h"
#import "RailStationTableView.h"
#import "XMLStops.h"
#import "RailMapView.h"
#import "XMLDepartures.h"
#import "MapViewController.h"
#import "DebugLogging.h"
#import "RailMapView.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <stdlib.h>
#import "NSString+Helper.h"
#import "CLLocation+Helper.h"

// Machine generated static data structures are used for the search

#import "StaticStationData.m"

@interface AllRailStationView () {
    HOTSPOT *_hotSpots;
}
@end


@implementation AllRailStationView

- (instancetype)init {
    if ((self = [super init])) {
        _hotSpots = [RailMapView hotspotRecords];
        [RailMapView initHotspotData];
        self.title = NSLocalizedString(@"All Rail Stations", @"screen title");
        
        self.searchableItems = [NSMutableArray array];
        
#ifndef CREATE_MAX_ARRAYS
        
        for (int i = 0; i < sizeof(stationsAlpha) / sizeof(int); i++) {
            RailStation *station = [RailStation fromHotSpot:_hotSpots + stationsAlpha[i] index:stationsAlpha[i]];
            
            [self.searchableItems addObject:station];
        }
        
        self.enableSearch = YES;
#endif
    }
    
    return self;
}

- (void)addLineToDescription:(NSMutableString *)desc line:(RAILLINES)line station:(RAILLINES)station name:(NSString *)name {
    if ((station & line) != 0) {
        if (desc.length > 0) {
            [desc appendString:@", "];
        }
        
        [desc appendString:name];
    }
}

- (void)indexStations {
    Class searchClass = (NSClassFromString(@"CSSearchableIndex"));
    
    if (searchClass == nil || ![CSSearchableIndex isIndexingAvailable]) {
        return;
    }
    
    CSSearchableIndex *searchableIndex = [CSSearchableIndex defaultSearchableIndex];
    
    
    [searchableIndex deleteSearchableItemsWithDomainIdentifiers:@[ @"station" ] completionHandler:^(NSError *__nullable error)
     {
        @autoreleasepool {
            if (error != nil) {
                ERROR_LOG(@"Failed to delete station index %@\n", error.description);
            }
            
            if (Settings.searchStations) {
                NSMutableArray *index = [NSMutableArray array];
                
                for (int i = 0; i < sizeof(stationsAlpha) / sizeof(int); i++) {
                    RailStation *station = [[RailStation alloc] initFromHotSpot:self->_hotSpots + stationsAlpha[i] index:stationsAlpha[i]];
                    NSInteger alpha = stationsAlpha[i];
                    RAILLINES lines = railLines0[alpha] | railLines1[alpha];
                    
                    
                    CSSearchableItemAttributeSet *attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeText];
                    attributeSet.title = station.station;
                    
                    NSMutableString *desc = [NSMutableString string];
                    
                    for (PC_ROUTE_INFO info = [TriMetInfo allColoredLines]; info->route_number != kNoRoute; info++) {
                        [self addLineToDescription:desc line:info->line_bit station:lines name:info->full_name];
                    }
                    
                    attributeSet.contentDescription = [NSString stringWithFormat:@"TriMet station serving %@", desc];
                    
                    NSString *uniqueId = [NSString stringWithFormat:@"%@:%d", kSearchItemStation, stationsAlpha[i]];
                    
                    CSSearchableItem *item = [[CSSearchableItem alloc] initWithUniqueIdentifier:uniqueId domainIdentifier:@"station" attributeSet:attributeSet];
                    
                    [index addObject:item];
                }
                
                [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:index completionHandler: ^(NSError *__nullable error) {
                    if (error != nil) {
                        ERROR_LOG(@"Failed to index stations %@\n", error.description);
                    }
                }];
            }
        }
    }];
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    [toolbarItems addObject:[UIToolbar mapButtonWithTarget:self action:@selector(showMap:)]];
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

- (void)showMap:(id)sender {
    int i, j;
    CLLocation *here;
    NSArray *items = [self topViewData];
    
    MapViewController *mapPage = [MapViewController viewController];
    
    for (i = 0; i < items.count; i++) {
        //if (_hotSpots[stationsAlpha[i]].action[0]==kLinkTypeStop)
        {
            RailStation *station = items[i];
            
            // NSString *stop = nil;
            NSString *dir = nil;
            NSString *stopId = nil;
            
            for (j = 0; j < station.dirArray.count; j++) {
                dir = station.dirArray[j];
                stopId = station.stopIdArray[j];
                
                here = [AllRailStationView locationFromStopId:stopId];
                
                if (here) {
                    Stop *a = [Stop data];
                    
                    a.stopId = stopId;
                    a.desc = station.station;
                    a.dir = dir;
                    a.lat = [NSString stringWithFormat:@"%f", here.coordinate.latitude];
                    a.lng = [NSString stringWithFormat:@"%f", here.coordinate.longitude];
                    a.callback = self;
                    
                    [mapPage addPin:a];
                }
            }
        }
    }
    
    mapPage.stopIdCallback = self.stopIdCallback;
    
    [self.navigationController pushViewController:mapPage animated:YES];
}

+ (RAILLINES)railLines:(int)index {
    return railLines0[index] | railLines1[index];
}

+ (RAILLINES)railLines0:(int)index {
    return railLines0[index];
}

+ (RAILLINES)railLines1:(int)index {
    return railLines1[index];
}

#define kAlphaSection  0
#define kFilterSection 1

- (int)sectionType:(UITableView *)tableView section:(NSInteger)section {
    if (tableView == self.table) {
        if (section < ALPHA_SECTIONS_CNT) {
            return kAlphaSection;
        }
        
        return kSectionRowDisclaimerType;
    }
    
    return kFilterSection;
}

#pragma mark TableView methods

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self safeScrollToTop];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (tableView == self.table) {
        NSMutableArray *titles = [NSMutableArray array];
        
        [titles addObject:UITableViewIndexSearch];
        
        for (int i = 0; i < ALPHA_SECTIONS_CNT; i++) {
            [titles addObject:[NSString stringWithFormat:@"%s", alphaSections[i].title]];
        }
        
        return titles;
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if (title == UITableViewIndexSearch) {
        [tableView scrollRectToVisible:self.searchController.searchBar.frame animated:NO];
        return -1;
    }
    
    return index - 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.table) {
        return sizeof(alphaSections) / sizeof(alphaSections[0]) + 1;
    }
    
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self sectionType:tableView section:indexPath.section]) {
        case kAlphaSection:
            return [self basicRowHeight];
            
        case kSectionRowDisclaimerType:
            return kDisclaimerCellHeight;
            
        case kFilterSection:
            return [self basicRowHeight];
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ([self sectionType:tableView section:section]) {
        case kAlphaSection:
            return alphaSections[section].items;
            
        case kSectionRowDisclaimerType:
            return 1;
            
        case kFilterSection:
            return [self filteredData:tableView].count;
    }
    return 0;
}

- (RailStation *)stationForIndex:(NSIndexPath *)indexPath tableView:(UITableView *)tableView {
    RailStation *station = nil;
    
    switch ([self sectionType:tableView section:indexPath.section]) {
        case kAlphaSection: {
            int offset = alphaSections[indexPath.section].offset + (int)indexPath.row;
            station = self.searchableItems[offset];
        }
            break;
            
        case kSectionRowDisclaimerType:
            break;
            
        case kFilterSection: {
            NSArray *items = [self filteredData:tableView];
            
            if (indexPath.row < items.count) {
                station = items[indexPath.row];
            }
        }
    }
    return station;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Configure the cell
    UITableViewCell *cell = nil;
    
    int sectionType = [self sectionType:tableView section:indexPath.section];
    
    switch (sectionType) {
        case kAlphaSection:
        case kFilterSection: {
            RailStation *station = [self stationForIndex:indexPath tableView:tableView];
            
            cell = [RailStation tableView:tableView
                  cellWithReuseIdentifier:MakeCellId(kAlphaSection)
                                rowHeight:[self tableView:tableView heightForRowAtIndexPath:indexPath]];
            
            [RailStation populateCell:cell
                              station:station.station
                                lines:railLines0[station.index] | railLines1[station.index]];
            
            //    DEBUG_LOG(@"Section %d row %d offset %d index %d name %@ line %x\n", indexPath.section,
            //                  indexPath.row, offset, index, [RailStation nameFromHotspot:_hotSpots+index], railLines[index]);
            break;
        }
            
        case kSectionRowDisclaimerType:
            cell = [self disclaimerCell:tableView];
            [self updateDisclaimerAccessibility:cell];
            break;
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ([self sectionType:tableView section:section]) {
        case kAlphaSection:
            return [NSString stringWithFormat:@"%s", alphaSections[section].title];
            
        case kFilterSection:
            return nil;
            
        case kSectionRowDisclaimerType:
            return nil;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self sectionType:tableView section:indexPath.section]) {
        case kFilterSection:
        case kAlphaSection: {
            RailStation *station = [self stationForIndex:indexPath tableView:tableView];
            
            if (station == nil) {
                return;
            }
            
            RailStationTableView *railView = [RailStationTableView viewController];
            railView.station = station;
            railView.stopIdCallback = self.stopIdCallback;
            [railView maybeFetchRouteShapesAsync:self.backgroundTask];
        }
            
        case kSectionRowDisclaimerType:
            break;
    }
}

#pragma mark ReturnStop callbacks

- (void)chosenStop:(Stop *)stop progress:(id<TaskController>)progress {
    if (self.stopIdCallback) {
        if ([self.stopIdCallback respondsToSelector:@selector(selectedStop:desc:)]) {
            [self.stopIdCallback selectedStop:stop.stopId desc:stop.desc];
        } else {
            [self.stopIdCallback selectedStop:stop.stopId];
        }
        
        return;
    }
    
    DepartureTimesView *departureViewController = [DepartureTimesView viewController];
    
    departureViewController.displayName = stop.desc;
    
    [departureViewController fetchTimesForLocationAsync:progress stopId:stop.stopId];
}

- (NSString *)actionText {
    if (self.stopIdCallback) {
        return [self.stopIdCallback actionText];
    }
    
    return NSLocalizedString(@"Show departures", @"button text");
}

#pragma mark Data Creation Methods - not used at runtime


#ifdef CREATE_MAX_ARRAYS

- (void)addLine:(RAILLINES)line route:(NSString *)route direction:(NSString *)direction stations:(NSArray *)stations query:(NSString *)query raillines:(RAILLINES *)lines {
    int i, j, k;
    
    XMLStops *xml = [XMLStops xml];
    
    xml.staticQuery = query;
    
    [xml getStopsForRoute:route direction:direction
              description:@"" cacheAction:TriMetXMLNoCaching];
    
    for (i = 0; i < xml.items.count; i++) {
        Stop *stop = xml.items[i];
        
        for (j = 0; j < stations.count; j++) {
            RailStation *r = stations[j];
            
            for (k = 0; k < r.stopIdArray.count; k++) {
                NSString *loc = r.stopIdArray[k];
                
                if ([stop.stopId isEqualToString:loc]) {
                    lines[r.index] |= line;
                    break;
                }
            }
        }
    }
}

- (NSString *)directionForStop:(NSString *)stop {
    XMLDepartures *dep = [XMLDepartures xml];
    
    [dep getDeparturesForStopId:stop];
    
    return dep.locDir;
}

- (void)addStreetcar:(RAILLINES)line route:(NSString *)route direction:(NSString *)direction stations:(NSMutableArray *)streetcarStops {
    XMLStops *xml = [XMLStops xml];
    
    [xml getStopsForRoute:route direction:direction
              description:@"" cacheAction:TriMetXMLNoCaching];
    
    for (Stop *stop in xml.items) {
        RailStation *found = nil;
        
        // see if station exists
        for (RailStation *r in streetcarStops) {
            if ([r.station isEqualToString:stop.desc]) {
                found = r;
                break;
            }
        }
        
        if (!found) {
            found = [[RailStation alloc] init];
            found.station = stop.desc;
            found.stopIdArray = [NSMutableArray array];
            found.dirArray = [NSMutableArray array];
            
            [found.stopIdArray addObject:stop.stopId];
            [found.dirArray addObject:[self directionForStop:stop.stopId]];
            
            [streetcarStops addObject:found];
        } else {
            NSString *stopId = nil;
            int i = 0;
            
            for (i = 0; i < found.stopIdArray.count; i++) {
                stopId = found.stopIdArray[i];
                
                if ([stopId isEqualToString:stop.stopId]) {
                    break;
                }
            }
            
            if (i == found.stopIdArray.count) {
                [found.stopIdArray addObject:stop.stopId];
                [found.dirArray addObject:[self directionForStop:stop.stopId]];
            }
        }
    }
}

#endif // ifdef CREATE_MAX_ARRAYS


int comparestopInfos(const void *first, const void *second) {
    return (int)(((STOP_INFO *)first)->stopId - ((STOP_INFO *)second)->stopId);
}

+ (RailStation *)railstationFromStopId:(NSString *)stopId {
    [RailMapView initHotspotData];
    
    RailStation *res = nil;
    STOP_INFO key = { (long)stopId.longLongValue, 0, 0, 0 };
    
    STOP_INFO *result = (STOP_INFO *)bsearch(&key, stopInfo, sizeof(stopInfo) / sizeof(stopInfo[0]), sizeof(stopInfo[0]), comparestopInfos);
    
    if (result) {
        HOTSPOT *hotspots = [RailMapView hotspotRecords];
        
        res = [RailStation fromHotSpot:hotspots + (result->hotspot) index:result->hotspot];
    }
    
    return res;
}

+ (CLLocation *)locationFromStopId:(NSString *)stopId {
    [RailMapView initHotspotData];
    
    CLLocation *res = nil;
    
    STOP_INFO key = { (long)stopId.longLongValue, 0 };
    
    STOP_INFO *result = (STOP_INFO *)bsearch(&key, stopInfo, sizeof(stopInfo) / sizeof(stopInfo[0]), sizeof(stopInfo[0]), comparestopInfos);
    
    if (result) {
        res = [CLLocation withLat:result->lat lng:result->lng];
    }
    
    return res;
}

#ifdef CREATE_MAX_ARRAYS

- (NSArray<RailStation *> *)sortStations {
    NSMutableArray<RailStation *> *stations = [NSMutableArray array];
    int i;
    int nHotSpots = [RailMapView nHotspotRecords];
    HOTSPOT *hotSpotRegions = [RailMapView hotspotRecords];
    
    for (i = 0; i < nHotSpots; i++) {
        if (hotSpotRegions[i].action.firstUnichar == kLinkTypeStop) {
            [stations addObject:[RailStation fromHotSpot:hotSpotRegions + i index:i]];
        }
    }
    
    [stations sortUsingSelector:@selector(compareUsingStation:)];
    
    return stations;
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
        [codeText appendFormat:@"\t0x%03x, \t/* %@ */\n", sortedStations[i].index, sortedStations[i].station];
    }
    
    [codeText appendString:@"};\n"];
    
    CODE_STRING(codeText);
}

- (void)generateRouteDirection:(NSArray<RailStation *> *)sortedStations lines:(RAILLINES *)lines name:(NSString *)name {
    int nHotSpots = [RailMapView nHotspotRecords];
    NSMutableString *codeText = [NSMutableString string];
    
    [codeText appendFormat:@"\nstatic const RAILLINES %@[]={\n", name];
    int i;
    
    for (i = 0; i < nHotSpots; i++) {
        [codeText appendFormat:@"\t0x%04x,\t", lines[i]];
        
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

- (void)generateRouteColors:(NSArray<RailStation *> *)sortedStations {
    NSString *routeNumber = nil;
    RAILLINES createRailLines0[MAXHOTSPOTS] = { 0 };
    RAILLINES createRailLines1[MAXHOTSPOTS] = { 0 };
    
    CODE_COMMENT((@[
        @"//",
        @"// These are the colors for the lines of each rail station in the hotspot array.",
        @"// It is calculated by gettng the stops for each station and merging them in.",
        @"// Much easier than doing it by hand!",
        @"//",
        @"// There is one array for each direction"]));
    
    for (PC_ROUTE_INFO routeInfo = [TriMetInfo allColoredLines]; routeInfo->route_number != kNoRoute; routeInfo++) {
        routeNumber = [TriMetInfo routeString:routeInfo];
        
        [self addLine:routeInfo->line_bit route:routeNumber direction:@"0" stations:sortedStations query:nil raillines:createRailLines0];
        
        if (routeInfo->opposite == kDir1) {
            [self addLine:routeInfo->line_bit route:routeNumber direction:@"1" stations:sortedStations query:nil raillines:createRailLines1];
        }
    }
    
    [self generateRouteDirection:sortedStations lines:createRailLines0 name:@"railLines0"];
    
    [self generateRouteDirection:sortedStations lines:createRailLines1 name:@"railLines1"];
}

- (NSString *)sectionForTitle:(NSString *)title {
    NSString *section = [NSString stringWithFormat:@"\"%@\"", title];
    
    return [section stringByPaddingToLength:4 withString:@" " startingAtIndex:0];
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
    
    [codeText appendFormat:@"\nstatic const ALPHA_SECTIONS alphaSections[]={\n"];
    
    RailStation *r = sortedStations[0];
    NSString *title = [NSString stringWithFormat:@"%c", [r.station characterAtIndex:0]];
    NSString *next = nil;
    int offset = 0;
    int count = 1;
    
    NSArray *specialCases = @[@"NW", @"NE", @"SW", @"SE", @"NE"];
    
    for (i = 1; i < sortedStations.count; i++) {
        r = [sortedStations objectAtIndex:i];
        
        next = nil;
        
        for (NSString *prefix in specialCases) {
            if (prefix.length <= r.station.length) {
                NSString *sub = [r.station substringToIndex:prefix.length];
                
                if ([prefix isEqualToString:sub]) {
                    next = prefix;
                }
            }
        }
        
        if (next == nil) {
            next = [NSString stringWithFormat:@"%c", [r.station characterAtIndex:0]];
        }
        
        if (![next isEqualToString:title]) {
            [codeText appendFormat:@"\t{ %@, %5d, %5d},\n", [self sectionForTitle:title], offset, count];
            title = next;
            offset = i;
            count = 1;
        } else {
            count++;
        }
    }
    
    [codeText appendFormat:@"\t{ %@, %5d, %5d},\n", [self sectionForTitle:title], offset, count];
    
    [codeText appendFormat:@"};\n"];
    
    CODE_STRING(codeText);
}

- (void)generateStopIdTable:(NSArray<RailStation *> *)sortedStations {
    NSMutableString *codeText = [NSMutableString string];
    int i;
    STOP_INFO stopInfo2[MAXHOTSPOTS * 3] = { 0 };
    
    CODE_COMMENT((@[
        @"//",
        @"// This table allows a quick lookup of a hot spot and location from a stop ID.",
        @"// Only the IDs of rail stations are in here.",
        @"//"]));
    
    int stops = 0;
    
    for (RailStation *rs in sortedStations) {
        for (NSString *loc in rs.stopIdArray) {
            stopInfo2[stops].stopId = loc.intValue;
            stopInfo2[stops].hotspot = rs.index;
            
            XMLDepartures *dep = [XMLDepartures xmlWithOptions:DepOptionsFirstOnly | DepOptionsNoDetours];
            
            [dep getDeparturesForStopId:loc];
            
            stopInfo2[stops].lat = dep.loc.coordinate.latitude;
            stopInfo2[stops].lng = dep.loc.coordinate.longitude;
            
            stops++;
        }
    }
    
    qsort(stopInfo2, stops, sizeof(stopInfo2[0]), comparestopInfos);
    
    [codeText appendString:@"\nstatic const STOP_INFO stopInfo[]={\n"];
    
    for (i = 0; i < stops; i++) {
        [codeText appendFormat:@"\t{ %5d, %5d, %10f, %10f},\n", (int)stopInfo2[i].stopId, (int)stopInfo2[i].hotspot, stopInfo2[i].lat, stopInfo2[i].lng];
    }
    
    [codeText appendFormat:@"};\n"];
    
    CODE_STRING(codeText);
}

#endif // ifdef CREATE_MAX_ARRAYS

- (void)generateArrays {
#ifdef CREATE_MAX_ARRAYS
    [RailMapView initHotspotData];
    
    NSArray<RailStation *> *sortedStations = [self sortStations];
    
    CODE_FILE(@"StaticStationData.m");
    
    [self generateAlphaStations:sortedStations];
    
    [self generateRouteColors:sortedStations];
    
    [self generateSections:sortedStations];
    
    [self generateStopIdTable:sortedStations];
    
    CODE_LOG_FILE_END;
    
    exit(0);
    
#endif
}

@end
