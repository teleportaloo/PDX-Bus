//
//  AllRailStationViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/5/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AllRailStationViewController.h"
#import "DepartureTimesViewController.h"

#import "CLLocation+Helper.h"
#import "DebugLogging.h"
#import "HotSpot.h"
#import "MapViewController.h"
#import "NSString+MoreMarkup.h"
#import "RailMapViewController.h"
#import "RailStation+UI.h"
#import "RailStation.h"
#import "RailStationTableViewController.h"
#import "StationData.h"
#import "Stop+UI.h"
#import "TriMetInfoColoredLines.h"
#import "XMLDepartures.h"
#import "XMLStops.h"
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <stdlib.h>

// Machine generated static data structures are used for the search

@interface AllRailStationViewController () {
    size_t _stationsAlphaCnt;
    const int *_stationsAlpha;
    const TriMetInfo_AlphaSections *_alphaSections;
    size_t _alphaSectionsCnt;
}

@property(nonatomic) bool appeared;

@end

@implementation AllRailStationViewController

- (instancetype)init {
    if ((self = [super init])) {
        _stationsAlpha =
            [StationData getStationAlphaAndCount:&_stationsAlphaCnt];
        _alphaSections =
            [StationData getAlphaSectionsAndCount:&_alphaSectionsCnt];

        self.title = NSLocalizedString(@"All Rail Stations", @"screen title");

        self.searchableItems = [NSMutableArray array];

        for (int i = 0; i < _stationsAlphaCnt; i++) {
            RailStation *station =
                [RailStation fromHotSpotIndex:_stationsAlpha[i]];

            [self.searchableItems addObject:station];
        }

        self.enableSearch = YES;
    }

    return self;
}

- (void)addLineToDescription:(NSMutableString *)desc
                        line:(TriMetInfo_ColoredLines)line
                     station:(TriMetInfo_ColoredLines)station
                        name:(NSString *)name {
    if ((station & line) != 0) {
        if (desc.length > 0) {
            [desc appendString:@", "];
        }

        [desc appendString:name];
    }
}

- (void)addStationsToIndex {
    if (Settings.searchStations) {
        NSMutableArray *index = [NSMutableArray array];

        for (int i = 0; i < self->_stationsAlphaCnt; i++) {
            RailStation *station =
                [RailStation fromHotSpotIndex:self->_stationsAlpha[i]];
            NSInteger alpha = self->_stationsAlpha[i];
            TriMetInfo_ColoredLines lines = [StationData railLines:(int)alpha];

            CSSearchableItemAttributeSet *attributeSet =
                [[CSSearchableItemAttributeSet alloc]
                    initWithItemContentType:UTTypeText.identifier];
            attributeSet.title = station.name;

            NSMutableString *desc = [NSMutableString string];

            for (PtrConstRouteInfo info = TriMetInfoColoredLines.allLines;
                 info->route_number != kNoRoute; info++) {
                [self addLineToDescription:desc
                                      line:info->line_bit
                                   station:lines
                                      name:info->full_name];
            }

            attributeSet.contentDescription =
                [NSString stringWithFormat:@"TriMet station "
                                           @"serving %@",
                                           desc];

            NSString *uniqueId =
                [NSString stringWithFormat:@"%@:%d", kSearchItemStation,
                                           self->_stationsAlpha[i]];

            CSSearchableItem *item = [[CSSearchableItem alloc]
                initWithUniqueIdentifier:uniqueId
                        domainIdentifier:@"station"
                            attributeSet:attributeSet];

            [index addObject:item];
        }

        [[CSSearchableIndex defaultSearchableIndex]
            indexSearchableItems:index
               completionHandler:^(NSError *__nullable error) {
                 if (error != nil) {
                     ERROR_LOG(@"Failed to index "
                               @"stations %@\n",
                               error.description);
                 }
               }];
    }
}

