//
//  ReverseGeoLocator.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/2/14.
//  Copyright (c) 2014 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface ReverseGeoLocator : NSObject

@property (atomic) bool waitingForGeocoder;
@property (atomic, strong) NSString *result;
@property (atomic, strong) NSError *error;

- (NSString *)fetchAddress:(CLLocation *)loc;

+ (bool)supported;

@end
