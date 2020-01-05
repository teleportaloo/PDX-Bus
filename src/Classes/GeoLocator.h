//
//  GeoLocator.h
//  PDX Bus
//
//  Created by Andrew Wallace on 8/30/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "TripLegEndPoint.h"

@interface GeoLocator : NSObject

@property (atomic) bool waitingForGeocoder;
@property (atomic, strong) NSError *error;

- (NSMutableArray<TripLegEndPoint*> *)fetchCoordinates:(NSString *)address;

+ (bool)supported;
+ (bool)addressNeedsCoords:(NSString *)address;

@end
