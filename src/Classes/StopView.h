//
//  StopView.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"
#import "ReturnStopId.h"
#import "Stop.h"
@class XMLStops;
@class DepartureData;


@interface StopView : TableViewWithToolbar <ReturnStop>{
	XMLStops *      _stopData;
	DepartureData * _departure;
	NSString *      _directionName;
}

@property (nonatomic, retain) XMLStops *stopData;
@property (nonatomic, retain) DepartureData *departure;
@property (nonatomic, copy)   NSString *directionName;
- (void)refreshAction:(id)sender;
- (void)fetchStopsAsync:(id<BackgroundTaskProgress>) callback route:(NSString*)routeid direction:(NSString*)dir description:(NSString *)desc
				 directionName:(NSString *)dirName;
- (void)fetchDestinationsAsync:(id<BackgroundTaskProgress>) callback dep:(DepartureData *)dep;


@end
