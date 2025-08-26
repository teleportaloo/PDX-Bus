//
//  NearestRoutesView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 1/9/11.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TableViewControllerWithToolbar.h"
#import "XMLLocateStops+iOSUI.h"
#import <UIKit/UIKit.h>

@interface NearestRoutesViewController : TableViewControllerWithToolbar

- (void)fetchNearestRoutesAsync:(id<TaskController>)taskController
                       location:(CLLocation *)here
                      maxToFind:(int)max
                    minDistance:(double)min
                           mode:(TripMode)mode;

@end
