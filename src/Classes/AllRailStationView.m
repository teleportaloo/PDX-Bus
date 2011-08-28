//
//  AllRailStationView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/5/10.
//  Copyright 2010. All rights reserved.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import "AllRailStationView.h"
#import "DepartureTimesView.h"

#ifdef ALL_RAIL_STATIONS


#import "Hotspot.h"
#import "RailStation.h"
#import "RailStationTableView.h"
#import "XMLStops.h"
#import "RailMapView.h"
#import "XMLDepartures.h"
#import "MapViewController.h"
#import "debug.h"

#define kSearchDataSection 0
#define kSearchDisclaimerSection 1

#ifdef CREATE_MAX_ARRAYS
static RAILLINES railLines2[MAXHOTSPOTS];
#endif

// 
// These arrays are actually machine generated from the hotspot data from the map.  If you build with CREATE_MAX_ARRAYS
// the software will generate a new set of this data from new hotspot data.  You have to copy it into this code from the
// console and and everything will just work again.
//
// This only needs to be done if a new rail station opens or a new line is added.
//

// 
// This is an index into the hotspot arrays of the stations in alphabetical order, this is calculated
// by the software so the developer does not have to!
//

int stationsAlpha[]={
	0x042, 	/* Albina/Mississippi */
	0x094, 	/* Art Museum */
	0x00d, 	/* Beaverton Central */
	0x00b, 	/* Beaverton Creek */
	0x00e, 	/* Beaverton TC */
	0x04d, 	/* Cascades */
	0x095, 	/* Central Library */
	0x031, 	/* City Hall/SW 5th & Jefferson St */
	0x05f, 	/* Civic Drive */
	0x056, 	/* Clackamas Town Center TC */
	0x062, 	/* Cleveland Ave */
	0x045, 	/* Convention Center */
	0x03b, 	/* Delta Park/Vanport */
	0x057, 	/* E 102nd Ave */
	0x058, 	/* E 122nd Ave */
	0x059, 	/* E 148th Ave */
	0x05a, 	/* E 162nd Ave */
	0x05b, 	/* E 172nd */
	0x05c, 	/* E 181st */
	0x009, 	/* Elmonica/SW 170th Ave */
	0x03a, 	/* Expo Center */
	0x004, 	/* Fair Complex/Hillsboro Airport */
	0x01e, 	/* Galleria/SW 10th */
	0x01c, 	/* Gateway/NE 99th TC */
	0x018, 	/* Goose Hollow/SW Jefferson St */
	0x061, 	/* Gresham Central TC */
	0x060, 	/* Gresham City Hall */
	0x012, 	/* Hall/Nimbus */
	0x000, 	/* Hatfield Government Center */
	0x005, 	/* Hawthorn Farm */
	0x001, 	/* Hillsboro Central/SE 3rd TC */
	0x048, 	/* Hollywood/NE 42nd Ave */
	0x043, 	/* Interstate/Rose Quarter */
	0x01a, 	/* JELD-WEN Field (PGE Park) */
	0x03c, 	/* Kenton/N Denver */
	0x019, 	/* Kings Hill/SW Salmon St */
	0x053, 	/* Lents/SE Foster Rd */
	0x021, 	/* Library/SW 9th Ave */
	0x047, 	/* Lloyd Center/NE 11th Ave */
	0x032, 	/* Mall/SW 4th Ave */
	0x02e, 	/* Mall/SW 5th Ave */
	0x00a, 	/* Merlo Rd/SW 158th Ave */
	0x00c, 	/* Millikan Way */
	0x02f, 	/* Morrison/SW 3rd Ave */
	0x04c, 	/* Mt Hood Ave */
	0x03f, 	/* N Killingsworth */
	0x03d, 	/* N Lombard TC */
	0x040, 	/* N Prescott */
	0x049, 	/* NE 60th Ave */
	0x046, 	/* NE 7th Ave */
	0x04a, 	/* NE 82nd Ave */
	0x098, 	/* NW 10th & Couch */
	0x099, 	/* NW 10th & Everett */
	0x09a, 	/* NW 10th & Glisan */
	0x09b, 	/* NW 10th & Johnson */
	0x09c, 	/* NW 10th & Marshall */
	0x0aa, 	/* NW 11th & Couch */
	0x0a9, 	/* NW 11th & Everett */
	0x0a8, 	/* NW 11th & Glisan */
	0x0a7, 	/* NW 11th & Johnson */
	0x09d, 	/* NW 12th & Northrup */
	0x0a2, 	/* NW 23rd & Marshall */
	0x02b, 	/* NW 5th & Couch St */
	0x027, 	/* NW 6th & Davis St */
	0x0a6, 	/* NW Lovejoy & 13th */
	0x0a5, 	/* NW Lovejoy & 18th */
	0x0a4, 	/* NW Lovejoy & 21st */
	0x0a3, 	/* NW Lovejoy & 22nd */
	0x09e, 	/* NW Northrup & 14th */
	0x09f, 	/* NW Northrup & 18th */
	0x0a0, 	/* NW Northrup & 21st */
	0x0a1, 	/* NW Northrup & 22nd */
	0x08b, 	/* OHSU Commons */
	0x036, 	/* Oak/SW 1st Ave */
	0x034, 	/* Old Town/Chinatown */
	0x006, 	/* Orenco/NW 231st Ave */
	0x041, 	/* Overlook Park */
	0x091, 	/* PSU Urban Center */
	0x030, 	/* PSU/SW 5th & Mill St */
	0x024, 	/* PSU/SW 6th & Montgomery */
	0x04e, 	/* Parkrose/Sumner TC */
	0x020, 	/* Pioneer Courthouse/SW 6th Ave */
	0x02c, 	/* Pioneer Place/SW 5th Ave */
	0x01f, 	/* Pioneer Square North */
	0x022, 	/* Pioneer Square South */
	0x04b, 	/* Portland Int'l Airport */
	0x007, 	/* Quatama/NW 205th Ave */
	0x05d, 	/* Rockwood/E 188th Ave TC */
	0x03e, 	/* Rosa Parks */
	0x044, 	/* Rose Quarter TC */
	0x05e, 	/* Ruby Junction/E 197th Ave */
	0x050, 	/* SE Division St */
	0x054, 	/* SE Flavel St */
	0x055, 	/* SE Fuller Rd */
	0x052, 	/* SE Holgate Blvd */
	0x04f, 	/* SE Main St */
	0x051, 	/* SE Powell Blvd */
	0x096, 	/* SW 10th & Alder */
	0x093, 	/* SW 10th & Clay */
	0x097, 	/* SW 10th & Stark */
	0x0ab, 	/* SW 11th & Alder */
	0x0ae, 	/* SW 11th & Clay */
	0x0ad, 	/* SW 11th & Jefferson */
	0x0ac, 	/* SW 11th & Taylor */
	0x08f, 	/* SW 1st & Harrison */
	0x090, 	/* SW 3rd & Harrison */
	0x0b0, 	/* SW 5th & Market */
	0x0b1, 	/* SW 5th & Montgomery */
	0x02d, 	/* SW 5th & Oak St */
	0x023, 	/* SW 6th & Madison St */
	0x028, 	/* SW 6th & Pine St */
	0x08a, 	/* SW Bond & Lane */
	0x08e, 	/* SW Harrison Street */
	0x089, 	/* SW Lowell & Bond */
	0x0b2, 	/* SW Moody & Gaines */
	0x08c, 	/* SW Moody & Gibbs */
	0x0af, 	/* SW Park & Market */
	0x092, 	/* SW Park & Mill */
	0x08d, 	/* SW River Pkwy & Moody */
	0x035, 	/* Skidmore Fountain */
	0x016, 	/* Sunset TC */
	0x013, 	/* Tigard TC */
	0x014, 	/* Tualatin */
	0x002, 	/* Tuality Hospital/SE 8th Ave */
	0x02a, 	/* Union Station/NW 5th & Glisan St */
	0x026, 	/* Union Station/NW 6th & Hoyt St */
	0x017, 	/* Washington Park */
	0x003, 	/* Washington/SE 12th Ave */
	0x008, 	/* Willow Creek/SW 185th Ave TC */
	0x015, 	/* Wilsonville */
	0x033, 	/* Yamhill District */
};

