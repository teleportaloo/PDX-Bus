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

#import "Hotspot.h"
#import "RailStation.h"
#import "RailStationTableView.h"
#import "XMLStops.h"
#import "RailMapView.h"
#import "XMLDepartures.h"
#import "MapViewController.h"
#import "debug.h"
#import "RailMapView.h"

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
	0x041, 	/* Albina/Mississippi */
	0x0aa, 	/* Art Museum */
	0x00f, 	/* Beaverton Central */
	0x00d, 	/* Beaverton Creek */
	0x010, 	/* Beaverton TC */
	0x04c, 	/* Cascades */
	0x0a8, 	/* Central Library */
	0x033, 	/* City Hall/SW 5th & Jefferson St */
	0x05e, 	/* Civic Drive */
	0x055, 	/* Clackamas Town Center TC */
	0x061, 	/* Cleveland Ave */
	0x044, 	/* Convention Center */
	0x03a, 	/* Delta Park/Vanport */
	0x056, 	/* E 102nd Ave */
	0x057, 	/* E 122nd Ave */
	0x058, 	/* E 148th Ave */
	0x059, 	/* E 162nd Ave */
	0x05a, 	/* E 172nd */
	0x05b, 	/* E 181st */
	0x00b, 	/* Elmonica/SW 170th Ave */
	0x039, 	/* Expo Center */
	0x006, 	/* Fair Complex/Hillsboro Airport */
	0x020, 	/* Galleria/SW 10th */
	0x01e, 	/* Gateway/NE 99th TC */
	0x01a, 	/* Goose Hollow/SW Jefferson St */
	0x060, 	/* Gresham Central TC */
	0x05f, 	/* Gresham City Hall */
	0x014, 	/* Hall/Nimbus */
	0x002, 	/* Hatfield Government Center */
	0x007, 	/* Hawthorn Farm */
	0x003, 	/* Hillsboro Central/SE 3rd TC */
	0x047, 	/* Hollywood/NE 42nd Ave */
	0x042, 	/* Interstate/Rose Quarter */
	0x01c, 	/* JELD-WEN Field */
	0x03b, 	/* Kenton/N Denver */
	0x01b, 	/* Kings Hill/SW Salmon St */
	0x052, 	/* Lents/SE Foster Rd */
	0x023, 	/* Library/SW 9th Ave */
	0x046, 	/* Lloyd Center/NE 11th Ave */
	0x034, 	/* Mall/SW 4th Ave */
	0x030, 	/* Mall/SW 5th Ave */
	0x00c, 	/* Merlo Rd/SW 158th Ave */
	0x00e, 	/* Millikan Way */
	0x031, 	/* Morrison/SW 3rd Ave */
	0x04b, 	/* Mt Hood Ave */
	0x03e, 	/* N Killingsworth */
	0x03c, 	/* N Lombard TC */
	0x03f, 	/* N Prescott */
	0x08f, 	/* N Weidler/Broadway & Ross */
	0x048, 	/* NE 60th Ave */
	0x089, 	/* NE 7th & Halsey */
	0x088, 	/* NE 7th & Holladay */
	0x045, 	/* NE 7th Ave */
	0x049, 	/* NE 82nd Ave */
	0x08d, 	/* NE Broadway & 2nd (Streetcar) */
	0x08b, 	/* NE Grand & Broadway */
	0x085, 	/* NE Grand & Hoyt */
	0x08a, 	/* NE Grand & Multnomah */
	0x087, 	/* NE Grand & Pacific */
	0x083, 	/* NE M L King & E Burnside */
	0x084, 	/* NE M L King & Hoyt */
	0x086, 	/* NE Oregon & Grand */
	0x08e, 	/* NE Weidler & 2nd (Streetcar) */
	0x08c, 	/* NE Weidler & Grand */
	0x0a4, 	/* NW 10th & Couch */
	0x0a2, 	/* NW 10th & Everett */
	0x0a0, 	/* NW 10th & Glisan */
	0x09e, 	/* NW 10th & Johnson */
	0x09c, 	/* NW 10th & Northrup */
	0x0a3, 	/* NW 11th & Couch */
	0x0a1, 	/* NW 11th & Everett */
	0x09f, 	/* NW 11th & Glisan */
	0x09d, 	/* NW 11th & Johnson */
	0x091, 	/* NW 11th & Marshall */
	0x09b, 	/* NW 12th & Northrup */
	0x092, 	/* NW 23rd & Marshall */
	0x02d, 	/* NW 5th & Couch St */
	0x029, 	/* NW 6th & Davis St */
	0x090, 	/* NW 9th & Lovejoy */
	0x09a, 	/* NW Lovejoy & 13th */
	0x098, 	/* NW Lovejoy & 18th */
	0x095, 	/* NW Lovejoy & 21st */
	0x093, 	/* NW Lovejoy & 22nd */
	0x099, 	/* NW Northrup & 14th */
	0x097, 	/* NW Northrup & 18th */
	0x096, 	/* NW Northrup & 21st */
	0x094, 	/* NW Northrup & 22nd */
	0x0b5, 	/* OHSU Commons */
	0x038, 	/* Oak/SW 1st Ave */
	0x036, 	/* Old Town/Chinatown */
	0x008, 	/* Orenco/NW 231st Ave */
	0x040, 	/* Overlook Park */
	0x000, 	/* PSU South/SW 5th & Jackson */
	0x001, 	/* PSU South/SW 6th & College */
	0x0b0, 	/* PSU Urban Center */
	0x032, 	/* PSU/SW 5th & Mill St */
	0x026, 	/* PSU/SW 6th & Montgomery */
	0x04d, 	/* Parkrose/Sumner TC */
	0x022, 	/* Pioneer Courthouse/SW 6th Ave */
	0x02e, 	/* Pioneer Place/SW 5th Ave */
	0x021, 	/* Pioneer Square North */
	0x024, 	/* Pioneer Square South */
	0x04a, 	/* Portland Int'l Airport */
	0x009, 	/* Quatama/NW 205th Ave */
	0x05c, 	/* Rockwood/E 188th Ave TC */
	0x03d, 	/* Rosa Parks */
	0x043, 	/* Rose Quarter TC */
	0x05d, 	/* Ruby Junction/E 197th Ave */
	0x04f, 	/* SE Division St */
	0x053, 	/* SE Flavel St */
	0x054, 	/* SE Fuller Rd */
	0x07e, 	/* SE Grand & Belmont */
	0x082, 	/* SE Grand & E Burnside */
	0x07a, 	/* SE Grand & Hawthorne */
	0x078, 	/* SE Grand & Mill */
	0x080, 	/* SE Grand & Stark */
	0x07c, 	/* SE Grand & Taylor */
	0x051, 	/* SE Holgate Blvd */
	0x07b, 	/* SE M L King & Hawthorne */
	0x079, 	/* SE M L King & Mill */
	0x07f, 	/* SE M L King & Morrison */
	0x081, 	/* SE M L King & Stark */
	0x07d, 	/* SE M L King & Taylor */
	0x04e, 	/* SE Main St */
	0x050, 	/* SE Powell Blvd */
	0x077, 	/* SE Water/OMSI (Streetcar) */
	0x0a7, 	/* SW 10th & Alder */
	0x0ad, 	/* SW 10th & Clay */
	0x0a5, 	/* SW 10th & Stark */
	0x0a6, 	/* SW 11th & Alder */
	0x0ac, 	/* SW 11th & Clay */
	0x0ab, 	/* SW 11th & Jefferson */
	0x0a9, 	/* SW 11th & Taylor */
	0x0b4, 	/* SW 1st & Harrison */
	0x0b3, 	/* SW 3rd & Harrison */
	0x0b2, 	/* SW 5th & Market */
	0x0b1, 	/* SW 5th & Montgomery */
	0x02f, 	/* SW 5th & Oak St */
	0x025, 	/* SW 6th & Madison St */
	0x02a, 	/* SW 6th & Pine St */
	0x0ba, 	/* SW Bond & Lane */
	0x0b8, 	/* SW Harrison Street */
	0x0bc, 	/* SW Lowell & Bond */
	0x0bb, 	/* SW Moody & Gaines */
	0x0b6, 	/* SW Moody & Gibbs */
	0x0b9, 	/* SW Moody & Meade */
	0x0ae, 	/* SW Park & Market */
	0x0af, 	/* SW Park & Mill */
	0x0b7, 	/* SW River Pkwy & Moody */
	0x037, 	/* Skidmore Fountain */
	0x018, 	/* Sunset TC */
	0x015, 	/* Tigard TC */
	0x016, 	/* Tualatin */
	0x004, 	/* Tuality Hospital/SE 8th Ave */
	0x02c, 	/* Union Station/NW 5th & Glisan St */
	0x028, 	/* Union Station/NW 6th & Hoyt St */
	0x019, 	/* Washington Park */
	0x005, 	/* Washington/SE 12th Ave */
	0x00a, 	/* Willow Creek/SW 185th Ave TC */
	0x017, 	/* Wilsonville */
	0x035, 	/* Yamhill District */
};

