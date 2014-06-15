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


#import "Vehicle.h"
#import "DepartureTimesView.h"
#import "TriMetRouteColors.h"

@implementation Vehicle

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

- (NSString*)title
{
    if (self.signMessage)
    {
        DEBUG_LOG(@"Sign Message %@ b %@\n", self.signMessage, self.block);
        return self.signMessage;
    }
    
    if ([self.type isEqualToString:kVehicleTypeStreetcar])
    {
        ROUTE_COL *col = [TriMetRouteColors rawColorForRoute:self.routeNumber];
        
        if (col)
        {
            return col->name;
        }
        return @"Portland Streetcar";
    }
    
    if (self.garage)
    {
        return [NSString stringWithFormat:@"Garage %@", self.garage];
    }
    
    return @"";
}

- (NSString*)subtitle
{
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setTimeStyle:NSDateFormatterLongStyle];
    
    return [NSString stringWithFormat:@"Seen at %@", [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:TriMetToUnixTime(self.locationTime)]]];
}

// From MapPinColor
- (MKPinAnnotationColor) getPinColor
{
    if ([self.type isEqualToString:kVehicleTypeBus])
    {
        return MKPinAnnotationColorRed;
    }
    
    if ([self.type isEqualToString:kVehicleTypeStreetcar])
    {
        return MKPinAnnotationColorPurple;
    }
    
    return MKPinAnnotationColorGreen;
}
- (bool) showActionMenu
{
    if (self.lastLocID)
    {
        return YES;
    }
    return NO;
}
- (bool) mapTapped:(id<BackgroundTaskProgress>) progress
{
    DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
    [departureViewController fetchTimesForVehicleInBackground:progress route:self.routeNumber direction:self.direction nextLoc:self.lastLocID block:self.block];
    [departureViewController release];
    
    return true;
}

- (NSString *) tapActionText
{
    return @"Show next stops";
}


-(NSComparisonResult)compareUsingDistance:(Vehicle*)inVehicle
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
