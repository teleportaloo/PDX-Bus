//
//  TripPlannerBookmarkView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/3/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"


@interface TripPlannerBookmarkView : TableViewWithToolbar

@property (nonatomic) bool from;

- (void)fetchNamesForStopIdsAsync:(id<TaskController>)taskController stopIds:(NSString *)stopIds;

@end
