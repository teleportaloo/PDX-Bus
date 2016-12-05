//
//  TripEndPoint.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "DataFactory.h"


#define kAcquiredLocation @"<Acquired GPS Location>"

@interface TripEndPoint : DataFactory {
	bool        _useCurrentLocation;
	NSString *  _locationDesc;
	NSString *  _additionalInfo;
	CLLocation *_coordinates;
}

@property (nonatomic, retain) NSString  *locationDesc;
@property (nonatomic, retain) NSString  *additionalInfo;
@property (nonatomic, retain) CLLocation  *coordinates;
@property (nonatomic) bool useCurrentLocation;

- (NSString *)toQuery:(NSString *)toOrFrom;

@property (nonatomic, readonly, copy) NSDictionary *toDictionary;
- (bool)readDictionary:(NSDictionary *)dict;
- (bool)equalsTripEndPoint:(TripEndPoint*)endPoint;
+ (instancetype)fromDictionary:(NSDictionary *)dict;
@property (nonatomic, readonly, copy) NSString *displayText;
@property (nonatomic, readonly, copy) NSString *userInputDisplayText;


@end
