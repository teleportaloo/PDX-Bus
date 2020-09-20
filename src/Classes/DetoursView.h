//
//  DetoursView.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TableViewControllerWithRefresh.h"
#import "XMLDetoursAndMessages.h"
#import "DetoursForRoute.h"

@interface DetoursView : TableViewControllerWithRefresh<DetoursForRoute *>

- (void)fetchDetoursAsync:(id<TaskController>)taskController;

- (void)fetchDetoursAsync:(id<TaskController>)taskController
                    route:(NSString *)route;

- (void)fetchDetoursAsync:(id<TaskController>)taskController
                   routes:(NSArray *)routes
        backgroundRefresh:(bool)backgroundRefresh;

@end
