//
//  TripLegEndPoint.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
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

#import "TripLegEndPoint.h"

@implementation TripLegEndPoint

@synthesize xlat			= _xlat;
@synthesize xlon			= _xlon;
@synthesize xdescription	= _xdescription;
@synthesize xstopId			= _xstopId;
@synthesize displayText		= _displayText;
@synthesize mapText			= _mapText;
@synthesize index			= _index;
@synthesize callback		= _callback;
@synthesize displayModeText = _displayModeText;
@synthesize displayTimeText = _displayTimeText;
@synthesize leftColor       = _leftColor;
@synthesize xnumber			= _xnumber;

- (void)dealloc {
	
	self.xlat			= nil;
	self.xlon			= nil;
	self.xdescription	= nil;
	self.xstopId		= nil;
	self.displayText    = nil;
	self.mapText		= nil;
	self.callback		= nil;
	self.displayModeText = nil;
	self.displayTimeText = nil;
	self.leftColor		 = nil;
	self.xnumber		 = nil;
	[super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
	TripLegEndPoint *ep = [[ TripLegEndPoint allocWithZone:zone] init];
	
	ep.xlat				= [[self.xlat			copyWithZone:zone] autorelease];
	ep.xlon				= [[self.xlon			copyWithZone:zone] autorelease];
	ep.xdescription		= [[self.xdescription	copyWithZone:zone] autorelease];
	ep.xstopId			= [[self.xstopId		copyWithZone:zone] autorelease];
	ep.displayText		= [[self.displayText	copyWithZone:zone] autorelease];
	ep.displayText		= [[self.displayText	copyWithZone:zone] autorelease];
	ep.mapText			= [[self.mapText		copyWithZone:zone] autorelease];
	ep.xnumber			= [[self.xnumber		copyWithZone:zone] autorelease];
	ep.callback			= self.callback;
	ep.displayModeText	= [[self.displayModeText copyWithZone:zone] autorelease];
	ep.displayTimeText	= [[self.displayTimeText copyWithZone:zone] autorelease];
	ep.leftColor		= self.leftColor;
	ep.index			= self.index;
	
	return ep;
}

#pragma mark Map callbacks

- (NSString*)stopId
{
	if (self.xstopId)
	{
		return [NSString stringWithFormat:@"%d", [self.xstopId	intValue]];
	}
	return nil;
}

- (bool)mapTapped:(id<BackgroundTaskProgress>) progress
{
	if (self.callback != nil)
	{
		[self.callback chosenEndpoint:self];
		
		return YES;
	}
	return NO;
}

- (NSString *)tapActionText
{
	if (self.callback != nil)
	{
		return @"Choose this stop";
	}
	else {
		return @"Show arrivals";
	}
    
}

- (MKPinAnnotationColor) getPinColor
{
	return MKPinAnnotationColorGreen;
}

- (NSString *)mapStopId
{
	return [self stopId];
}

- (CLLocationCoordinate2D)coordinate
{
	CLLocationCoordinate2D pos;
	
	pos.latitude = [self.xlat doubleValue];
	pos.longitude = [self.xlon doubleValue];
	return pos;
}

- (bool)showActionMenu
{
	return self.xstopId!=nil || self.callback!=nil;
}

- (NSString *)title
{
	return self.xdescription;
}

- (NSString *)subtitle
{
	if (self.mapText != nil)
	{
		return [NSString stringWithFormat:@"%d: %@", self.index, self.mapText];
	}
	return nil;
}



@end