//
// These are the colours for the lines of each rail station in the hotspot array.  It is calculated by gettng the stops
// for each station and merging them in.  Much easier than doing it by hand!
//

static RAILLINES railLines[]={
	0x02,	/* Hatfield Government Center */
	0x02,	/* Hillsboro Central/SE 3rd TC */
	0x02,	/* Tuality Hospital/SE 8th Ave */
	0x02,	/* Washington/SE 12th Ave */
	0x02,	/* Fair Complex/Hillsboro Airport */
	0x02,	/* Hawthorn Farm */
	0x02,	/* Orenco/NW 231st Ave */
	0x02,	/* Quatama/NW 205th Ave */
	0x02,	/* Willow Creek/SW 185th Ave TC */
	0x03,	/* Elmonica/SW 170th Ave */
	0x03,	/* Merlo Rd/SW 158th Ave */
	0x03,	/* Beaverton Creek */
	0x03,	/* Millikan Way */
	0x03,	/* Beaverton Central */
	0x13,	/* Beaverton TC */
	0x00,	
	0x00,	
	0x00,	
	0x10,	/* Hall/Nimbus */
	0x10,	/* Tigard TC */
	0x10,	/* Tualatin */
	0x10,	/* Wilsonville */
	0x03,	/* Sunset TC */
	0x03,	/* Washington Park */
	0x03,	/* Goose Hollow/SW Jefferson St */
	0x03,	/* Kings Hill/SW Salmon St */
	0x03,	/* JELD-WEN Field (PGE Park) */
	0x00,	
	0x07,	/* Gateway/NE 99th TC */
	0x00,	
	0x03,	/* Galleria/SW 10th */
	0x03,	/* Pioneer Square North */
	0x0c,	/* Pioneer Courthouse/SW 6th Ave */
	0x03,	/* Library/SW 9th Ave */
	0x03,	/* Pioneer Square South */
	0x0c,	/* SW 6th & Madison St */
	0x0c,	/* PSU/SW 6th & Montgomery */
	0x00,	
	0x0c,	/* Union Station/NW 6th & Hoyt St */
	0x0c,	/* NW 6th & Davis St */
	0x0c,	/* SW 6th & Pine St */
	0x00,	
	0x0c,	/* Union Station/NW 5th & Glisan St */
	0x0c,	/* NW 5th & Couch St */
	0x0c,	/* Pioneer Place/SW 5th Ave */
	0x0c,	/* SW 5th & Oak St */
	0x03,	/* Mall/SW 5th Ave */
	0x03,	/* Morrison/SW 3rd Ave */
	0x0c,	/* PSU/SW 5th & Mill St */
	0x0c,	/* City Hall/SW 5th & Jefferson St */
	0x03,	/* Mall/SW 4th Ave */
	0x03,	/* Yamhill District */
	0x03,	/* Old Town/Chinatown */
	0x03,	/* Skidmore Fountain */
	0x03,	/* Oak/SW 1st Ave */
	0x00,	
	0x00,	
	0x00,	
	0x08,	/* Expo Center */
	0x08,	/* Delta Park/Vanport */
	0x08,	/* Kenton/N Denver */
	0x08,	/* N Lombard TC */
	0x08,	/* Rosa Parks */
	0x08,	/* N Killingsworth */
	0x08,	/* N Prescott */
	0x08,	/* Overlook Park */
	0x08,	/* Albina/Mississippi */
	0x08,	/* Interstate/Rose Quarter */
	0x0f,	/* Rose Quarter TC */
	0x07,	/* Convention Center */
	0x07,	/* NE 7th Ave */
	0x07,	/* Lloyd Center/NE 11th Ave */
	0x07,	/* Hollywood/NE 42nd Ave */
	0x07,	/* NE 60th Ave */
	0x07,	/* NE 82nd Ave */
	0x01,	/* Portland Int'l Airport */
	0x01,	/* Mt Hood Ave */
	0x01,	/* Cascades */
	0x01,	/* Parkrose/Sumner TC */
	0x04,	/* SE Main St */
	0x04,	/* SE Division St */
	0x04,	/* SE Powell Blvd */
	0x04,	/* SE Holgate Blvd */
	0x04,	/* Lents/SE Foster Rd */
	0x04,	/* SE Flavel St */
	0x04,	/* SE Fuller Rd */
	0x04,	/* Clackamas Town Center TC */
	0x02,	/* E 102nd Ave */
	0x02,	/* E 122nd Ave */
	0x02,	/* E 148th Ave */
	0x02,	/* E 162nd Ave */
	0x02,	/* E 172nd */
	0x02,	/* E 181st */
	0x02,	/* Rockwood/E 188th Ave TC */
	0x02,	/* Ruby Junction/E 197th Ave */
	0x02,	/* Civic Drive */
	0x02,	/* Gresham City Hall */
	0x02,	/* Gresham Central TC */
	0x02,	/* Cleveland Ave */
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x00,	
	0x20,	/* SW Lowell & Bond */
	0x20,	/* SW Bond & Lane */
	0x20,	/* OHSU Commons */
	0x20,	/* SW Moody & Gibbs */
	0x20,	/* SW River Pkwy & Moody */
	0x20,	/* SW Harrison Street */
	0x20,	/* SW 1st & Harrison */
	0x20,	/* SW 3rd & Harrison */
	0x20,	/* PSU Urban Center */
	0x20,	/* SW Park & Mill */
	0x20,	/* SW 10th & Clay */
	0x20,	/* Art Museum */
	0x20,	/* Central Library */
	0x20,	/* SW 10th & Alder */
	0x20,	/* SW 10th & Stark */
	0x20,	/* NW 10th & Couch */
	0x20,	/* NW 10th & Everett */
	0x20,	/* NW 10th & Glisan */
	0x20,	/* NW 10th & Johnson */
	0x20,	/* NW 10th & Marshall */
	0x20,	/* NW 12th & Northrup */
	0x20,	/* NW Northrup & 14th */
	0x20,	/* NW Northrup & 18th */
	0x20,	/* NW Northrup & 21st */
	0x20,	/* NW Northrup & 22nd */
	0x20,	/* NW 23rd & Marshall */
	0x20,	/* NW Lovejoy & 22nd */
	0x20,	/* NW Lovejoy & 21st */
	0x20,	/* NW Lovejoy & 18th */
	0x20,	/* NW Lovejoy & 13th */
	0x20,	/* NW 11th & Johnson */
	0x20,	/* NW 11th & Glisan */
	0x20,	/* NW 11th & Everett */
	0x20,	/* NW 11th & Couch */
	0x20,	/* SW 11th & Alder */
	0x20,	/* SW 11th & Taylor */
	0x20,	/* SW 11th & Jefferson */
	0x20,	/* SW 11th & Clay */
	0x20,	/* SW Park & Market */
	0x20,	/* SW 5th & Market */
	0x20,	/* SW 5th & Montgomery */
	0x20,	/* SW Moody & Gaines */
};



