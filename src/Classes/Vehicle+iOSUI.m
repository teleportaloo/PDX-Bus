//
//  Vehicle.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Vehicle+iOSUI.h"
#import "DepartureTimesView.h"
#import "TriMetInfo.h"
#import "DebugLogging.h"
#import "BlockColorDb.h"

@class DepartureTimesView;

@implementation Vehicle (VehicleUI)


- (CLLocationCoordinate2D) coordinate
{
    return self.location.coordinate;
}

- (NSString*)title
{
    if (self.signMessage)
    {
        // DEBUG_LOG(@"Sign Message %@ b %@ %f %f\n", self.signMessage, self.block, self.location.coordinate.latitude, self.location.coordinate.latitude);
        return self.signMessage;
    }
    
    if ([self.type isEqualToString:kVehicleTypeStreetcar])
    {
        PC_ROUTE_INFO info = [TriMetInfo infoForRoute:self.routeNumber];
        
        if (info)
        {
            return info->full_name;
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
    NSString *located = [Vehicle locatedSomeTimeAgo:self.locationTime];
    
    if (self.vehicleID)
    {
        return [NSString stringWithFormat:@"ID %@ %@", self.vehicleID, located];
    }
    
    return located;
}

// From MapPinColor
- (MapPinColorValue) pinColor
{
        if ([self.type isEqualToString:kVehicleTypeBus])
        {
            return MAP_PIN_COLOR_PURPLE;
        }
        
        if ([self.type isEqualToString:kVehicleTypeStreetcar])
        {
            return MAP_PIN_COLOR_GREEN;
        }
        
        return MAP_PIN_COLOR_RED;
}
- (bool)showActionMenu
{
    if (self.lastLocID)
    {
        return YES;
    }
    return NO;
}

- (bool)mapTapped:(id<BackgroundTaskController>) progress
{
    [[DepartureTimesView viewController]  fetchTimesForVehicleAsync:progress route:self.routeNumber direction:self.direction nextLoc:self.lastLocID block:self.block targetDeparture:nil];
    return true;
}

- (NSString *)mapStopId
{
    return self.nextLocID;
}

- (NSString *)mapStopIdText
{
    return [NSString stringWithFormat:@"Departures at next stop - ID %@", self.nextLocID];
}



- (NSString *)tapActionText
{
    return @"Show next stops";
}

- (UIColor *)pinTint
{
    return [TriMetInfo colorForRoute:self.routeNumber];
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
