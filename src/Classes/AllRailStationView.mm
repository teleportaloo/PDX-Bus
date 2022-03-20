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
    HotSpot *_hotSpots;
}
@end


@implementation AllRailStationView

- (instancetype)init {
    if ((self = [super init])) {
        _hotSpots = [RailMapView hotspotRecords];
        [RailMapView initHotspotData];
        self.title = NSLocalizedString(@"All Rail Stations", @"screen title");
        
        self.searchableItems = [NSMutableArray array];

        for (int i = 0; i < sizeof(stationsAlpha) / sizeof(int); i++) {
            RailStation *station = [RailStation fromHotSpot:_hotSpots + stationsAlpha[i] index:stationsAlpha[i]];
            
            [self.searchableItems addObject:station];
        }
        
        self.enableSearch = YES;
    }
    
    return self;
}

- (void)addLineToDescription:(NSMutableString *)desc line:(RailLines)line station:(RailLines)station name:(NSString *)name {
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
                    RailLines lines = railLines0[alpha] | railLines1[alpha];
                    
                    
                    CSSearchableItemAttributeSet *attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeText];
                    attributeSet.title = station.station;
                    
                    NSMutableString *desc = [NSMutableString string];
                    
                    for (PtrConstRouteInfo info = [TriMetInfo allColoredLines]; info->route_number != kNoRoute; info++) {
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
    bool tp;
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
                tp = [AllRailStationView tpFromStopId:stopId];
                
                if (here) {
                    Stop *a = [Stop new];
                    
                    a.stopId = stopId;
                    a.desc = station.station;
                    a.dir = dir;
                    a.location = here;
                    a.stopObjectCallback = self;
                    a.timePoint = tp;
                    
                    [mapPage addPin:a];
                }
            }
        }
    }
    
    mapPage.stopIdStringCallback = self.stopIdStringCallback;
    
    [self.navigationController pushViewController:mapPage animated:YES];
}

+ (RailLines)railLines:(int)index {
    return railLines0[index] | railLines1[index];
}

+ (RailLines)railLines0:(int)index {
    return railLines0[index];
}

+ (RailLines)railLines1:(int)index {
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
                                rowHeight:[self tableView:tableView
                                  heightForRowAtIndexPath:indexPath]];
            
            [RailStation populateCell:cell
                              station:station.station.safeEscapeForMarkUp
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
            railView.stopIdStringCallback = self.stopIdStringCallback;
            [railView maybeFetchRouteShapesAsync:self.backgroundTask];
        }
            
        case kSectionRowDisclaimerType:
            break;
    }
}

#pragma mark ReturnStop callbacks

- (void)returnStopObject:(Stop *)stop progress:(id<TaskController>)progress {
    if (self.stopIdStringCallback) {
        [self.stopIdStringCallback returnStopIdString:stop.stopId desc:stop.desc];
        return;
    }
    
    DepartureTimesView *departureViewController = [DepartureTimesView viewController];
    
    departureViewController.displayName = stop.desc;
    
    [departureViewController fetchTimesForLocationAsync:progress stopId:stop.stopId];
}

- (NSString *)returnStopObjectActionText {
    if (self.stopIdStringCallback) {
        return [self.stopIdStringCallback returnStopIdStringActionText];
    }
    
    return @"";
}

#pragma mark Data Creation Methods - not used at runtime

int static comparestopInfos(const void *first, const void *second) {
    return (int)(((StopInfo *)first)->stopId - ((StopInfo *)second)->stopId);
}

+ (StopInfoCompare)compareStopInfos {
    return comparestopInfos;
}

+ (RailStation *)railstationFromStopId:(NSString *)stopId {
    [RailMapView initHotspotData];
    
    RailStation *res = nil;
    StopInfo key = { (long)stopId.longLongValue, 0, 0, 0 };
    
    StopInfo *result = (StopInfo *)bsearch(&key, stopInfo, sizeof(stopInfo) / sizeof(stopInfo[0]), sizeof(stopInfo[0]), comparestopInfos);
    
    if (result) {
        HotSpot *hotspots = [RailMapView hotspotRecords];
        
        res = [RailStation fromHotSpot:hotspots + (result->hotspot) index:result->hotspot];
    }
    
    return res;
}

+ (CLLocation *)locationFromStopId:(NSString *)stopId {
    [RailMapView initHotspotData];
    
    CLLocation *res = nil;
    
    StopInfo key = { (long)stopId.longLongValue, 0 };
    
    StopInfo *result = (StopInfo *)bsearch(&key, stopInfo, sizeof(stopInfo) / sizeof(stopInfo[0]), sizeof(stopInfo[0]), comparestopInfos);
    
    if (result) {
        res = [CLLocation withLat:result->lat lng:result->lng];
    }
    
    return res;
}

+ (RailLines)railLinesForStopId:(NSString *)stopId {
    [RailMapView initHotspotData];
    
    RailLines lines = 0;
    
    StopInfo key = { (long)stopId.longLongValue, 0 };
    
    StopInfo *result = (StopInfo *)bsearch(&key, stopInfo, sizeof(stopInfo) / sizeof(stopInfo[0]), sizeof(stopInfo[0]), comparestopInfos);
    
    if (result) {
        lines = result->lines;
    }
    
    return lines;
}



+ (bool)tpFromStopId:(NSString *)stopId {
    [RailMapView initHotspotData];
        
    StopInfo key = { (long)stopId.longLongValue, 0 };
    
    StopInfo *result = (StopInfo *)bsearch(&key, stopInfo, sizeof(stopInfo) / sizeof(stopInfo[0]), sizeof(stopInfo[0]), comparestopInfos);
    
    if (result) {
        return result->tp;
    }
    
    return NO;
}



@end
