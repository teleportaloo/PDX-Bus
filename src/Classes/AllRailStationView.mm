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
#include <stdlib.h>
#include "StringHelper.h"

#ifdef CREATE_MAX_ARRAYS
static RAILLINES createRailLines0[MAXHOTSPOTS];
static RAILLINES createRailLines1[MAXHOTSPOTS];
static STOP_TO_HOTSPOT stopToHotspot2[MAXHOTSPOTS * 3];
#endif

// Machine generated static data structures are used for the search

#include "StaticStationData.m"


@implementation AllRailStationView

- (instancetype)init
{
    if ((self = [super init]))
    {
        _hotSpots = [RailMapView hotspots];
        [RailMapView initHotspotData];
        self.title = NSLocalizedString(@"All Rail Stations", @"screen title");
        
        self.searchableItems = [NSMutableArray array];
        
#ifndef CREATE_MAX_ARRAYS
        for (int i=0; i< sizeof(stationsAlpha)/sizeof(int);  i++)
        {
            RailStation *station = [RailStation fromHotSpot:_hotSpots+stationsAlpha[i] index:stationsAlpha[i]];
            
            [self.searchableItems addObject:station];
    
        }
        
        self.enableSearch = YES;
#endif
    }
    return self;
}

- (void)addLineToDescription:(NSMutableString *)desc line:(RAILLINES)line station:(RAILLINES)station name:(NSString *)name
{
    if ((station & line) !=0)
    {
        if (desc.length >0)
        {
            [desc appendString:@", "];
        }
        
        [desc appendString:name];
    }
}

- (void)indexStations
{
    Class searchClass = (NSClassFromString(@"CSSearchableIndex"));
    
    if (searchClass == nil || ![CSSearchableIndex isIndexingAvailable])
    {
        return;
    }
    
    CSSearchableIndex * searchableIndex = [CSSearchableIndex defaultSearchableIndex];
    
    
    [searchableIndex deleteSearchableItemsWithDomainIdentifiers:@[ @"station" ] completionHandler:^(NSError * __nullable error)
     {
         @autoreleasepool {
             
             if (error != nil)
             {
                 ERROR_LOG(@"Failed to delete station index %@\n", error.description);
             }
             
             if ([UserPrefs sharedInstance].searchStations)
             {
                 NSMutableArray *index = [NSMutableArray array];
                 for (int i=0; i< sizeof(stationsAlpha)/sizeof(int);  i++)
                 {
                     RailStation *station = [[RailStation alloc] initFromHotSpot:self->_hotSpots+stationsAlpha[i] index:stationsAlpha[i]];
                     NSInteger alpha = stationsAlpha[i];
                     RAILLINES lines = railLines0[alpha] | railLines1[alpha];
                     
                     
                     CSSearchableItemAttributeSet * attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString*)kUTTypeText];
                     attributeSet.title = station.station;
                     
                     NSMutableString *desc = [NSMutableString string];
                     
                     for (PC_ROUTE_INFO info = [TriMetInfo allColoredLines]; info->route_number!=kNoRoute; info++)
                     {
                         [self addLineToDescription:desc line:info->line_bit station:lines name:info->full_name];
                     }
                     
                     attributeSet.contentDescription = [NSString stringWithFormat:@"TriMet station serving %@", desc];
                     
                     NSString *uniqueId = [NSString stringWithFormat:@"%@:%d", kSearchItemStation, stationsAlpha[i]];
                     
                     CSSearchableItem * item = [[CSSearchableItem alloc] initWithUniqueIdentifier:uniqueId domainIdentifier:@"station" attributeSet:attributeSet];
                     
                     [index addObject:item];
                     
                 }
                 
                 [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:index completionHandler: ^(NSError * __nullable error) {
                     if (error != nil)
                     {
                         ERROR_LOG(@"Failed to index stations %@\n", error.description);
                     }
                 }];
             }
         }
         
     }];

}


- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    [toolbarItems addObject:[UIToolbar mapButtonWithTarget:self action:@selector(showMap:)]];
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

-(void)showMap:(id)sender
{
    StopLocations *locationsDb = [StopLocations getDatabase];
    
    if (locationsDb.isEmpty)
    {
        return;
    }
    
    
    int i,j;
    CLLocation *here;
    NSArray *items = [self topViewData];
    
    MapViewController *mapPage = [MapViewController viewController];
    
    for (i=0; i< items.count;  i++)
    {
        //if (_hotSpots[stationsAlpha[i]].action[0]==kLinkTypeStop)
        {
            RailStation *station = items[i];
            
            // NSString *stop = nil;
            NSString *dir = nil;
            NSString *locId = nil;
            
            for (j=0; j< station.dirList.count; j++)    
            {
                dir = station.dirList[j];
                locId = station.locList[j];
                
                here = [locationsDb getLocation:locId];
                
                if (here)
                {
                    Stop *a = [Stop data];
                    
                    a.locid = locId;
                    a.desc  = station.station;
                    a.dir   = dir;
                    a.lat   = [NSString stringWithFormat:@"%f", here.coordinate.latitude];
                    a.lng   = [NSString stringWithFormat:@"%f", here.coordinate.longitude];
                    a.callback = self;
                
                    [mapPage addPin:a];
                }
            }
        }
        
    }
    
    mapPage.callback = self.callback;
    
    [self.navigationController pushViewController:mapPage animated:YES];
}


