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

@interface NearestVehiclesMap : MapViewController
{
    XMLLocateVehicles *_locator;
}


@property (nonatomic, retain) XMLLocateVehicles *locator;
- (void)fetchNearestVehiclesInBackground:(id<BackgroundTaskProgress>)background location:(CLLocation *)here maxDistance:(double)dist;


@end
