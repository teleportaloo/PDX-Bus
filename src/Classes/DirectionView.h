//
//  DirectionView.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "Route.h"
#import "TableViewWithToolbar.h"
#import "ReturnStopId.h"
#import "XMLRoutes.h"


@interface DirectionView : TableViewWithToolbar {
	Route *_route;
	XMLRoutes *_directionData;
	NSArray *_directionKeys;
	NSString *_routeId;
}

@property (nonatomic, retain) Route *route;
@property (nonatomic, retain) NSArray *directionKeys;
@property (nonatomic, retain) XMLRoutes *directionData;
@property (nonatomic, retain) NSString *routeId;

- (void)fetchDirectionsInBackground:(id<BackgroundTaskProgress>)callback route:(NSString *)route;


@end