//
// These are the sections for the rail view screen, only displayed when no searching is happening
//

static ALPHA_SECTIONS alphaSections[]={
	{ 'A', 0, 2},
	{ 'B', 2, 3},
	{ 'C', 5, 7},
	{ 'D', 12, 1},
	{ 'E', 13, 8},
	{ 'F', 21, 1},
	{ 'G', 22, 5},
	{ 'H', 27, 5},
	{ 'I', 32, 1},
	{ 'J', 33, 1},
	{ 'K', 34, 2},
	{ 'L', 36, 3},
	{ 'M', 39, 6},
	{ 'N', 45, 27},
	{ 'O', 72, 5},
	{ 'P', 77, 9},
	{ 'Q', 86, 1},
	{ 'R', 87, 4},
	{ 'S', 91, 30},
	{ 'T', 121, 3},
	{ 'U', 124, 2},
	{ 'W', 126, 4},
	{ 'Y', 130, 1},
};

#define ALPHA_SECTIONS_CNT (sizeof(alphaSections)/sizeof(alphaSections[0]))

@implementation AllRailStationView

- (id)init
{
	if ((self = [super init]))
	{
		_hotSpots = [RailMapView hotspots];
		[RailMapView initHotspotData];
		self.title = @"All Rail Stations";
		
		self.searchableItems = [[[NSMutableArray alloc] init] autorelease];
		
		for (int i=0; i< sizeof(stationsAlpha)/sizeof(int);  i++)
		{
			RailStation *station = [[RailStation alloc] initFromHotSpot:_hotSpots+stationsAlpha[i] index:stationsAlpha[i]];
			
			[self.searchableItems addObject:station];
			
			[station release];
		}
		
		self.enableSearch = YES;
		
	}
	return self;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self reloadData];
}


