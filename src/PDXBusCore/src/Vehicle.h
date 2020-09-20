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


#import <Foundation/Foundation.h>
#import "TriMetXML.h"
#import <CoreLocation/CoreLocation.h>
#import "DataFactory.h"


#define kNoVehicles           @"PDX Bus could not find a bus or train close by. Note - Streetcar is not supported.  Try again in a few moments as the vehicle locations may be updated."

#define kVehicleTypeBus       @"bus"
#define kVehicleTypeTrain     @"train"
#define kVehicleTypeStreetcar @"streetcar"

// #define VEHICLE_TEST 1

@interface Vehicle : DataFactory

@property (nonatomic, copy) NSString *signMessageLong;
@property (nonatomic, strong) NSDate *locationTime;
@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, copy) NSString *signMessage;
@property (nonatomic, copy) NSString *routeNumber;
@property (nonatomic, copy) NSString *direction;
@property (nonatomic, copy) NSString *vehicleId;
@property (nonatomic, copy) NSString *nextStopId;
@property (nonatomic, copy) NSString *lastStopId;
@property (nonatomic, copy) NSString *bearing;
@property (nonatomic, copy) NSString *garage;
@property (nonatomic, copy) NSString *block;
@property (nonatomic, copy) NSString *type;
@property (nonatomic) double distance;

- (bool)typeMatchesMode:(TripMode)mode;

+ (NSString *)locatedSomeTimeAgo:(NSDate *)date;

@end
