//
//  RailStationTableView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/8/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RailStation.h"
#import "Stop.h"
#import "TableViewControllerWithRefresh.h"
#import <UIKit/UIKit.h>

@class RailMapViewController;
@class ShapeRoutePath;

@interface RailStationTableViewController
    : TableViewControllerWithRefresh <ReturnStopObject>

@property(nonatomic, strong) RailMapViewController *map;
@property(nonatomic, strong) RailStation *station;
@property(nonatomic) bool from;

@property(nonatomic, readonly, copy) NSString *actionText;

@property(nonatomic) MKMapRect mapFlyTo;

- (void)returnStopObject:(Stop *)stop progress:(id<TaskController>)progress;
- (void)fetchShapesAndDetoursAsync:(id<TaskController>)taskController;

@end
