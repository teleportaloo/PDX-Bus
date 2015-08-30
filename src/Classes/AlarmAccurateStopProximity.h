//
//  AlarmAccurateStopProximity.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/11/11.
//  Copyright 2011 Teleportaloo. All rights reserved.
//




/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */




#import <Foundation/Foundation.h>
#import "AlarmTask.h"
#import "MapPinColor.h"
#import "UserPrefs.h"

@interface AlarmAccurateStopProximity : AlarmTask <CLLocationManagerDelegate, MapPinColor>
{
	CLLocation	*_destination;
	bool		_accurate;
	CLLocationManager *_locationManager;
    bool        _updating;
    bool        _significant;
}

@property (nonatomic, retain)	CLLocation *destination;
@property (retain)				CLLocationManager *locationManager;
	  
- (void)setStop:(NSString *)stopId lat:(NSString *)lat lng:(NSString *)lng desc:(NSString *)desc;
- (void)cancelAlert;
- (id)initWithAccuracy:(bool)accurate;
- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;
- (void)startMonitoringSignificantLocationChanges;
- (void)stopMonitoringSignificantLocationChanges;
+ (bool)backgroundLocationAuthorizedOrNotDeterminedShowMsg:(bool)msg;


@end
