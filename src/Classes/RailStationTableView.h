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


@interface RailStationTableView : TableViewWithToolbar <UIAlertViewDelegate, ReturnStop> {
	RailStation *               _station;
	RailMapView *               _map;
	bool                        _from;
	StopLocations *             _locationsDb;
    NSMutableArray<NSNumber*> * _routes;
    NSInteger                   _firstLocationRow;
}

@property (nonatomic, retain) RailMapView *map;
@property (nonatomic, retain) RailStation *station;
@property (nonatomic) bool from;
@property (nonatomic, retain) StopLocations *locationsDb;
@property (nonatomic, retain) NSMutableArray<NSNumber*> *routes;


- (void) chosenStop:(Stop *)stop progress:(id<BackgroundTaskProgress>) progress;
@property (nonatomic, readonly, copy) NSString *actionText;



@end
