//
//  RouteView.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"
#import "ReturnStopId.h"
#import "BackgroundTaskContainer.h"

@class XMLRoutes;



@interface RouteView : TableViewWithToolbar {
	XMLRoutes *_routeData;
}

- (void)fetchRoutesAsync:(id<BackgroundTaskProgress>)callback;
- (void)refreshAction:(id)sender;

@property (nonatomic, retain) XMLRoutes *routeData;

@end