- (void)indexStations {
    Class searchClass = (NSClassFromString(@"CSSearchableIndex"));

    if (searchClass == nil || ![CSSearchableIndex isIndexingAvailable]) {
        return;
    }

    CSSearchableIndex *searchableIndex =
        [CSSearchableIndex defaultSearchableIndex];

    [searchableIndex
        deleteSearchableItemsWithDomainIdentifiers:@[ @"station" ]
                                 completionHandler:^(
                                     NSError *__nullable error) {
                                   if (error != nil) {
                                       ERROR_LOG(@"Failed to delete "
                                                 @"station index %@\n",
                                                 error.description);
                                   }
                                   [self addStationsToIndex];
                                 }];
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    [toolbarItems
        addObject:[UIToolbar mapButtonWithTarget:self
                                          action:@selector(showMap:)]];
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

- (void)showMap:(id)sender {
    int i, j;
    CLLocation *here;
    bool tp;
    NSArray *items = [self topViewData];

    MapViewController *mapPage = [MapViewController viewController];

    for (i = 0; i < items.count; i++) {
        RailStation *station = items[i];

        // NSString *stop = nil;
        NSString *dir = nil;
        NSString *stopId = nil;

        for (j = 0; j < station.dirArray.count; j++) {
            dir = station.dirArray[j];
            stopId = station.stopIdArray[j];

            here = [StationData locationFromStopId:stopId];
            tp = [StationData tpFromStopId:stopId];

            if (here) {
                Stop *a = [Stop new];

                a.stopId = stopId;
                a.desc = station.name;
                a.dir = dir;
                a.location = here;
                a.stopObjectCallback = self;
                a.timePoint = tp;

                [mapPage addPin:a];
            }
        }
    }

    mapPage.stopIdStringCallback = self.stopIdStringCallback;

    [self.navigationController pushViewController:mapPage animated:YES];
}

#define kAlphaSection 0
#define kFilterSection 1

- (int)sectionType:(UITableView *)tableView section:(NSInteger)section {
    if (tableView == self.tableView) {
        if (section < _alphaSectionsCnt) {
            return kAlphaSection;
        }

        return kSectionRowDisclaimerType;
    }

    return kFilterSection;
}

#pragma mark TableView methods

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.appeared = YES;

    [self reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self safeScrollToTop];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        // We don't respond until the view did appear and the reload data
        // that occurs there. This is so that the index doesn't jerk to the left
        // as it finally resized, it just appears.
        if (self.appeared) {
            NSMutableArray *titles = [NSMutableArray array];

            [titles addObject:UITableViewIndexSearch];

            for (int i = 0; i < _alphaSectionsCnt; i++) {
                [titles
                    addObject:_alphaSections[i].title];
            }
            return titles;
        } else {
            return @[ @"" ];
        }
    }

    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView
    sectionForSectionIndexTitle:(NSString *)title
                        atIndex:(NSInteger)index {
    if (title == UITableViewIndexSearch) {
        [tableView scrollRectToVisible:self.searchController.searchBar.frame
                              animated:NO];
        return -1;
    }

    return index - 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        return _alphaSectionsCnt + 1;
    }

    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
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

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
    switch ([self sectionType:tableView section:section]) {
    case kAlphaSection:
        return _alphaSections[section].items;

    case kSectionRowDisclaimerType:
        return 1;

    case kFilterSection:
        return [self filteredData:tableView].count;
    }
    return 0;
}

- (RailStation *)stationForIndex:(NSIndexPath *)indexPath
                       tableView:(UITableView *)tableView {
    RailStation *station = nil;

    switch ([self sectionType:tableView section:indexPath.section]) {
    case kAlphaSection: {
        int offset =
            _alphaSections[indexPath.section].offset + (int)indexPath.row;
        station = self.searchableItems[offset];
    } break;

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

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Configure the cell
    UITableViewCell *cell = nil;

    int sectionType = [self sectionType:tableView section:indexPath.section];

    switch (sectionType) {
    case kAlphaSection:
    case kFilterSection: {
        RailStation *station = [self stationForIndex:indexPath
                                           tableView:tableView];

        RailStationViewCell *railCell = [RailStation
                          tableView:tableView
            cellWithReuseIdentifier:MakeCellId(kAlphaSection)
                          rowHeight:[self tableView:tableView
                                        heightForRowAtIndexPath:indexPath]
                        rightMargin:NO
                        fixedMargin:sectionType == kAlphaSection ? 24.0 : 0.0];

        [railCell
            populateCellWithStation:station.name.safeEscapeForMarkUp
                              lines:[StationData railLines:station.index]];

        cell = railCell;
        break;
    }

    case kSectionRowDisclaimerType:
        cell = [self disclaimerCell:tableView];
        [self updateDisclaimerAccessibility:cell];
        break;
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
    switch ([self sectionType:tableView section:section]) {
    case kAlphaSection:
        return _alphaSections[section].title;

    case kFilterSection:
        return nil;

    case kSectionRowDisclaimerType:
        return nil;
    }

    return nil;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self sectionType:tableView section:indexPath.section]) {
    case kFilterSection:
    case kAlphaSection: {
        RailStation *station = [self stationForIndex:indexPath
                                           tableView:tableView];

        if (station == nil) {
            return;
        }

        RailStationTableViewController *railView =
            [RailStationTableViewController viewController];
        railView.station = station;
        railView.stopIdStringCallback = self.stopIdStringCallback;
        [railView fetchShapesAndDetoursAsync:self.backgroundTask];
    }

    case kSectionRowDisclaimerType:
        break;
    }
}

#pragma mark ReturnStop callbacks

- (void)returnStopObject:(Stop *)stop progress:(id<TaskController>)progress {
    if (self.stopIdStringCallback) {
        [self.stopIdStringCallback returnStopIdString:stop.stopId
                                                 desc:stop.desc];
        return;
    }

    DepartureTimesViewController *departureViewController =
        [DepartureTimesViewController viewController];

    departureViewController.displayName = stop.desc;

    [departureViewController fetchTimesForLocationAsync:progress
                                                 stopId:stop.stopId];
}

- (NSString *)returnStopObjectActionText {
    if (self.stopIdStringCallback) {
        return [self.stopIdStringCallback returnStopIdStringActionText];
    }

    return @"";
}

@end
