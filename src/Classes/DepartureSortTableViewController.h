//
//  DepartureSortTableViewController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/17/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TableViewControllerWithToolbar.h"
#import <UIKit/UIKit.h>

@class DepartureTimesViewController;

@interface DepartureSortTableViewController : TableViewControllerWithToolbar

@property(nonatomic, strong) DepartureTimesViewController *depView;

- (void)sortSegmentChanged:(id)sender;

@end
