//
//  TripEndPoint.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


#define kAcquiredLocation @"Acquired GPS Location"

@interface TripEndPoint : NSObject {
	bool _useCurrentLocation;
	NSString *_locationDesc;
	NSString *_additionalInfo;
	CLLocation *_currentLocation;
}

@property (nonatomic, retain) NSString  *locationDesc;
@property (nonatomic, retain) NSString  *additionalInfo;
@property (nonatomic, retain) CLLocation  *currentLocation;
@property (nonatomic) bool useCurrentLocation;

- (NSString *)toQuery:(NSString *)toOrFrom;

- (NSDictionary *)toDictionary;
- (bool)fromDictionary:(NSDictionary *)dict;
- (bool) equalsTripEndPoint:(TripEndPoint*)endPoint;
- (id)initFromDict:(NSDictionary *)dict;
- (NSString *)displayText;
- (NSString *)userInputDisplayText;


@end
