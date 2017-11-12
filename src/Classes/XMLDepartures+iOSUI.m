//
//  XMLDeparturesUI.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLDepartures+iOSUI.h"
#import "DepartureData.h"
#import "DebugLogging.h"
#import "DepartureData+iOSUI.h"


@implementation XMLDepartures (iOSUI)

#pragma mark Map Pin callbacks

- (NSString *)mapStopId
{
	return self.locid;
}

- (bool)showActionMenu
{
	return YES;
}

// MK Annotate
- (CLLocationCoordinate2D)coordinate
{
	return self.loc.coordinate;
}

- (NSString *)title
{
	return self.locDesc;
}

- (MKPinAnnotationColor) pinColor
{
	return MKPinAnnotationColorGreen;
}


#pragma mark Data accessors

- (id)DTDataXML
{
	return self;
}

- (DepartureData *)DTDataGetDeparture:(NSInteger)i
{
	return self[i];
}
- (NSInteger)DTDataGetSafeItemCount
{
	return self.count;
}
- (NSString *)DTDataGetSectionHeader
{
    if (self.locDir!=nil && self.locDir.length!=0)
    {
        return [NSString stringWithFormat:@"%@ (%@)", self.locDesc, self.locDir];
    }
    return self.locDesc;
}
- (NSString *)DTDataGetSectionTitle
{
	return self.sectionTitle;
}

- (void)DTDataPopulateCell:(DepartureData *)dd cell:(DepartureCell *)cell decorate:(BOOL)decorate wide:(BOOL)wide
{
	[dd populateCell:cell decorate:decorate busName:YES wide:wide];
}
- (NSString *)DTDataStaticText
{
	return [NSString stringWithFormat:@"Stop ID %@.", self.locid];
}

- (StopDistanceData*)DTDataDistance
{
	return self.distance;
}

- (TriMetTime) DTDataQueryTime
{
	return self.queryTime;
}

- (CLLocation *)DTDataLoc
{
	return self.loc;
}

- (NSString *)DTDataLocDesc
{
	return self.locDesc;
}

- (NSString *)DTDataLocID
{
	return self.locid;
}

- (BOOL) DTDataHasDetails
{
	return TRUE;
}

- (BOOL) DTDataNetworkError
{
	return !self.gotData;
}

- (NSString *) DTDataNetworkErrorMsg
{
	return self.errorMsg;
}

- (NSString *) DTDataDir
{
	return self.locDir;
}

- (NSData *) DTDataHtmlError
{
	return self.htmlError;
}

- (UIColor *)pinTint
{
    return nil;
}

- (bool)hasBearing
{
    return NO;
}


@end
