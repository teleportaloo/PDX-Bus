//
//  ArrivalDetail.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Stop.h"
#import "TableViewControllerWithRefresh.h"
#import <UIKit/UIKit.h>

@class XMLDetours;
@class Departure;
@class XMLDepartures;
@class XMLLocateVehicles;
@class ShapeRoutePath;

@protocol DepartureDetailDelegate

- (void)detailsChanged;

@end

@interface DepartureDetailViewController
    : TableViewControllerWithRefresh <ReturnStopObject>

@property(nonatomic, weak) id<DepartureDetailDelegate> delegate;
@property(nonatomic, copy) NSString *stops;
@property(nonatomic, assign) bool allowBrowseForDestination;

- (void)fetchDepartureAsync:(id<TaskController>)taskController
                        dep:(Departure *)dep
              allDepartures:(NSArray *)deps
          backgroundRefresh:(bool)backgroundRefresh;

- (void)fetchDepartureAsync:(id<TaskController>)taskController
                     stopId:(NSString *)loc
                      block:(NSString *)block
                        dir:(NSString *)direction
          backgroundRefresh:(bool)backgroundRefresh;

@end
