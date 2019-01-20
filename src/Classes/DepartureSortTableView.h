//
//  DepartureSortTableView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/17/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"

@class DepartureTimesView;


@interface DepartureSortTableView : TableViewWithToolbar {
	BOOL                    _segSetup;
}

@property (nonatomic, strong) UISegmentedControl *sortSegment;
@property (nonatomic, copy)   NSString *info;
@property (nonatomic, strong) DepartureTimesView *depView;

- (void)sortSegmentChanged:(id)sender;
- (UISegmentedControl*) createSegmentedControl:(NSArray *)segmentTextContent parent:(UIView *)parent action:(SEL)action;

@end
