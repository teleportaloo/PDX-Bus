//
//  ShapeCoord.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/8/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ShapeCoord.h"

@interface ShapeCoord () {
    CLLocationCoordinate2D _coord;
}

@end

@implementation ShapeCoord

@dynamic longitude;
@dynamic latitude;

+ (instancetype)coordWithLat:(CLLocationDegrees)lat lng:(CLLocationDegrees)lng {
    ShapeCoord *coord = [[[self class] alloc] init];
    
    coord.latitude = lat;
    coord.longitude = lng;
    
    return coord;
}

- (CLLocationDegrees)latitude {
    return _coord.latitude;
}

- (CLLocationDegrees)longitude {
    return _coord.longitude;
}

- (void)setLatitude:(CLLocationDegrees)val {
    _coord.latitude = val;
}

- (void)setLongitude:(CLLocationDegrees)val {
    _coord.longitude = val;
}

- (instancetype)init {
    if ((self = [super init])) {
    }
    
    return self;
}

@end
