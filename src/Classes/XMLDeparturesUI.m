//
//  XMLDeparturesUI.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLDeparturesUI.h"
#import "DepartureData.h"
#import "DebugLogging.h"
#import "DepartureUI.h"


@implementation XMLDeparturesUI

@synthesize data = _data;


+ (XMLDeparturesUI*) createFromData:(XMLDepartures *)data
{
    XMLDeparturesUI *item = [[[XMLDeparturesUI alloc] initWithData:data] autorelease];
    
    return item;
}

- (void)dealloc
{
    self.data = nil;
    
    [super dealloc];
}

- (id)initWithData:(XMLDepartures *)data
{
    if ((self = [super init]))
    {
        self.data = data;
    }
    return self;
}


#pragma mark Map Pin callbacks

- (NSString *)mapStopId
{
	return _data.locid;
}

- (bool)showActionMenu
{
	return YES;
}

// MK Annotate
- (CLLocationCoordinate2D)coordinate
{
	CLLocationCoordinate2D pos;
	
	pos.latitude = [_data.locLat doubleValue];
	pos.longitude = [_data.locLng doubleValue];
	return pos;
}

- (NSString *)title
{
	return _data.locDesc;
}

- (MKPinAnnotationColor) getPinColor
{
	return MKPinAnnotationColorGreen;
}


#pragma mark Data accessors

- (id)DTDataXML
{
	return _data;
}

- (DepartureData *)DTDataGetDeparture:(NSInteger)i
{
	return [_data itemAtIndex:i];
}
- (NSInteger)DTDataGetSafeItemCount
{
	return [_data safeItemCount];
}
- (NSString *)DTDataGetSectionHeader
{
	return _data.locDesc;
}
- (NSString *)DTDataGetSectionTitle
{
	return _data.sectionTitle;
}

- (void)DTDataPopulateCell:(DepartureUI *)dd cell:(UITableViewCell *)cell decorate:(BOOL)decorate big:(BOOL)big wide:(BOOL)wide
{
	[dd populateCell:cell decorate:decorate big:big busName:YES wide:wide];
}
- (NSString *)DTDataStaticText
{
	return [NSString stringWithFormat:@"(ID %@) %@.", 
			_data.locid,
			_data.locDir];
}

- (StopDistance*)DTDataDistance
{
	return _data.distance;
}

- (TriMetTime) DTDataQueryTime
{
	return _data.queryTime;
}

- (NSString *)DTDataLocLat
{
	return _data.locLat;
}
- (NSString *)DTDataLocLng
{
	return _data.locLng;
}
- (NSString *)DTDataLocDesc
{
	return _data.locDesc;
}

- (id<MapPinColor>)DTDatagetPin
{
	return self;
}

- (NSString *)DTDataLocID
{
	return _data.locid;
}

- (BOOL) DTDataHasDetails
{
	return TRUE;
}

- (BOOL) DTDataNetworkError
{
	return ![_data gotData];
}

- (NSString *) DTDataNetworkErrorMsg
{
	return _data.errorMsg;
}

- (NSString *) DTDataDir
{
	return _data.locDir;
}

- (NSData *) DTDataHtmlError
{
	return _data.htmlError;
}


@end
