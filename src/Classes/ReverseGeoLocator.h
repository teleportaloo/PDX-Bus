//
//  ReverseGeoLocator.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/2/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface ReverseGeoLocator : NSObject
{
    bool        _waitingForGeocoder;
    NSString *  _result;
    NSError *   _error;
    
}

@property (atomic) bool waitingForGeocoder;
@property (atomic, retain) NSString *result;
@property (atomic, retain) NSError *error;

+ (bool) supported;
- (NSString *)fetchAddress:(CLLocation*)loc;





@end
