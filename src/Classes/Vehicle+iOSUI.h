//
//  Vehicle.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapPin.h"
#import "TriMetXML.h"
#import "Vehicle.h"
#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#define kNoVehicles                                                            \
    @"PDX Bus could not find a bus or train close by. Note - Streetcar is "    \
    @"not supported.  Try again in a few moments as the vehicle locations "    \
    @"may be updated."

// #define VEHICLE_TEST 1

@interface Vehicle (VehicleUI) <MapPin>

// From Annotation
@property(nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property(nonatomic, readonly, copy) NSString *title;
@property(nonatomic, readonly, copy) NSString *subtitle;
@property(nonatomic, readonly, copy) NSString *key;

@end
