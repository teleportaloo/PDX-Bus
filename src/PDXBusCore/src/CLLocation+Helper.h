//
//  CLLocation+Helper.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/25/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

#define COORD_FORMAT @"%.13f"
#define COORD_TO_STR(X) [NSString stringWithFormat:COORD_FORMAT, (X)]
#define COORD_TO_LAT_LNG_STR(C)                                                \
    [NSString stringWithFormat:COORD_FORMAT @"," COORD_FORMAT, (C).latitude,   \
                               (C).longitude]
#define COORD_TO_LNG_LAT_STR(C)                                                \
    [NSString stringWithFormat:COORD_FORMAT @"," COORD_FORMAT, (C).longitude,  \
                               (C).latitude]

@interface CLLocation (Helper)

+ (instancetype)withLat:(CLLocationDegrees)lat lng:(CLLocationDegrees)lng;
+ (instancetype)fromStringsLat:(NSString *)lat lng:(NSString *)lng;

@end
