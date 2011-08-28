//
//  StopDistance.m
//  PDX Bus
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

#import "StopDistance.h"


@implementation StopDistance

@synthesize distance = _distance;
@synthesize accuracy = _accuracy;
@synthesize locid = _locid;
@synthesize desc  = _desc;
@synthesize location = _location;

-(void)dealloc
{
	self.locid = nil;
	self.desc  = nil;
	self.location = nil;
	[super dealloc];
}


-(id)initWithLocId:(int)loc distance:(CLLocationDistance)dist accuracy:(CLLocationAccuracy)acc
{
	if ((self = [super init]))
	{
		
		self.locid = [NSString stringWithFormat:@"%d", loc];
		self.distance = dist;		
		self.accuracy = acc;
	}
	return self;
}

-(NSComparisonResult)compareUsingDistance:(StopDistance*)inStop
{
	if (self.distance < inStop.distance)
	{
		return NSOrderedAscending;
	}
	
	if (self.distance > inStop.distance)
	{
		return NSOrderedDescending;
	}
	
	return [self.locid compare:inStop.locid];
}

- (MKPinAnnotationColor) getPinColor
{
	return MKPinAnnotationColorGreen;
}

- (bool) mapDisclosure
{
	return YES;
}

- (CLLocationCoordinate2D)coordinate
{
	return self.location.coordinate;
}

- (NSString *)title
{
	return self.desc;
}

- (NSString *)subtitle
{
	return [NSString stringWithFormat:@"Stop ID %@", self.locid];
}

- (NSString *) mapStopId
{
	return self.locid;
}


@end
