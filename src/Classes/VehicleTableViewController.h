//
//  VehicleTableView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TableViewControllerWithToolbar.h"
#import "XMLLocateVehicles.h"

@interface VehicleTableViewController : TableViewControllerWithToolbar

@property(nonatomic, strong) XMLLocateVehicles *locator;

- (void)fetchNearestVehiclesAsync:(id<TaskController>)taskController
                         location:(CLLocation *)here
                      maxDistance:(double)dist
                backgroundRefresh:(bool)backgroundRefresh;

@end
