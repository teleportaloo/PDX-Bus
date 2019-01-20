//
//  RailStationTableView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/8/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"
#import "StopLocations.h"
#import "Stop.h"
#import "RailStation.h"

@class RailMapView;
@class ShapeRoutePath;


@interface RailStationTableView : TableViewWithToolbar <ReturnStop>
{
    NSInteger                           _firstLocationRow;
}

@property (nonatomic, strong) RailMapView *map;
@property (nonatomic, strong) RailStation *station;
@property (nonatomic) bool from;
@property (nonatomic, strong) StopLocations *locationsDb;
@property (nonatomic, strong) NSMutableArray<NSNumber*> *routes;
@property (nonatomic, readonly, copy) NSString *actionText;
@property (nonatomic, strong) NSMutableArray<ShapeRoutePath*>* shapes;

- (void) chosenStop:(Stop *)stop progress:(id<BackgroundTaskController>) progress;
- (void)maybeFetchRouteShapesAsync:(id<BackgroundTaskController>)task;

@end