- (void)createToolbarItems
{
	// match each of the toolbar item's style match the selection in the "UIBarButtonItemStyle" segmented control
	// UIBarButtonItemStyle style = UIBarButtonItemStylePlain;
	
	NSArray *items = nil;
	
	
	items = [NSArray arrayWithObjects: 
			 [self autoDoneButton], 
			 [CustomToolbar autoFlexSpace], 
			 [CustomToolbar autoMapButtonWithTarget:self action:@selector(showMap:)],
			 [CustomToolbar autoFlexSpace],
			 [CustomToolbar autoFlashButtonWithTarget:self action:@selector(flashButton:)],
			 nil];
	
	[self setToolbarItems:items animated:NO];
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
	
	MapViewController *mapPage = [[MapViewController alloc] init];
	
	for (i=0; i< items.count;  i++)
	{
		//if (_hotSpots[stationsAlpha[i]].action[0]==kLinkTypeStop)
		{
			RailStation *station = [items objectAtIndex:i];
			
			// NSString *stop = nil;
			NSString *dir = nil;
			NSString *locId = nil;
			
			for (j=0; j< station.dirList.count; j++)	
			{
				dir = [station.dirList objectAtIndex:j];
				locId = [station.locList objectAtIndex:j];
				
				here = [locationsDb getLocaction:locId];
				
				if (here)
				{
					Stop *a = [[[Stop alloc] init] autorelease];
					
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
	
	[[self navigationController] pushViewController:mapPage animated:YES];
	[mapPage release];	
	
}


+ (RAILLINES)railLines:(int)index
{
	return railLines[index];
}

#define kAlphaSection      0
#define kFilterSection     1
#define kDisclaimerSection 2



- (int)sectionType:(UITableView *)tableView section:(int)section
{
	if (tableView == self.table)
	{		
		if (section < ALPHA_SECTIONS_CNT)
		{
			return kAlphaSection;
		}
		return kDisclaimerSection;
	}
	
	if (section == 0)
	{
		return kFilterSection;
	}
	return kDisclaimerSection;
	
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
		NSMutableArray *titles = [[[NSMutableArray alloc] init] autorelease];
		
		[titles addObject:UITableViewIndexSearch];
	
		for (int i=0; i<ALPHA_SECTIONS_CNT; i++)
		{
			[titles addObject:[NSString stringWithFormat:@"%c", alphaSections[i].title]];
		}
	
		return titles;
	}
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index 
{
	if (title == UITableViewIndexSearch) {
		[tableView scrollRectToVisible:self.searchBar.frame animated:NO];
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
		case kDisclaimerSection:
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
		case kDisclaimerSection:
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
				int offset = alphaSections[indexPath.section].offset+indexPath.row;
				station = [self.searchableItems objectAtIndex:offset];
			}		
			break;
		case kDisclaimerSection:
			break;
		case kFilterSection:
		{
			NSArray *items = [self filteredData:tableView];
			if (indexPath.row < items.count)
			{
				station = [items objectAtIndex:indexPath.row];
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
			NSString *stopId = [NSString stringWithFormat:@"stop%d", [self screenWidth]];
				
			cell = [tableView dequeueReusableCellWithIdentifier:stopId];
			if (cell == nil) {
					
				cell = [RailStation tableviewCellWithReuseIdentifier:stopId 
															rowHeight:[self tableView:tableView heightForRowAtIndexPath:indexPath] 
														 screenWidth:[self screenWidth]
														 rightMargin:(sectionType == kAlphaSection)
																font:[self getBasicFont]];
					
			}
			[RailStation populateCell:cell 
							  station:station.station
								lines:railLines[station.index]];
				
				//	DEBUG_LOG(@"Section %d row %d offset %d index %d name %@ line %x\n", indexPath.section,
				//				  indexPath.row, offset, index, [RailStation nameFromHotspot:_hotSpots+index], railLines[index]);
			break;
		}
			
			
		case kDisclaimerSection:
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
			return [NSString stringWithFormat:@"%c", alphaSections[section].title];
		case kFilterSection:
			return nil;
		case kDisclaimerSection:
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
			
			RailStationTableView *railView = [[RailStationTableView alloc] init];
			railView.station = station; 
			railView.callback = self.callback;
			// railView.from = self.from;
			railView.locationsDb = [StopLocations getDatabase];
			[[self navigationController] pushViewController:railView animated:YES];
			[railView release];
		}	
		
		case kDisclaimerSection:
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
	
	DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
	
	departureViewController.displayName = stop.desc;
	
	[departureViewController fetchTimesForLocationInBackground:progress loc:stop.locid];
	[departureViewController release];
	
}

- (NSString *)actionText
{
	if (self.callback)
	{
		return [self.callback actionText];
	}
	return @"Show arrivals";
}

#pragma mark Data Creation Methods - not used at runtime


#ifdef CREATE_MAX_ARRAYS

- (void)addLine:(RAILLINES)line route:(NSString*)route direction:(NSString*)direction stations:(NSArray *)stations
{
	int i,j,k;
	
	XMLStops *xml = [[[XMLStops alloc] init] autorelease];
	
	NSError *error = nil;
	
	[xml getStopsForRoute:route direction:direction  
			  description:@"" parseError:&error cacheAction:TriMetXMLNoCaching];
	
	StopLocations *db = [StopLocations getDatabase];
	
	for (i=0; i< xml.itemArray.count; i++)
	{
		Stop *stop = [xml.itemArray objectAtIndex:i];
		
		[db insert:[stop.locid intValue] lat:[stop.lat doubleValue] lng:[stop.lng doubleValue] rail:YES];
		
		for (j=0; j< stations.count; j++)
		{
			RailStation *r = [stations objectAtIndex:j];
			
			for (k=0; k < r.locList.count; k++)
			{
				NSString *loc = [r.locList objectAtIndex:k];
				
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
	XMLDepartures *dep = [[[XMLDepartures alloc] init] autorelease];
	NSError *error = nil;
	
	[dep getDeparturesForLocation:stop parseError:&error];
	
	return dep.locDir;
}

- (void)addStreetcar:(RAILLINES)line route:(NSString*)route direction:(NSString*)direction stations:(NSMutableArray *)streetcarStops
{
	XMLStops *xml = [[[XMLStops alloc] init] autorelease];
	
	NSError *error = nil;
	
	[xml getStopsForRoute:route direction:direction  
			  description:@"" parseError:&error cacheAction:TriMetXMLNoCaching];
	
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
			found.locList = [[[NSMutableArray alloc] init] autorelease];
			found.dirList = [[[NSMutableArray alloc] init] autorelease];
			
			[found.locList addObject:stop.locid];
			[found.dirList addObject:[self directionForStop:stop.locid]];
			
			[streetcarStops addObject:found];
		}
		else {
			NSString *loc = nil;
			int i = 0;
			for (i=0; i < found.locList.count; i++)
			{
				loc = [found.locList objectAtIndex:i];
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

- (void)generateArrays
{
#ifdef CREATE_MAX_ARRAYS 
	[RailMapView initHotspotData];
	
#ifdef MAKE_STREETCAR_LIST
	NSMutableArray *streetcarStops = [[[NSMutableArray alloc] init] autorelease];
	
	[self addStreetcar:kStreetcarLine route:@"193" direction:@"0" stations:streetcarStops];
	[self addStreetcar:kStreetcarLine route:@"193" direction:@"1" stations:streetcarStops];
	
	NSMutableString * res0 = [[[NSMutableString alloc] init] autorelease];
	
	[res0 appendString:@"\n"];
	
	for (RailStation * r in streetcarStops)
	{
		[res0 appendFormat:@"\tNULL_HOTSPOT(\"%@\");\n", [r url]];
	}
	
	DEBUG_LOG(@"%@", res0);
#endif
	
	NSMutableArray *stations = [[[NSMutableArray alloc] init] autorelease];
	
	int i;
	
	int nHotSpots = [RailMapView nHotspots];
	HOTSPOT *hotSpotRegions = [RailMapView hotspots];
	
	
	for (i=0; i<nHotSpots; i++)
	{
		if (hotSpotRegions[i].action[0] == kLinkTypeStop)
		{
			[stations addObject:[[[RailStation alloc] initFromHotSpot:hotSpotRegions+i index:i] autorelease]];
		}
	}
	
	[stations sortUsingSelector:@selector(compareUsingStation:)];
	
	NSMutableString *res = [[[NSMutableString alloc] init] autorelease];
	
	[res appendString:@"\nint stationsAlpha[]={\n"];
	for (i=0; i<stations.count; i++)
	{
		[res appendFormat:@"\t0x%03x, \t/* %@ */\n", ((RailStation *)[stations objectAtIndex:i]).index,
						((RailStation *)[stations objectAtIndex:i]).station];
	}
	[res appendString:@"};\n"];
	
	DEBUG_LOG(@"%@", res);
	
	StopLocations *db = [StopLocations getDatabase];
	
	[db clear];
	
	[self addLine:kRedLine route:@"90" direction:@"0" stations:stations];
	[self addLine:kRedLine route:@"90" direction:@"1" stations:stations];
	
	[self addLine:kBlueLine route:@"100" direction:@"0" stations:stations];
	[self addLine:kBlueLine route:@"100" direction:@"1" stations:stations];
	
	[self addLine:kYellowLine route:@"190" direction:@"0" stations:stations];
	[self addLine:kYellowLine route:@"190" direction:@"1" stations:stations];
	
	[self addLine:kGreenLine route:@"200" direction:@"0" stations:stations];
	[self addLine:kGreenLine route:@"200" direction:@"1" stations:stations];
	
	[self addLine:kWesLine route:@"203" direction:@"0" stations:stations];
	[self addLine:kWesLine route:@"203" direction:@"1" stations:stations];
	
	[self addLine:kStreetcarLine route:@"193" direction:@"0" stations:stations];
	[self addLine:kStreetcarLine route:@"193" direction:@"1" stations:stations];
	
	// Civic Drive is a special case - add it now by hand - when I made the 
	// stop location database it had been removed from the lines.
	[db insert:13450 lat:45.5079717219104 lng:-122.441301600866 rail:YES];
	[db insert:13449 lat:45.5082978213805 lng:-122.441819427459 rail:YES];
	
	[db close];
	
	
	NSMutableString *res1 = [[[NSMutableString alloc] init] autorelease];
	
	[res1 appendString:@"\nstatic RAILLINES railLines[]={\n"];
	for (i=0; i<nHotSpots; i++)
	{
		[res1 appendFormat:@"\t0x%02x,\t", railLines2[i]];
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
	
	DEBUG_LOG(@"%@", res1);
	
	NSMutableString *res3 = [[[NSMutableString alloc] init] autorelease];
	
	[res3 appendFormat:@"\nstatic ALPHA_SECTIONS alphaSections[]={\n"];
	
	RailStation *r = [stations objectAtIndex:0];
	char title = [r.station characterAtIndex:0];
	char next;
	int offset = 0;
	int count = 1;
	
	for(i=1; i< stations.count; i++)
	{
		r = [stations objectAtIndex:i];
		next = [r.station characterAtIndex:0];
		if (next != title)
		{
			[res3 appendFormat:@"\t{ '%c', %d, %d},\n", title, offset, count];
			title = next;
			offset = i;
			count = 1;
		}
		else 
		{
			count++;
		}
	}
	
	[res3 appendFormat:@"\t{ '%c', %d, %d},\n", title, offset, count];
	
	[res3 appendFormat:@"};\n"];
	DEBUG_LOG(@"%@", res3);
#endif	
}


@end

#endif
