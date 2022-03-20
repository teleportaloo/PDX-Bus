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
#import "StopDistance.h"
#import "RouteDistance.h"

@interface XMLLocateStops : TriMetXML<StopDistance*>

@property (nonatomic) unsigned int maxToFind;
@property (nonatomic) double minDistance;
@property (nonatomic) TripMode mode;
@property (nonatomic, strong) CLLocation *location;
@property (nonatomic) bool includeRoutesInStops;

@property (nonatomic, strong) NSMutableArray<RouteDistance *> *routes;

- (bool)findNearestRoutes;
- (bool)findNearestStops;

@end
