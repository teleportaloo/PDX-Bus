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
@synthesize pinTint = _pinTint;

- (void)dealloc {
	self.pinSubtitle = nil;
	self.pinTitle = nil;
    self.pinTint = nil;
	[super dealloc];
}

#pragma mark Setters


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

- (UIColor *)getPinTint
{
    return self.pinTint;
}

- (bool)hasBearing
{
    return _hasBearing;
}

- (void)setBearing:(double)bearing
{
    _bearing = bearing;
    _hasBearing = YES;
}

- (double)bearing
{
    return _bearing;
}


@end
