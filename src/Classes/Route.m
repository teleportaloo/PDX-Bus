//
//  Route.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Route.h"


@implementation Route

@synthesize desc = _desc;
@synthesize route = _route;
@synthesize directions = _directions;


- (void) dealloc
{
	self.desc = nil;
	self.route = nil;
	self.directions = nil;
	[super dealloc];
}

-(id)init
{
	if ((self = [super init]))
	{
		self.directions = [[[NSMutableDictionary alloc] init] autorelease];
	}
	return self;
}

- (NSString*)stringToFilter
{
	return self.desc;
}

@end
