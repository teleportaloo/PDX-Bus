//
//  XMLLocateVehicles.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "TriMetXMLv2.h"
#import <CoreLocation/CoreLocation.h>
#import "VehicleData.h"

@interface XMLLocateVehicles : TriMetXMLv2<VehicleData*>

@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, strong) NSString  *direction;
@property (nonatomic) bool noErrorAlerts;
@property (nonatomic) double  dist;

- (BOOL)findNearestVehicles:(NSSet<NSString*> *)routes direction:(NSString *)direction blocks:(NSSet<NSString*> *)blocks vehicles:(NSSet<NSString*> *)vehicles;
// - (bool)displayErrorIfNoneFound:(id<BackgroundTaskController>)progress;
@end



