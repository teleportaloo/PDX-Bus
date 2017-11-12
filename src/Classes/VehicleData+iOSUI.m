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


#import "VehicleData+iOSUI.h"
#import "DepartureTimesView.h"
#import "TriMetRouteColors.h"
#import "DebugLogging.h"
#import "BlockColorDb.h"

@class DepartureTimesView;

@implementation VehicleData (VehicleUI)


- (CLLocationCoordinate2D) coordinate
{
    return self.location.coordinate;
}

- (NSString*)title
{
    if (self.signMessage)
    {
        DEBUG_LOG(@"Sign Message %@ b %@ %f %f\n", self.signMessage, self.block, self.location.coordinate.latitude, self.location.coordinate.latitude);
        return self.signMessage;
    }
    
    if ([self.type isEqualToString:kVehicleTypeStreetcar])
    {
        const ROUTE_COL *col = [TriMetRouteColors rawColorForRoute:self.routeNumber];
        
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
    
    return @"no title";
}


- (NSString*)subtitle
{
    return [VehicleData locatedSomeTimeAgo:TriMetToNSDate(self.locationTime)];
}

// From MapPinColor
- (MKPinAnnotationColor) pinColor
{
        if ([self.type isEqualToString:kVehicleTypeBus])
        {
            return MKPinAnnotationColorPurple;
        }
        
        if ([self.type isEqualToString:kVehicleTypeStreetcar])
        {
            return MKPinAnnotationColorGreen;
        }
        
        return MKPinAnnotationColorRed;
}
- (bool)showActionMenu
{
    if (self.lastLocID)
    {
        return YES;
    }
    return NO;
}

- (bool)mapTapped:(id<BackgroundTaskProgress>) progress
{
    [[DepartureTimesView viewController]  fetchTimesForVehicleAsync:progress route:self.routeNumber direction:self.direction nextLoc:self.lastLocID block:self.block];
    return true;
}

- (NSString *)mapStopId
{
    return self.nextLocID;
}

- (NSString *)mapStopIdText
{
    return [NSString stringWithFormat:@"Arrivals at next stop - ID %@", self.nextLocID];
}



- (NSString *)tapActionText
{
    return @"Show next stops";
}

- (UIColor *)pinTint
{
    return [TriMetRouteColors colorForRoute:self.routeNumber];
}


- (UIColor*)pinSubTint
{
    if (self.block!=nil)
    {
        BlockColorDb *db = [BlockColorDb sharedInstance];
        return [db colorForBlock:self.block];
        
    }
    return nil;
}



- (bool)hasBearing
{
    return self.bearing != nil;
}

- (double)doubleBearing
{
    if (self.bearing)
    {
        return self.bearing.doubleValue;
    }
    return 0.0;
}

@end
