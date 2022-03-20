//
//  DirectionView.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "Route+iOS.h"
#import "TableViewControllerWithRefresh.h"
#import "XMLRoutes.h"
#import "XMLDetoursAndMessages.h"

#define kSearchItemRoute @"org.teleportaloo.pdxbus.route"

@interface DirectionView : TableViewControllerWithRefresh

- (void)fetchDirectionsAsync:(id<TaskController>)taskController route:(NSString *)route backgroundRefresh:(bool)backgroundRefresh;
- (void)fetchDirectionsAsync:(id<TaskController>)taskController route:(NSString *)route;
@end
