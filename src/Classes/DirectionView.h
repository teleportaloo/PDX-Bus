//
//  DirectionView.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "Route+iOS.h"
#import "TableViewControllerWithRefresh.h"
#import "ReturnStopId.h"
#import "XMLRoutes.h"
#import "XMLDetoursAndMessages.h"

#define kSearchItemRoute @"org.teleportaloo.pdxbus.route"

@interface DirectionView : TableViewControllerWithRefresh
{
    CacheAction _cacheAction;
    bool        _appeared;
}

@property (nonatomic, strong) Route *route;
@property (nonatomic, strong) NSArray *directionKeys;
@property (nonatomic, strong) XMLRoutes *directionData;
@property (nonatomic, strong) XMLDetoursAndMessages *detourData;
@property (nonatomic, copy)   NSString *routeId;

- (void)fetchDirectionsAsync:(id<BackgroundTaskController>)task route:(NSString *)route backgroundRefresh:(bool)backgroundRefresh;
- (void)fetchDirectionsAsync:(id<BackgroundTaskController>)task route:(NSString *)route;
@end
