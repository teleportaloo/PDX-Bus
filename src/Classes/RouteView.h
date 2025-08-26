//
//  RouteView.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BackgroundTaskContainer.h"
#import "TableViewControllerWithRefresh.h"
#import <UIKit/UIKit.h>

@class XMLRoutes;

@interface RouteView : TableViewControllerWithRefresh

- (void)fetchRoutesAsync:(id<TaskController>)taskController
       backgroundRefresh:(bool)backgroundRefresh;

@end
