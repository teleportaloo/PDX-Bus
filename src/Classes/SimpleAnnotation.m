//
//  SimpleAnnotation.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/24/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "SimpleAnnotation.h"


@implementation SimpleAnnotation

@synthesize pinColor = _pinColor;
@synthesize pinSubtitle = _pinSubtitle;
@synthesize pinTitle = _pinTitle;

- (void)dealloc {
	self.pinSubtitle = nil;
	self.pinTitle = nil;
	[super dealloc];
}

#pragma mark Setters

- (void)setCoordinateLat:(NSString *)lat lng:(NSString *)lng
{
	coord.latitude = 	[lat doubleValue];
	coord.longitude =  [lng doubleValue];
}


- (void)setCoord:(CLLocationCoordinate2D)value
{
	coord=value;
}

#pragma mark Getters

- (NSString *)title
{
	return self.pinTitle;
}
- (NSString *)subtitle
{
	return self.pinSubtitle;
}
- (MKPinAnnotationColor) getPinColor
{
	return self.pinColor;
}

- (CLLocationCoordinate2D)coordinate
{
	return coord;
}

- (bool) showActionMenu
{
	return false;
}


@end
