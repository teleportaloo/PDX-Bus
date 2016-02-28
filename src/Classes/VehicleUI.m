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


#import "VehicleUI.h"
#import "DepartureTimesView.h"
#import "TriMetRouteColors.h"
#import "DebugLogging.h"

@class DepartureTimesView;

@implementation VehicleUI

@synthesize data            = _data;


+ (VehicleUI *)createFromData:(VehicleData *)data
{
    return [[[VehicleUI alloc] initWithData:data] autorelease];
}

- (id)initWithData:(VehicleData *)data {
    if ((self = [super init]))
    {
        self.data = data;
    }
    return self;
}


- (void)dealloc
{
    self.data = nil;
    
    [super dealloc];
}

- (CLLocationCoordinate2D) coordinate
{
    return _data.location.coordinate;
}

- (NSString*)title
{
    if (_data.signMessage)
    {
        DEBUG_LOG(@"Sign Message %@ b %@ %f %f\n", _data.signMessage, _data.block, _data.location.coordinate.latitude, _data.location.coordinate.latitude);
        return _data.signMessage;
    }
    
    if ([_data.type isEqualToString:kVehicleTypeStreetcar])
    {
        ROUTE_COL *col = [TriMetRouteColors rawColorForRoute:_data.routeNumber];
        
        if (col)
        {
            return col->name;
        }
        return @"Portland Streetcar";
    }
    
    if (_data.garage)
    {
        return [NSString stringWithFormat:@"Garage %@", _data.garage];
    }
    
    return @"no title";
}


- (NSString*)subtitle
{
    return [VehicleData locatedSomeTimeAgo:TriMetToNSDate(_data.locationTime)];
}

// From MapPinColor
- (MKPinAnnotationColor) getPinColor
{
        if ([_data.type isEqualToString:kVehicleTypeBus])
        {
            return MKPinAnnotationColorPurple;
        }
        
        if ([_data.type isEqualToString:kVehicleTypeStreetcar])
        {
            return MKPinAnnotationColorGreen;
        }
        
        return MKPinAnnotationColorRed;
}
- (bool)showActionMenu
{
    if (_data.lastLocID)
    {
        return YES;
    }
    return NO;
}

- (bool)mapTapped:(id<BackgroundTaskProgress>) progress
{
    DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
    [departureViewController fetchTimesForVehicleInBackground:progress route:_data.routeNumber direction:_data.direction nextLoc:_data.lastLocID block:_data.block];
    [departureViewController release];
    
    return true;
}

- (NSString *)mapStopId
{
    return _data.nextLocID;
}

- (NSString *)mapStopIdText
{
    return [NSString stringWithFormat:@"Arrivals at next stop - ID %@", _data.nextLocID];
}



- (NSString *)tapActionText
{
    return @"Show next stops";
}

- (UIColor *)getPinTint
{
    return [TriMetRouteColors colorForRoute:_data.routeNumber];
}

- (bool)hasBearing
{
    return self.data.bearing != nil;
}

- (double)bearing
{
    if (self.data.bearing)
    {
        return [self.data.bearing doubleValue];
    }
    return 0;
}

@end