+ (RAILLINES)railLines:(int)index
{
    return railLines0[index] | railLines1[index];
}

+ (RAILLINES)railLines0:(int)index
{
    return railLines0[index];
}

+ (RAILLINES)railLines1:(int)index
{
    return railLines1[index];
}


#define kAlphaSection      0
#define kFilterSection     1

- (int)sectionType:(UITableView *)tableView section:(NSInteger)section
{
    if (tableView == self.table)
    {        
        if (section < ALPHA_SECTIONS_CNT)
        {
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



- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView 
{
    if (tableView == self.table)
    {
        NSMutableArray *titles = [NSMutableArray array];
        
        [titles addObject:UITableViewIndexSearch];
    
        for (int i=0; i<ALPHA_SECTIONS_CNT; i++)
        {
            [titles addObject:[NSString stringWithFormat:@"%s", alphaSections[i].title]];
        }
    
        return titles;
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index 
{
    if (title == UITableViewIndexSearch) {
        [tableView scrollRectToVisible:self.searchController.searchBar.frame animated:NO];
        return -1;
    }
    
    return index-1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if (tableView == self.table)
    {
        return sizeof(alphaSections)/sizeof(alphaSections[0])+1;
    }
    return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ([self sectionType:tableView section:indexPath.section])
    {
        case kAlphaSection:
            return [self basicRowHeight];
        case kSectionRowDisclaimerType:
            return kDisclaimerCellHeight;
        case kFilterSection:
            return [self basicRowHeight];
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    switch ([self sectionType:tableView section:section])
    {
        case kAlphaSection:
            return alphaSections[section].items;
        case kSectionRowDisclaimerType:
            return 1;
        case kFilterSection:
            return [self filteredData:tableView].count;
    }
    return 0;
}

- (RailStation *)stationForIndex:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    RailStation *station = nil;

    switch ([self sectionType:tableView section:indexPath.section])
    {
        case kAlphaSection:
            {
                int offset = alphaSections[indexPath.section].offset+(int)indexPath.row;
                station = self.searchableItems[offset];
            }        
            break;
        case kSectionRowDisclaimerType:
            break;
        case kFilterSection:
        {
            NSArray *items = [self filteredData:tableView];
            if (indexPath.row < items.count)
            {
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
    switch (sectionType)
    {
        case kAlphaSection:
        case kFilterSection:
        {
            RailStation * station = [self stationForIndex:indexPath tableView:tableView];
            
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
    switch ([self sectionType:tableView section:section])
    {
        case kAlphaSection:
            return [NSString stringWithFormat:@"%s", alphaSections[section].title];
        case kFilterSection:
            return nil;
        case kSectionRowDisclaimerType:
            return nil;
    }
    
    return nil;
}




- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    switch ([self sectionType:tableView section:indexPath.section])
    {
        case kFilterSection:
        case kAlphaSection:
        {
            RailStation * station = [self stationForIndex:indexPath tableView:tableView];
            
            if (station == nil)
            {
                return;
            }
            
            RailStationTableView *railView = [RailStationTableView viewController];
            railView.station = station; 
            railView.callback = self.callback;
            // railView.from = self.from;
            railView.locationsDb = [StopLocations getDatabase];
            [railView maybeFetchRouteShapesAsync:self.backgroundTask];
        }    
        
        case kSectionRowDisclaimerType:
            break;
    }
}

#pragma mark ReturnStop callbacks

- (void) chosenStop:(Stop *)stop progress:(id<BackgroundTaskController>) progress
{
    if (self.callback)
    {
        
        
        if ([self.callback respondsToSelector:@selector(selectedStop:desc:)])
        {
            [self.callback selectedStop:stop.locid desc:stop.desc];
        }
        else 
        {
            [self.callback selectedStop:stop.locid];
        }

        
        return;
    }
    
    DepartureTimesView *departureViewController = [DepartureTimesView viewController];
    
    departureViewController.displayName = stop.desc;
    
    [departureViewController fetchTimesForLocationAsync:progress loc:stop.locid];
    
}

- (NSString *)actionText
{
    if (self.callback)
    {
        return [self.callback actionText];
    }
    return NSLocalizedString(@"Show arrivals", @"button text");
}

#pragma mark Data Creation Methods - not used at runtime


#ifdef CREATE_MAX_ARRAYS

- (void)addLine:(RAILLINES)line route:(NSString*)route direction:(NSString*)direction stations:(NSArray *)stations query:(NSString *)query raillines:(RAILLINES*)lines
{
    int i,j,k;
    
    XMLStops *xml = [XMLStops xml];
    xml.staticQuery = query;
    
    [xml getStopsForRoute:route direction:direction  
              description:@"" cacheAction:TriMetXMLNoCaching];
    
     StopLocations *db = [StopLocations getDatabase];
    
    for (i=0; i< xml.items.count; i++)
    {
        Stop *stop = xml.items[i];
        
        [db insert:[stop.locid intValue] lat:[stop.lat doubleValue] lng:[stop.lng doubleValue] rail:YES];
        
        for (j=0; j< stations.count; j++)
        {
            RailStation *r = stations[j];
            
            for (k=0; k < r.locList.count; k++)
            {
                NSString *loc = r.locList[k];
                
                if ([stop.locid isEqualToString:loc])
                {
                    lines[r.index] |= line;
                    break;
                }
            }
        }
    }
    
}

- (NSString *)directionForStop:(NSString *)stop
{
    XMLDepartures *dep = [XMLDepartures xml];
    
    [dep getDeparturesForLocation:stop];
    
    return dep.locDir;
}

- (void)addStreetcar:(RAILLINES)line route:(NSString*)route direction:(NSString*)direction stations:(NSMutableArray *)streetcarStops
{
    XMLStops *xml = [XMLStops xml];
    
    [xml getStopsForRoute:route direction:direction  
              description:@"" cacheAction:TriMetXMLNoCaching];
    
    for (Stop *stop in xml.items)
    {
        RailStation *found = nil;
        // see if station exists
        for (RailStation * r in streetcarStops)
        {
            if ([r.station isEqualToString:stop.desc])
            {
                found = r;
                break;
            }
        }
        if (!found)
        {
            found = [[RailStation alloc] init];
            found.station = stop.desc;
            found.locList = [NSMutableArray array];
            found.dirList = [NSMutableArray array];
            
            [found.locList addObject:stop.locid];
            [found.dirList addObject:[self directionForStop:stop.locid]];
            
            [streetcarStops addObject:found];
        }
        else {
            NSString *loc = nil;
            int i = 0;
            for (i=0; i < found.locList.count; i++)
            {
                loc = found.locList[i];
                if ([loc isEqualToString:stop.locid])
                {
                    break;
                }
            }
            
            if (i == found.locList.count)
            {
                [found.locList addObject:stop.locid];
                [found.dirList addObject:[self directionForStop:stop.locid]];
            }
        }
    }
    
}
#endif


int compareStopToHotspots(const void *first, const void *second)
{    
    return (int)(((STOP_TO_HOTSPOT*)first)->stopId - ((STOP_TO_HOTSPOT*)second)->stopId);
}

+ (RailStation *)railstationFromStopId:(NSString *)stopId
{
    [RailMapView initHotspotData];
    
    RailStation *res = nil;
    STOP_TO_HOTSPOT key = { (long)stopId.longLongValue, 0 };
    
    STOP_TO_HOTSPOT *result = (STOP_TO_HOTSPOT*)bsearch(&key, stopToHotSpot, sizeof(stopToHotSpot)/sizeof(stopToHotSpot[0]), sizeof(stopToHotSpot[0]), compareStopToHotspots);
    
    if (result)
    {
        HOTSPOT *hotspots = [RailMapView hotspots];

        res = [RailStation fromHotSpot:hotspots+(result->hotspot) index:result->hotspot];
    }
    return res;
}

- (void)generateArrays
{
#ifdef CREATE_MAX_ARRAYS 
    CODE_LOG(@"\n-------------------------------------------------------\n"
               @"-     Creating Static Arrays of Rail Stations         -\n"
               @"-------------------------------------------------------\n\n");
    
    
    [RailMapView initHotspotData];
    
    NSMutableArray<RailStation*> *stations = [NSMutableArray array];
    
    int i;
    
    int nHotSpots = [RailMapView nHotspots];
    HOTSPOT *hotSpotRegions = [RailMapView hotspots];
    
    
    for (i=0; i<nHotSpots; i++)
    {
        if (hotSpotRegions[i].action.firstUnichar == kLinkTypeStop)
        {
            [stations addObject:[RailStation fromHotSpot:hotSpotRegions+i index:i]];
        }
    }
    
    [stations sortUsingSelector:@selector(compareUsingStation:)];
    
    NSMutableString *res = [NSMutableString string];
    
    [res appendString:@"\nint const stationsAlpha[]={\n"];
    for (i=0; i<stations.count; i++)
    {
        [res appendFormat:@"\t0x%03x, \t/* %@ */\n", stations[i].index, stations[i].station];
    }
    [res appendString:@"};\n"];
    
    CODE_LOG(@"\n--------\nStation Names in Alphabetical Order\n--------\n%@\n\n", res);
    
    StopLocations *db = [StopLocations getWritableDatabase];
    
    [db clear];
    
    NSString *routeNumber = nil;
    
    for (PC_ROUTE_INFO routeInfo = [TriMetInfo allColoredLines]; routeInfo->route_number!= kNoRoute; routeInfo++)
    {
        routeNumber = [TriMetInfo routeString:routeInfo];
        
        [self addLine:routeInfo->line_bit route:routeNumber direction:@"0" stations:stations query:nil raillines:createRailLines0];
        
        if (routeInfo->opposite == kDir1)
        {
            [self addLine:routeInfo->line_bit route:routeNumber direction:@"1" stations:stations query:nil raillines:createRailLines1];
        }
    }
    
    [db close];
    
    
    NSMutableString *res1 = [NSMutableString string];
    
    [res1 appendString:@"\nstatic const RAILLINES railLines0[]={\n"];
    for (i=0; i<nHotSpots; i++)
    {
        [res1 appendFormat:@"\t0x%04x,\t", createRailLines0[i]];
        for (RailStation *r in stations)
        {
            if (r.index == i)
            {
                [res1 appendFormat:@"/* %@ */", r.station];
                break;
            }
        }
        [res1 appendFormat:@"\n"];
    }
    [res1 appendString:@"};\n"];
    
    [res1 appendString:@"\nstatic const RAILLINES railLines1[]={\n"];
    for (i=0; i<nHotSpots; i++)
    {
        [res1 appendFormat:@"\t0x%04x,\t", createRailLines1[i]];
        for (RailStation *r in stations)
        {
            if (r.index == i)
            {
                [res1 appendFormat:@"/* %@ */", r.station];
                break;
            }
        }
        [res1 appendFormat:@"\n"];
    }
    [res1 appendString:@"};\n"];
    
    
    CODE_LOG(@"\n--------\nLine colors for each station\n--------\n%@\n\n", res1);
    
    NSMutableString *res3 = [NSMutableString string];
    
    [res3 appendFormat:@"\nstatic const ALPHA_SECTIONS alphaSections[]={\n"];
    
    RailStation *r = stations[0];
    NSString * title = [NSString stringWithFormat:@"%c", [r.station characterAtIndex:0]];
    NSString * next = nil;
    int offset = 0;
    int count = 1;
    
    NSArray * specialCases = @[@"NW", @"NE", @"SW", @"SE", @"NE"];
    
    for(i=1; i< stations.count; i++)
    {
        r = [stations objectAtIndex:i];
        
        next = nil;
        
        for (NSString *prefix in specialCases)
        {
            if (prefix.length <= r.station.length)
            {
                NSString *sub = [r.station substringToIndex:prefix.length];
                if ([prefix isEqualToString:sub])
                {
                    next = prefix;
                }
            }
        }
        
        if (next == nil)
        {
            next = [NSString stringWithFormat:@"%c", [r.station characterAtIndex:0]];
        }
        if (![next isEqualToString:title])
        {
            [res3 appendFormat:@"\t{ \"%@\", %d, %d},\n", title, offset, count];
            title = next;
            offset = i;
            count = 1;
        }
        else 
        {
            count++;
        }
    }
    
    [res3 appendFormat:@"\t{ \"%@\", %d, %d},\n", title, offset, count];
    
    [res3 appendFormat:@"};\n"];
    CODE_LOG(@"\n--------\nTable Sections\n--------\n%@\n\n", res3);
    
    int stops = 0;
    for (RailStation *rs in stations)
    {
        for (NSString *loc in rs.locList)
        {
            stopToHotspot2[stops].stopId = loc.intValue;
            stopToHotspot2[stops].hotspot = rs.index;
            stops++;
        }
    }
    
    qsort(stopToHotspot2, stops, sizeof(stopToHotspot2[0]), compareStopToHotspots);
          
    NSMutableString *res4 = [NSMutableString string];
          
    [res4 appendString:@"\nstatic const STOP_TO_HOTSPOT stopToHotSpot[]={\n"];
          
    for (i=0; i<stops; i++)
    {
        [res4 appendFormat:@"\t{ %d, %d},\n", (int)stopToHotspot2[i].stopId, (int)stopToHotspot2[i].hotspot];
    }
          
    [res4 appendFormat:@"};\n"];
          
    
    CODE_LOG(@"\n--------\nStopIDs to hot spots\n--------\n%@\n\n", res4);

    
#endif
}


@end

