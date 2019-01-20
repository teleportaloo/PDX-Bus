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


#import "TableViewWithToolbar.h"
#import "XMLLocateVehicles.h"

@interface VehicleTableView : TableViewWithToolbar
{
    bool                _firstTime;
}

@property (nonatomic, strong) XMLLocateVehicles *locator;

- (void)fetchNearestVehiclesAsync:(id<BackgroundTaskController>)task location:(CLLocation *)here maxDistance:(double)dist backgroundRefresh:(bool)backgroundRefresh;

@end
