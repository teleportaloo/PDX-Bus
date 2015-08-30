//
//  Vehicle.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "VehicleData.h"
#import "DebugLogging.h"

@implementation VehicleData

@synthesize block           = _block;
@synthesize location        = _location;
@synthesize nextLocID       = _nextLocID;
@synthesize routeNumber     = _routeNumber;
@synthesize direction       = _direction;
@synthesize signMessage     = _signMessage;
@synthesize signMessageLong = _signMessageLong;
@synthesize type            = _type;
@synthesize lastLocID       = _lastLocID;
@synthesize locationTime    = _locationTime;
@synthesize garage          = _garage;


- (void)dealloc
{
    self.block = nil;
    self.location = nil;
    self.nextLocID = nil;
    self.routeNumber = nil;
    self.direction = nil;
    self.signMessage = nil;
    self.signMessageLong = nil;
    self.type           = nil;
    self.lastLocID      = nil;
    self.garage         = nil;
    
    [super dealloc];
}

- (CLLocationCoordinate2D) coordinate
{
    return self.location.coordinate;
}


-(NSComparisonResult)compareUsingDistance:(VehicleData*)inVehicle
{
	if (self.distance < inVehicle.distance)
	{
		return NSOrderedAscending;
	}
    
	if (self.distance > inVehicle.distance)
	{
		return NSOrderedDescending;
	}
    
	return NSOrderedSame;
}

@end
