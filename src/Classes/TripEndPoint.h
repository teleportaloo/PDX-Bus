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


#define kAcquiredLocation @"<Acquired GPS Location>"

@interface TripEndPoint : NSObject {
	bool _useCurrentLocation;
	NSString *_locationDesc;
	NSString *_additionalInfo;
	CLLocation *_coordinates;
}

@property (nonatomic, retain) NSString  *locationDesc;
@property (nonatomic, retain) NSString  *additionalInfo;
@property (nonatomic, retain) CLLocation  *coordinates;
@property (nonatomic) bool useCurrentLocation;

- (NSString *)toQuery:(NSString *)toOrFrom;

- (NSDictionary *)toDictionary;
- (bool)fromDictionary:(NSDictionary *)dict;
- (bool) equalsTripEndPoint:(TripEndPoint*)endPoint;
- (id)initFromDict:(NSDictionary *)dict;
- (NSString *)displayText;
- (NSString *)userInputDisplayText;


@end