//
// These are the colours for the lines of each rail station in the hotspot array.  It is calculated by gettng the stops
// for each station and merging them in.  Much easier than doing it by hand!
//

static RAILLINES railLines[]={
	0x0c,	/* PSU South/SW 5th & Jackson */
	0x0c,	/* PSU South/SW 6th & College */
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
	0x03,	/* JELD-WEN Field */
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
	0x40,	/* SE Water/OMSI (Streetcar) */
	0x40,	/* SE Grand & Mill */
	0x40,	/* SE M L King & Mill */
	0x40,	/* SE Grand & Hawthorne */
	0x40,	/* SE M L King & Hawthorne */
	0x40,	/* SE Grand & Taylor */
	0x40,	/* SE M L King & Taylor */
	0x40,	/* SE Grand & Belmont */
	0x40,	/* SE M L King & Morrison */
	0x40,	/* SE Grand & Stark */
	0x40,	/* SE M L King & Stark */
	0x40,	/* SE Grand & E Burnside */
	0x40,	/* NE M L King & E Burnside */
	0x40,	/* NE M L King & Hoyt */
	0x40,	/* NE Grand & Hoyt */
	0x40,	/* NE Oregon & Grand */
	0x40,	/* NE Grand & Pacific */
	0x40,	/* NE 7th & Holladay */
	0x40,	/* NE 7th & Halsey */
	0x40,	/* NE Grand & Multnomah */
	0x40,	/* NE Grand & Broadway */
	0x40,	/* NE Weidler & Grand */
	0x40,	/* NE Broadway & 2nd (Streetcar) */
	0x40,	/* NE Weidler & 2nd (Streetcar) */
	0x40,	/* N Weidler/Broadway & Ross */
	0x40,	/* NW 9th & Lovejoy */
	0x40,	/* NW 11th & Marshall */
	0x20,	/* NW 23rd & Marshall */
	0x20,	/* NW Lovejoy & 22nd */
	0x20,	/* NW Northrup & 22nd */
	0x20,	/* NW Lovejoy & 21st */
	0x20,	/* NW Northrup & 21st */
	0x20,	/* NW Northrup & 18th */
	0x20,	/* NW Lovejoy & 18th */
	0x20,	/* NW Northrup & 14th */
	0x20,	/* NW Lovejoy & 13th */
	0x20,	/* NW 12th & Northrup */
	0x60,	/* NW 10th & Northrup */
	0x60,	/* NW 11th & Johnson */
	0x60,	/* NW 10th & Johnson */
	0x60,	/* NW 11th & Glisan */
	0x60,	/* NW 10th & Glisan */
	0x60,	/* NW 11th & Everett */
	0x60,	/* NW 10th & Everett */
	0x60,	/* NW 11th & Couch */
	0x60,	/* NW 10th & Couch */
	0x60,	/* SW 10th & Stark */
	0x60,	/* SW 11th & Alder */
	0x60,	/* SW 10th & Alder */
	0x60,	/* Central Library */
	0x60,	/* SW 11th & Taylor */
	0x60,	/* Art Museum */
	0x60,	/* SW 11th & Jefferson */
	0x60,	/* SW 11th & Clay */
	0x60,	/* SW 10th & Clay */
	0x20,	/* SW Park & Market */
	0x20,	/* SW Park & Mill */
	0x20,	/* PSU Urban Center */
	0x20,	/* SW 5th & Montgomery */
	0x20,	/* SW 5th & Market */
	0x20,	/* SW 3rd & Harrison */
	0x20,	/* SW 1st & Harrison */
	0x20,	/* OHSU Commons */
	0x20,	/* SW Moody & Gibbs */
	0x20,	/* SW River Pkwy & Moody */
	0x20,	/* SW Harrison Street */
	0x20,	/* SW Moody & Meade */
	0x20,	/* SW Bond & Lane */
	0x20,	/* SW Moody & Gaines */
	0x20,	/* SW Lowell & Bond */
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
	{ 'N', 45, 42},
	{ 'O', 87, 5},
	{ 'P', 92, 11},
	{ 'Q', 103, 1},
	{ 'R', 104, 4},
	{ 'S', 108, 43},
	{ 'T', 151, 3},
	{ 'U', 154, 2},
	{ 'W', 156, 4},
	{ 'Y', 160, 1},
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
		
#ifndef CREATE_MAX_ARRAYS
		for (int i=0; i< sizeof(stationsAlpha)/sizeof(int);  i++)
		{
			RailStation *station = [[RailStation alloc] initFromHotSpot:_hotSpots+stationsAlpha[i] index:stationsAlpha[i]];
			
            [self.searchableItems addObject:station];
			
                [station release];
        }
		
		self.enableSearch = YES;
#endif
	}
	return self;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self reloadData];
}

