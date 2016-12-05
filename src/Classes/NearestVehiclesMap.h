//
//  NearestVehiclesMap.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapViewController.h"
#import "XMLLocateVehicles.h"
#import "XMLLocateStops+iOSUI.h"

@interface NearestVehiclesMap : MapViewController
{
    XMLLocateVehicles * _locator;
    XMLLocateStops *    _stopLocator;
    NSSet *             _streetcarRoutes;
    NSSet *             _triMetRoutes;
    NSString *          _direction;
    bool                _alwaysFetch;
}

@property (nonatomic, retain) NSSet *streetcarRoutes;
@property (nonatomic, retain) NSSet *trimetRoutes;
@property (nonatomic, copy)   NSString *direction;
@property (nonatomic) bool alwaysFetch;
@property (nonatomic, retain) XMLLocateStops *stopLocator;

@property (nonatomic, retain) XMLLocateVehicles *locator;
- (void)fetchNearestVehiclesAsync:(id<BackgroundTaskProgress>)background;
- (void)fetchNearestVehiclesAndStopsAsync:(id<BackgroundTaskProgress>)background location:(CLLocation *)here maxToFind:(int)max minDistance:(double)min mode:(TripMode)mode;




@end
