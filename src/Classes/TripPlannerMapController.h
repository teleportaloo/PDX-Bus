//
//  TripPlannerMap.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/31/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapViewController.h"
#import "XMLTrips.h"
#import <Foundation/Foundation.h>

@interface TripPlannerMapController : MapViewController

@property(nonatomic, strong) TripItinerary *it;

- (void)fetchShapesAsync:(id<TaskController>)taskController;

@end
