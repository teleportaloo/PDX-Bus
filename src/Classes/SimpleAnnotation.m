//
//  SimpleAnnotation.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/24/09.
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

- (bool) mapDisclosure
{
	return false;
}


@end
