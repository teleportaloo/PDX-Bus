//
//  XMLLocateVehicles.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLLocateVehicles.h"
#import "VehicleData.h"
#import <MapKit/MapKit.h>
#import <MapKit/MKGeometry.h>
#import "XMLStreetcarLocations.h"
#import "StringHelper.h"
#import "UserPrefs.h"
#import "CLLocation+Helper.h"

#define MetersInAMile 1609.344

@implementation XMLLocateVehicles


- (void)cleanup
{
    int i = 0;
    
    for (i=0; i<self.items.count;)
    {
        VehicleData *item = self.items[i];
        
        if (item.signMessage==nil || item.signMessage.length==0)
        {
            [self.items removeObjectAtIndex:i];
        }
        else
        {
            i++;
        }
    }
}

- (BOOL)findNearestVehicles:(NSSet<NSString*> *)routes direction:(NSString*) direction blocks:(NSSet<NSString*> *)blocks vehicles:(NSSet<NSString*> *)vehicles
{
    NSString *query = nil;
    
    NSMutableString *routeIDs     = [NSMutableString string];
    NSMutableString *blockQuery   = [NSMutableString string];
    NSMutableString *vehicleQuery = [NSMutableString string];
    
    if (routes)
    {
        routeIDs = [NSString commaSeparatedStringFromEnumerator:routes selector:@selector(self)];
        [routeIDs insertString:@"/routes/" atIndex:0];
    }
    
    if (blocks)
    {
        blockQuery = [NSString commaSeparatedStringFromEnumerator:blocks selector:@selector(self)];
        [blockQuery insertString:@"/blocks/" atIndex:0];
    }
    
    if (vehicles)
    {
        vehicleQuery = [NSString commaSeparatedStringFromEnumerator:vehicles selector:@selector(self)];
        [vehicleQuery insertString:@"/ids/" atIndex:0];
    }
    
    if (self.dist > 1.0)
    {
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.location.coordinate, self.dist * 2.0, self.dist * 2.0);
        CLLocationCoordinate2D northWestCorner, southEastCorner;
        northWestCorner.latitude  = self.location.coordinate.latitude  - (region.span.latitudeDelta  / 2.0);
        northWestCorner.longitude = self.location.coordinate.longitude + (region.span.longitudeDelta / 2.0);
        southEastCorner.latitude  = self.location.coordinate.latitude  + (region.span.latitudeDelta  / 2.0);
        southEastCorner.longitude = self.location.coordinate.longitude - (region.span.longitudeDelta / 2.0);
    
        double lonmin = fmin(northWestCorner.longitude, southEastCorner.longitude);
        double latmin = fmin(northWestCorner.latitude,  southEastCorner.latitude);
        double lonmax = fmax(northWestCorner.longitude, southEastCorner.longitude);
        double latmax = fmax(northWestCorner.latitude,  southEastCorner.latitude);
    
        query = [NSString stringWithFormat:@"vehicles/bbox/%f,%f,%f,%f/xml/true/onRouteOnly/true%@%@%@",
                          lonmin,latmin, lonmax, latmax, routeIDs, blockQuery, vehicleQuery];
    }
    else
    {
        query = [NSString stringWithFormat:@"vehicles/xml/true/onRouteOnly/true%@%@%@", routeIDs, blockQuery, vehicleQuery];
    }
    
    self.direction = direction;
    
    
    bool res =  [self startParsing:query cacheAction:TriMetXMLNoCaching];
    
    if (self.gotData)
    {
        [self.items sortUsingSelector:NSSelectorFromString(@"compareUsingDistance:")];
        [self cleanup];
    }

    
    return res;
}

XML_START_ELEMENT(resultset)
{
    [self initItems];
    _hasData = YES;
}

XML_START_ELEMENT(vehicle)
{
    NSString *dir = ATRSTR(direction);
    
    if (self.direction == nil || [self.direction isEqualToString:dir])
    {
        
        VehicleData *currentVehicle = [VehicleData data];
        
        currentVehicle.block           = ATRSTR(blockID);
        currentVehicle.nextLocID       = ATRSTR(nextLocID);
        currentVehicle.lastLocID       = ATRSTR(lastLocID);
        currentVehicle.routeNumber     = ATRSTR(routeNumber);
        currentVehicle.direction       = dir;
        currentVehicle.signMessage     = ATRSTR(signMessage);
        currentVehicle.signMessageLong = ATRSTR(signMessageLong);
        currentVehicle.type            = ATRSTR(type);
        currentVehicle.locationTime    = ATRDAT(time);
        currentVehicle.garage          = ATRSTR(garage);
        currentVehicle.bearing         = ATRSTR(bearing);
        currentVehicle.vehicleID       = ATRSTR(vehicleID);
        currentVehicle.location        = ATRLOC(latitude,longitude);
        
        if (self.location != nil)
        {
            currentVehicle.distance = [currentVehicle.location distanceFromLocation:self.location];
        }
        
        
        [self addItem:currentVehicle];
        
    }

}

@end
