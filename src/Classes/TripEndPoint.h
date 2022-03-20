//
//  TripEndPoint.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define kAcquiredLocation @"<Acquired GPS Location>"

@interface TripEndPoint : NSObject

@property (nonatomic, strong) NSString *locationDesc;
@property (nonatomic, strong) NSString *additionalInfo;
@property (nonatomic, strong) CLLocation *coordinates;
@property (nonatomic) bool useCurrentLocation;
@property (nonatomic, readonly, copy) NSDictionary *toDictionary;
@property (nonatomic, readonly, copy) NSString *displayText;
@property (nonatomic, readonly, copy) NSString *markedUpUserInputDisplayText;

- (NSString *)toQuery:(NSString *)toOrFrom;
- (bool)readDictionary:(NSDictionary *)dict;
- (bool)equalsTripEndPoint:(TripEndPoint *)endPoint;
- (void)resetCurrentLocation;

+ (instancetype)fromDictionary:(NSDictionary *)dict;

@end
