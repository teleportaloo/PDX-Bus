//
//  ArrivalDetail.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TableViewControllerWithRefresh.h"
#import "../3rd Party/InfColorPicker/InfColorPicker.h"
#import "Stop.h"



@class XMLDetours;
@class Departure;
@class XMLDepartures;
@class XMLLocateVehicles;
@class ShapeRoutePath;

@protocol DepartureDetailDelegate

- (void)detailsChanged;

@end

@interface DepartureDetailView : TableViewControllerWithRefresh <InfColorPickerControllerDelegate, ReturnStop>

@property (nonatomic, weak) id<DepartureDetailDelegate> delegate;
@property (nonatomic, copy)   NSString *stops;
@property (nonatomic, assign) bool allowBrowseForDestination;

- (void)fetchDepartureAsync:(id<TaskController>)taskController
                        dep:(Departure *)dep
              allDepartures:(NSArray *)deps
          backgroundRefresh:(bool)backgroundRefresh;

- (void)fetchDepartureAsync:(id<TaskController>)taskController
                     stopId:(NSString *)loc
                      block:(NSString *)block
          backgroundRefresh:(bool)backgroundRefresh;


@end
