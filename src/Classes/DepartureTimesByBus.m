//
//  DepartureTimesByBus.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/2/09.
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

#import "DepartureTimesByBus.h"
#import "Departure.h"


@implementation DepartureTimesByBus

@synthesize departureItems = _departureItems;

- (void)dealloc
{
	self.departureItems = nil;
	[super dealloc];
}

- (id)init {
	if ((self = [super init]))
	{
		self.departureItems = [[[NSMutableArray alloc] init] autorelease];
	}
	return self;
}

#pragma mark Data Accessors

- (Departure *)DTDataGetDeparture:(int)i
{
	return [self.departureItems objectAtIndex:i];
}
- (int)DTDataGetSafeItemCount
{
	if (self.departureItems == nil)
	{
		return 0;
	}
	return [self.departureItems count];
}
- (NSString *)DTDataGetSectionHeader
{
	return [self DTDataGetDeparture:0].routeName;
}
- (NSString *)DTDataGetSectionTitle
{
	return nil;
}

- (void)DTDataPopulateCell:(Departure *)dd cell:(UITableViewCell *)cell decorate:(BOOL)decorate big:(BOOL)big wide:(BOOL)wide
{
	[dd populateCell:cell decorate:decorate big:big busName:NO wide:wide];	
}

- (NSString *)DTDataStaticText
{
	Departure *d = [self DTDataGetDeparture:0];
	if (d.block != nil)
	{
		return [NSString stringWithFormat:@"(Trip ID %@) ", d.block];
	}
	return @"(Trip ID unavailable)";
}

- (StopDistance*)DTDataDistance
{
	return nil;
}
- (TriMetTime) DTDataQueryTime
{
	return [self DTDataGetDeparture:0].queryTime;
}

- (NSString *)DTDataLocLat
{
	return nil;
}
- (NSString *)DTDataLocLng
{
	return nil;
}
- (NSString *)DTDataLocDesc
{
	Departure *dep = [self DTDataGetDeparture:0];
	return dep.locationDesc;
}

- (NSString *)DTDataLocID
{
	return [self DTDataGetDeparture:0].locid;
}

- (NSString *)DTDataDir
{
	return [self DTDataGetDeparture:0].locationDir;
}

- (id<MapPinColor>)DTDatagetPin
{
	return nil;
}

- (BOOL) DTDataHasDetails
{
	return FALSE;
}

- (BOOL) DTDataNetworkError
{
	return self.departureItems == nil;
}

- (NSString *)DTDataNetworkErrorMsg
{
	return nil;
}

- (NSData *) DTDataHtmlError
{
	return nil;
}

@end
