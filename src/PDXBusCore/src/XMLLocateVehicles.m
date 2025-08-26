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
#import "CLLocation+Helper.h"
#import "NSDictionary+Types.h"
#import "NSString+Core.h"
#import "Settings.h"
#import "TriMetXMLSelectors.h"
#import "Vehicle.h"
#import "XMLStreetcarLocations.h"
#import <MapKit/MKGeometry.h>
#import <MapKit/MapKit.h>

@interface XMLLocateVehicles () {
}

@property(nonatomic, copy) NSString *direction;

@end

@implementation XMLLocateVehicles

- (void)cleanup {
    int i = 0;

    for (i = 0; i < self.items.count;) {
        Vehicle *item = self.items[i];

        if (item.signMessage == nil || item.signMessage.length == 0) {
            [self.items removeObjectAtIndex:i];
        } else {
            i++;
        }
    }
}

- (bool)findNearestVehicles:(NSSet<NSString *> *)routeIdSet
                  direction:(NSString *)direction
                     blocks:(NSSet<NSString *> *)blockIdSet
                   vehicles:(NSSet<NSString *> *)vehicleIdSet
                      since:(NSDate *)since {
    NSString *query = nil;

    NSMutableString *routeQuery = [NSMutableString string];
    NSMutableString *blockQuery = [NSMutableString string];
    NSMutableString *vehicleQuery = [NSMutableString string];
    NSMutableString *dateQuery = [NSMutableString string];

    if (since) {
        [dateQuery appendFormat:@"/since/%lld", NSDateToTriMet(since)];
    }

    if (routeIdSet) {
        routeQuery =
            [NSString commaSeparatedStringFromStringEnumerator:routeIdSet];
        [routeQuery insertString:@"/routes/" atIndex:0];
    }

    if (blockIdSet) {
        blockQuery =
            [NSString commaSeparatedStringFromStringEnumerator:blockIdSet];
        [blockQuery insertString:@"/blocks/" atIndex:0];
    }

    if (vehicleIdSet) {
        vehicleQuery =
            [NSString commaSeparatedStringFromStringEnumerator:vehicleIdSet];
        [vehicleQuery insertString:@"/ids/" atIndex:0];
    }

    if (self.dist > 1.0) {
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(
            self.location.coordinate, self.dist * 2.0, self.dist * 2.0);
        CLLocationCoordinate2D northWestCorner, southEastCorner;
        northWestCorner.latitude = self.location.coordinate.latitude -
                                   (region.span.latitudeDelta / 2.0);
        northWestCorner.longitude = self.location.coordinate.longitude +
                                    (region.span.longitudeDelta / 2.0);
        southEastCorner.latitude = self.location.coordinate.latitude +
                                   (region.span.latitudeDelta / 2.0);
        southEastCorner.longitude = self.location.coordinate.longitude -
                                    (region.span.longitudeDelta / 2.0);

        double lonmin =
            fmin(northWestCorner.longitude, southEastCorner.longitude);
        double latmin =
            fmin(northWestCorner.latitude, southEastCorner.latitude);
        double lonmax =
            fmax(northWestCorner.longitude, southEastCorner.longitude);
        double latmax =
            fmax(northWestCorner.latitude, southEastCorner.latitude);

        query = [NSString
            stringWithFormat:
                @"vehicles/bbox/%@,%@,%@,%@/xml/true/onRouteOnly/true%@%@%@%@",
                COORD_TO_STR(lonmin), COORD_TO_STR(latmin),
                COORD_TO_STR(lonmax), COORD_TO_STR(latmax), routeQuery,
                blockQuery, vehicleQuery, dateQuery];
    } else {
        query = [NSString
            stringWithFormat:@"vehicles/xml/true/onRouteOnly/true%@%@%@%@",
                             routeQuery, blockQuery, vehicleQuery, dateQuery];
    }

    self.direction = direction;

    bool res = [self startParsing:query cacheAction:TriMetXMLNoCaching];

    if (self.gotData) {
        [self.items
            sortUsingSelector:NSSelectorFromString(@"compareUsingDistance:")];
        [self cleanup];
    }

    return res;
}

XML_START_ELEMENT(resultSet) {
    [self initItems];
    _hasData = YES;
}

XML_START_ELEMENT(vehicle) {
    NSString *dir = XML_NON_NULL_ATR_STR(@"direction");

    if (self.direction == nil || [self.direction isEqualToString:dir]) {
        Vehicle *currentVehicle = [Vehicle new];

        currentVehicle.block = XML_NON_NULL_ATR_STR(@"blockID");
        currentVehicle.nextStopId = XML_NON_NULL_ATR_STR(@"nextLocID");
        currentVehicle.lastStopId = XML_NULLABLE_ATR_STR(@"lastLocID");
        currentVehicle.routeNumber = XML_NON_NULL_ATR_STR(@"routeNumber");
        currentVehicle.direction = dir;
        currentVehicle.signMessage = XML_NON_NULL_ATR_STR(@"signMessage");
        currentVehicle.signMessageLong =
            XML_NON_NULL_ATR_STR(@"signMessageLong");
        currentVehicle.type = XML_NON_NULL_ATR_STR(@"type");
        currentVehicle.locationTime = XML_ATR_DATE(@"time");
        currentVehicle.garage = XML_NON_NULL_ATR_STR(@"garage");
        currentVehicle.bearing = XML_NON_NULL_ATR_STR(@"bearing");
        currentVehicle.vehicleId = XML_NON_NULL_ATR_STR(@"vehicleID");
        currentVehicle.location = XML_ATR_LOCATION(@"latitude", @"longitude");
        currentVehicle.loadPercentage =
            XML_ATR_INT_OR_MISSING(@"loadPercentage", kNoLoadPercentage);
        currentVehicle.inCongestion =
            XML_ATR_BOOL_DEFAULT_FALSE(@"inCongestion");
        currentVehicle.offRoute = XML_ATR_BOOL_DEFAULT_FALSE(@"offRoute");
        currentVehicle.delay = XML_NULLABLE_ATR_STR(@"delay");

        if (self.location != nil) {
            currentVehicle.distance =
                [currentVehicle.location distanceFromLocation:self.location];
        }

        [self addItem:currentVehicle];
    }
}

@end
