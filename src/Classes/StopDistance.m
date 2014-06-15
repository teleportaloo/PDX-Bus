//
//  StopDistance.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


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

- (bool) showActionMenu
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
	return [NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), self.locid];
}

- (NSString *) mapStopId
{
	return self.locid;
}


@end
