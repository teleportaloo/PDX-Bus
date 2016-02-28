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
	return _data.loc.coordinate;
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
    if (_data.locDir!=nil && _data.locDir.length!=0)
    {
        return [NSString stringWithFormat:@"%@ (%@)", _data.locDesc, _data.locDir];
    }
    return _data.locDesc;
}
- (NSString *)DTDataGetSectionTitle
{
	return _data.sectionTitle;
}

- (void)DTDataPopulateCell:(DepartureUI *)dd cell:(UITableViewCell *)cell decorate:(BOOL)decorate wide:(BOOL)wide
{
	[dd populateCell:cell decorate:decorate busName:YES wide:wide];
}
- (NSString *)DTDataStaticText
{
	return [NSString stringWithFormat:@"(ID %@) %@.", 
			_data.locid,
			_data.locDir];
}

- (StopDistanceData*)DTDataDistance
{
	return _data.distance;
}

- (TriMetTime) DTDataQueryTime
{
	return _data.queryTime;
}

- (CLLocation *)DTDataLoc
{
	return _data.loc;
}

- (NSString *)DTDataLocDesc
{
	return _data.locDesc;
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

- (UIColor *)getPinTint
{
    return nil;
}

- (bool)hasBearing
{
    return NO;
}


@end
