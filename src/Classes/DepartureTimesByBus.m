//
//  DepartureTimesByBus.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/2/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DepartureTimesByBus.h"
#import "DepartureData.h"
#import "DepartureData+iOSUI.h"


@implementation DepartureTimesByBus

@synthesize departureItems = _departureItems;

- (void)dealloc
{
	self.departureItems = nil;
	[super dealloc];
}

- (instancetype)init {
	if ((self = [super init]))
	{
        self.departureItems = [NSMutableArray array];
	}
	return self;
}

#pragma mark Data Accessors

- (DepartureData *)DTDataGetDeparture:(NSInteger)i
{
	return self.departureItems[i];
}
- (NSInteger)DTDataGetSafeItemCount
{
	if (self.departureItems == nil)
	{
		return 0;
	}
	return self.departureItems.count;
}
- (NSString *)DTDataGetSectionHeader
{
	return [self DTDataGetDeparture:0].shortSign;
}
- (NSString *)DTDataGetSectionTitle
{
	return nil;
}

- (void)DTDataPopulateCell:(DepartureData *)dd cell:(DepartureCell *)cell decorate:(BOOL)decorate wide:(BOOL)wide
{
	[dd populateCell:cell decorate:decorate busName:NO wide:wide];	
}

- (NSString *)DTDataStaticText
{
	DepartureData *d = [self DTDataGetDeparture:0];
	if (d.block != nil)
	{
		return [NSString stringWithFormat:NSLocalizedString(@"(Trip ID %@) ", @"trip info small text"), d.block];
	}
	return NSLocalizedString(@"(Trip ID unavailable)", @"error text");
}

- (StopDistanceData*)DTDataDistance
{
	return nil;
}
- (TriMetTime) DTDataQueryTime
{
	return [self DTDataGetDeparture:0].queryTime;
}

- (NSString *)DTDataLoc
{
	return nil;
}

- (NSString *)DTDataLocDesc
{
	DepartureData *dep = [self DTDataGetDeparture:0];
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
