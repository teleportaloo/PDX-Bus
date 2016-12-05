//
//  Detour.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Detour.h"



@implementation Detour

@synthesize routeDesc = _routeDesc;
@synthesize detourDesc = _detourDesc;
@synthesize route = _route;

#define kFontName				@"Arial"
#define kTextViewFontSize		16.0



- (void) dealloc
{
	self.routeDesc = nil;
	self.detourDesc = nil;
	self.route = nil;
	[super dealloc];
}

@end
