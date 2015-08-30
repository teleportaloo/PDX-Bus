//
//  XMLLocateVehicles.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "TriMetXML.h"
#import <CoreLocation/CoreLocation.h>
#import "VehicleData.h"
#import "BackgroundTaskProgress.h"

@interface XMLLocateVehicles : TriMetXML
{
    CLLocation *_location;
    double     _dist;

}

@property (nonatomic, retain) CLLocation *location;
@property (nonatomic)         double     dist;

- (BOOL)findNearestVehicles;
- (bool)displayErrorIfNoneFound:(id<BackgroundTaskProgress>)progress;
@end



