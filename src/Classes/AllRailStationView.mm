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

#import "Hotspot.h"
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

#define kSearchDataSection 0
#define kSearchDisclaimerSection 1

#ifdef CREATE_MAX_ARRAYS
static RAILLINES railLines2[MAXHOTSPOTS];
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
         if (error != nil)
         {
             ERROR_LOG(@"Failed to delete station index %@\n", error.description);
         }
         
         if ([UserPrefs singleton].searchStations)
         {
             NSMutableArray *index = [NSMutableArray array];
             for (int i=0; i< sizeof(stationsAlpha)/sizeof(int);  i++)
             {
                 RailStation *station = [[RailStation alloc] initFromHotSpot:_hotSpots+stationsAlpha[i] index:stationsAlpha[i]];
                 RAILLINES lines = railLines[stationsAlpha[i]];
                 
                 
                 CSSearchableItemAttributeSet * attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString*)kUTTypeText];
                 attributeSet.title = station.station;
                 
                 NSMutableString *desc = [NSMutableString string];
                 
                 [self addLineToDescription:desc line:kBlueLine          station:lines name:@"MAX Blue Line"];
                 [self addLineToDescription:desc line:kRedLine           station:lines name:@"MAX Red Line"];
                 [self addLineToDescription:desc line:kGreenLine         station:lines name:@"MAX Green Line"];
                 [self addLineToDescription:desc line:kYellowLine        station:lines name:@"MAX Yellow Line"];
                 [self addLineToDescription:desc line:kStreetcarALoop    station:lines name:@"Streetcar A Loop"];
                 [self addLineToDescription:desc line:kStreetcarBLoop    station:lines name:@"Streetcar B Loop"];
                 [self addLineToDescription:desc line:kStreetcarNsLine   station:lines name:@"Streetcar NS Line"];
                 [self addLineToDescription:desc line:kWesLine           station:lines name:@"WES"];
                 [self addLineToDescription:desc line:kOrangeLine        station:lines name:@"MAX Orange Line"];
                 
                 
                 attributeSet.contentDescription = [NSString stringWithFormat:@"TriMet station serving %@", desc];
                 
                 NSString *uniqueId = [NSString stringWithFormat:@"%@:%d", kSearchItemStation, stationsAlpha[i]];
                 
                 CSSearchableItem * item = [[CSSearchableItem alloc] initWithUniqueIdentifier:uniqueId domainIdentifier:@"station" attributeSet:attributeSet];
                 
                 [index addObject:item];
                 
                 [item release];
                 [attributeSet release];
                 [station release];
             }
             
             [[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:index completionHandler: ^(NSError * __nullable error) {
                 if (error != nil)
                 {
                     ERROR_LOG(@"Failed to index stations %@\n", error.description);
                 }
             }];
         }
         
     }];

}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self reloadData];
}


- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
	[toolbarItems addObject:[UIToolbar autoMapButtonWithTarget:self action:@selector(showMap:)]];
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
	return railLines[index];
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
	
	if (section == 0)
	{
		return kFilterSection;
	}
	return kSectionRowDisclaimerType;
	
}



#pragma mark TableView methods

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	[self reloadData];
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
	return 2;
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
			NSString *stopId = [NSString stringWithFormat:@"stop%f", self.screenInfo.appWinWidth];
				
			cell = [tableView dequeueReusableCellWithIdentifier:stopId];
			if (cell == nil) {
					
				cell = [RailStation tableviewCellWithReuseIdentifier:stopId 
															rowHeight:[self tableView:tableView heightForRowAtIndexPath:indexPath] 
														 screenWidth:self.screenInfo.screenWidth
														 rightMargin:(sectionType == kAlphaSection)
																font:self.basicFont];
					
			}
			[RailStation populateCell:cell 
							  station:station.station
								lines:railLines[station.index]];
				
				//	DEBUG_LOG(@"Section %d row %d offset %d index %d name %@ line %x\n", indexPath.section,
				//				  indexPath.row, offset, index, [RailStation nameFromHotspot:_hotSpots+index], railLines[index]);
			break;
		}
			
		case kSectionRowDisclaimerType:
			cell = [tableView dequeueReusableCellWithIdentifier:kDisclaimerCellId];
			if (cell == nil) {
				cell = [self disclaimerCellWithReuseIdentifier:kDisclaimerCellId];
			}
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
			[self.navigationController pushViewController:railView animated:YES];
		}	
		
		case kSectionRowDisclaimerType:
			break;
	}
}

