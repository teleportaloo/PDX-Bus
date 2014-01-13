//
//  VehicleLocatingTableView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//

#import "LocatingView.h"
#import "Vehicle.h"

#ifdef VEHICLE_TEST
#define kVehicleDistance 0
#else
#define kVehicleDistance 800
#endif

@interface VehicleLocatingTableView : LocatingView<LocatingViewDelegate>

@end
