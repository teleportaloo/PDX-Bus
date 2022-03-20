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

#define TriMetTypeBus           @"Bus"
#define TriMetTypeMAX           @"MAX"
#define TriMetTypeWES           @"WES"
#define TriMetTypeStreetcar     @"Streetcar"


typedef struct VehicleInfoStruct {
    NSInteger min;
    NSInteger max;
    NSString *type;
    NSString *markedUpManufacturer;
    NSString *markedUpModel;
    NSString *first_used;
    bool check_for_multiple;
    NSString *markedUpSpecialInfo;
    bool locatable;
} VehicleInfo;

typedef const VehicleInfo *PtrConstVehicleInfo;

PtrConstVehicleInfo getTriMetVehicleInfo(void);
size_t noOfTriMetVehicles(void);
int compareVehicle(const void *first, const void *second);

#endif /* TriMetInfoVehicles_h */
