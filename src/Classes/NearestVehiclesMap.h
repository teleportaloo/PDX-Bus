//
//  NearestVehiclesMap.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapViewController.h"
#import "XMLLocateVehicles.h"
#import "XMLLocateStops+iOSUI.h"

@interface NearestVehiclesMap : MapViewController

@property (nonatomic, strong) NSSet<NSString *> *streetcarRoutes;
@property (nonatomic, strong) NSSet<NSString *> *trimetRoutes;
@property (nonatomic, copy)   NSString *direction;
@property (nonatomic)         bool alwaysFetch;
@property (nonatomic)         bool allRoutes;

- (void)fetchNearestVehiclesAsync:(id<TaskController>)taskController;
- (void)fetchNearestVehiclesAndStopsAsync:(id<TaskController>)taskController location:(CLLocation *)here maxToFind:(int)max minDistance:(double)min mode:(TripMode)mode;

@end
