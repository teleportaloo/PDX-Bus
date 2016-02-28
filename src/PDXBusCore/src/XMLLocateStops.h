//
//  XMLLocateStops.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/13/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "TriMetXML.h"
#import "StopDistanceData.h"

@interface XMLLocateStops : TriMetXML {
	StopDistanceData *_currentStop;
	CLLocation *_location;
	
	NSMutableDictionary *_routes;
	
	TripMode _mode;
	int _maxToFind;
	double _minDistance;
	
	
	TripMode _currentMode;
}

@property (nonatomic, retain) NSMutableDictionary *routes;
@property (nonatomic, retain) StopDistanceData *currentStop;
@property (nonatomic, retain) CLLocation *location;
@property (nonatomic) TripMode mode;
@property (nonatomic) int maxToFind;
@property (nonatomic) double minDistance;

- (BOOL)findNearestStops;
- (BOOL)findNearestRoutes;

@end
