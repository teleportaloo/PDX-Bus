//
//  VehicleLocatingTableView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "LocatingView.h"
#import "VehicleData.h"

#ifdef VEHICLE_TEST
#define kVehicleDistance 0
#else
#define kVehicleDistance 800
#endif

@interface VehicleLocatingTableView : LocatingView<LocatingViewDelegate>

@end
