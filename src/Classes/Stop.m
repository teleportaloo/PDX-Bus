//
//  Stop.m
//  TriMetTimes
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

#import "Stop.h"


@implementation Stop

@synthesize desc	 = _desc;
@synthesize locid	 = _locid;
@synthesize tp		 = _tp;
@synthesize lat		 = _lat;
@synthesize lng		 = _lng;
@synthesize callback = _callback; 
@synthesize dir		 = _dir;
@synthesize index	 = _index;

- (void) dealloc
{
	self.desc	= nil;
	self.locid	= nil;
	self.tp		= nil;
	self.lat    = nil;
	self.lat    = nil;
	self.dir    = nil;
	
	[super dealloc];
}

- (MKPinAnnotationColor) getPinColor
{
	return MKPinAnnotationColorGreen;
}

- (bool) showActionMenu
{
	return YES;
}

- (bool)mapTapped:(id<BackgroundTaskProgress>) progress
{
	[self.callback chosenStop:self progress:progress];
	return YES;
}

- (NSString *)tapActionText
{
	return [self.callback actionText];
}


- (CLLocationCoordinate2D)coordinate
{
	CLLocationCoordinate2D pos;
	
	pos.latitude = [self.lat doubleValue];
	pos.longitude = [self.lng doubleValue];
	return pos;
}

- (NSString *)title
{
	return self.desc;
}

- (NSString *)subtitle
{
	if (self.dir == nil)
	{
		return [NSString stringWithFormat:@"Stop ID %@", self.locid];
	}
	
	return [NSString stringWithFormat:@"%@ ID %@", self.dir, self.locid];
}

-(NSComparisonResult)compareUsingStopName:(Stop*)inStop
{
	return [self.desc compare:inStop.desc];
}

-(NSComparisonResult)compareUsingIndex:(Stop*)inStop
{
	if (self.index < inStop.index)
	{
		return NSOrderedAscending;
	}
	
	if (self.index > inStop.index)
	{
		return NSOrderedDescending;
	}
	
	return NSOrderedSame;
}

-(NSString*)stringToFilter
{
	return self.desc;
}


@end
