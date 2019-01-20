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

@interface XMLLocateStops : TriMetXML<StopDistanceData*> {
    TripMode                _currentMode;
}

@property (nonatomic, strong) StopDistanceData *currentStop;
@property (nonatomic, strong) NSMutableDictionary *routes;
@property (nonatomic, readonly) BOOL findNearestRoutes;
@property (nonatomic, readonly) BOOL findNearestStops;
@property (nonatomic, strong) CLLocation *location;
@property (nonatomic) double minDistance;
@property (nonatomic) TripMode mode;
@property (nonatomic) int maxToFind;
@property (nonatomic) bool includeRoutesInStops;

@end