- (void)showRailMap:(id)sender
{
    RailMapView *webPage = [[RailMapView alloc] init];
    [[self navigationController] pushViewController:webPage animated:YES];
    [webPage release];
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
	[toolbarItems addObject:[CustomToolbar autoMapButtonWithTarget:self action:@selector(showMap:)]];
    
    
    if ([RailMapView RailMapSupported])
    {
        [toolbarItems addObject:[CustomToolbar autoFlexSpace]];
    
        UIBarButtonItem *stations = [[[UIBarButtonItem alloc]
                             initWithTitle:@"Rail map"
                             style:UIBarButtonItemStylePlain
                            target:self action:@selector(showRailMap:)] autorelease];
    
        stations.style = UIBarButtonItemStylePlain;
        stations.accessibilityLabel = @"Show Rail Map";
        
        [toolbarItems addObject:stations];
    }
    
    
    
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
	
	NSMutableString * res0 = [[[NSMutableString alloc] init] autorelease];
	
	[res0 appendString:@"\n"];
	
	for (RailStation * r in streetcarStops)
	{
		[res0 appendFormat:@"\tNULL_HOTSPOT(\"%@\");\n", [r url]];
	}
	
	CODE_LOG(@"\n--------\nStreetcar Station Data\n--------%@\n\n", res0);
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
	
	CODE_LOG(@"\n--------\nStation Names in Alphabetical Order\n--------\n%@\n\n", res);
	
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
	
	[self addLine:kStreetcarNsLine route:@"193" direction:@"0" stations:stations];
	[self addLine:kStreetcarNsLine route:@"193" direction:@"1" stations:stations];
    
    [self addLine:kStreetcarClLine route:@"194" direction:@"0" stations:stations];
	[self addLine:kStreetcarClLine route:@"194" direction:@"1" stations:stations];
	
	// Civic Drive is a special case - add it now by hand - when I made the 
	// stop location database it had been removed from the lines
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
	
	CODE_LOG(@"\n--------\nLine colors for each station\n--------\n%@\n\n", res1);
	
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
	CODE_LOG(@"\n--------\nTable Sections\n--------\n%@\n\n", res3);
#endif	
}


@end

