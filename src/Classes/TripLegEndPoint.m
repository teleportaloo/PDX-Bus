//
//  TripLegEndPoint.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


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
@synthesize thruRoute       = _thruRoute;

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

- (UIColor *)getPinTint
{
    return nil;
}

- (bool)hasBearing
{
    return NO;
}

- (CLLocation *)loc
{
    if (self.xlat!=nil && self.xlon!=nil)
    {
        return [[[CLLocation alloc] initWithLatitude:self.xlat.doubleValue longitude:self.xlon.doubleValue] autorelease];
    }
    
    return nil;
}



@end
