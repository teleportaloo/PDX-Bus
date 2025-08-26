//
//  TriMetInfoVehicles.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#ifndef TriMetInfoVehicles_h
#define TriMetInfoVehicles_h

#import <Foundation/Foundation.h>

#define NO_VEHICLE_ID (-1)

#define TriMetTypeBus @"Bus"
#define TriMetTypeMAX @"MAX"
#define TriMetTypeWES @"WES"
#define TriMetTypeStreetcar @"Streetcar"

typedef struct VehicleInfoStruct {
    NSInteger vehicleIdMin;
    NSInteger vehicleIdMax;
    NSString *type;
    NSString *markedUpManufacturer;
    NSString *markedUpModel;
    NSString *first_used;
    bool check_for_multiple;
    NSString *fuel;
    bool locatable;
} TriMetInfo_Vehicle;

typedef const TriMetInfo_Vehicle *TriMetInfo_VehicleConstPtr;

typedef struct VehicleInfoSpecial {
    NSInteger vehicleId;
    NSString *markedUpSpecialInfo;
} TriMetInfo_VehicleSpecial;

typedef const TriMetInfo_VehicleSpecial *TriMetInfo_VehicleSpecialConstPtr;

TriMetInfo_VehicleConstPtr TriMetInfo_getVehicle(void);
TriMetInfo_VehicleSpecialConstPtr TriMetInfo_getVehicleSpecial(void);

size_t TriMetInfo_noOfVehicles(void);
size_t TriMetInfo_noOfVehicleSpecials(void);

int TriMetInfo_compareVehicle(const void *first, const void *second);
int TriMetInfo_compareVehicleSpecial(const void *first, const void *second);

#endif /* TriMetInfoVehicles_h */
