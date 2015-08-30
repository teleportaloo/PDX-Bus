//
//  Trip.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DepartureTrip.h"

@implementation DepartureTrip

@synthesize name = _name;
@synthesize distance = _distance;
@synthesize progress = _progress;
@synthesize startTime = _startTime;
@synthesize endTime = _endTime;

- (void)dealloc
{
	self.name = nil;
	[super dealloc];
}

- (id)init
{
	if ((self = [super init]))
	{
	
		self.distance = 0;
		self.progress = 0;
		self.startTime = 0;
		self.endTime = 0;
	}
		
	return self;
}

@end