#pragma mark ReturnStop callbacks

- (void) chosenStop:(Stop *)stop progress:(id<BackgroundTaskProgress>) progress
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

- (void)addLine:(RAILLINES)line route:(NSString*)route direction:(NSString*)direction stations:(NSArray *)stations query:(NSString *)query
{
	int i,j,k;
	
    XMLStops *xml = [XMLStops xml];
    xml.staticQuery = query;
	
	[xml getStopsForRoute:route direction:direction  
			  description:@"" cacheAction:TriMetXMLNoCaching];
    
 	StopLocations *db = [StopLocations getDatabase];
	
	for (i=0; i< xml.itemArray.count; i++)
	{
		Stop *stop = xml.itemArray[i];
		
		[db insert:[stop.locid intValue] lat:[stop.lat doubleValue] lng:[stop.lng doubleValue] rail:YES];
		
		for (j=0; j< stations.count; j++)
		{
			RailStation *r = stations[j];
			
			for (k=0; k < r.locList.count; k++)
			{
				NSString *loc = r.locList[k];
				
				if ([stop.locid isEqualToString:loc])
				{
					railLines2[r.index] |= line;
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
    
	for (Stop *stop in xml.itemArray)
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
			found = [[[RailStation alloc] init] autorelease];
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
	
// #ifdef MAKE_STREETCAR_LIST
#if 0
	NSMutableArray *streetcarStops = [[[NSMutableArray alloc] init] autorelease];
	
	[self addStreetcar:kStreetcarNsLine route:@"193" direction:@"0" stations:streetcarStops];
	[self addStreetcar:kStreetcarNsLine route:@"193" direction:@"1" stations:streetcarStops];
    [self addStreetcar:kStreetcarClLine route:@"194" direction:@"0" stations:streetcarStops];
	[self addStreetcar:kStreetcarClLine route:@"194" direction:@"1" stations:streetcarStops];
	
	NSMutableString * res0 = [NSMutableString string];
	
	[res0 appendString:@"\n"];
	
	for (RailStation * r in streetcarStops)
	{
		[res0 appendFormat:@"\tNULL_HOTSPOT(\"%@\");\n", [r url]];
	}
	
	CODE_LOG(@"\n--------\nStreetcar Station Data\n--------%@\n\n", res0);
#endif
	
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
	
	[self addLine:kRedLine route:@"90" direction:@"0" stations:stations query:nil];
	[self addLine:kRedLine route:@"90" direction:@"1" stations:stations query:nil];
	
	[self addLine:kBlueLine route:@"100" direction:@"0" stations:stations query:nil];
	[self addLine:kBlueLine route:@"100" direction:@"1" stations:stations query:nil];
	
	[self addLine:kYellowLine route:@"190" direction:@"0" stations:stations query:nil];
	[self addLine:kYellowLine route:@"190" direction:@"1" stations:stations query:nil];
	
	[self addLine:kGreenLine route:@"200" direction:@"0" stations:stations query:nil];
	[self addLine:kGreenLine route:@"200" direction:@"1" stations:stations query:nil];
	
	[self addLine:kWesLine route:@"203" direction:@"0" stations:stations query:nil];
	[self addLine:kWesLine route:@"203" direction:@"1" stations:stations query:nil];
	
	[self addLine:kStreetcarNsLine route:@"193" direction:@"0" stations:stations query:nil];
	[self addLine:kStreetcarNsLine route:@"193" direction:@"1" stations:stations query:nil];
    
    [self addLine:kStreetcarALoop  route:@"194" direction:@"0" stations:stations query:nil];
	[self addLine:kStreetcarBLoop  route:@"195" direction:@"0" stations:stations query:nil];
    
    [self addLine:kOrangeLine route:@"290" direction:@"0" stations:stations query:nil];
    [self addLine:kOrangeLine route:@"290" direction:@"1" stations:stations query:nil];
	
	[db close];
	
	
	NSMutableString *res1 = [NSMutableString string];
	
	[res1 appendString:@"\nstatic const RAILLINES railLines[]={\n"];
	for (i=0; i<nHotSpots; i++)
	{
		[res1 appendFormat:@"\t0x%04x,\t", railLines2[i]];
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
            if ([[r.station substringToIndex:prefix.length] isEqualToString:prefix])
            {
                next = prefix;
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

