//
//  StopView.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TableViewControllerWithRefresh.h"
#import "ReturnStopId.h"
#import "Stop.h"
@class XMLStops;
@class DepartureData;


@interface StopView : TableViewControllerWithRefresh<ReturnStop>

@property (nonatomic, strong) XMLStops *stopData;
@property (nonatomic, strong) DepartureData *departure;
@property (nonatomic, copy)   NSString *directionName;

- (void)refreshAction:(id)sender;
- (void)fetchStopsAsync:(id<BackgroundTaskController>)task route:(NSString*)routeid direction:(NSString*)dir description:(NSString *)desc
          directionName:(NSString *)dirName backgroundRefresh:(bool)backgroundRefresh;
- (void)fetchDestinationsAsync:(id<BackgroundTaskController>)task dep:(DepartureData *)dep;

@end
