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
	UISegmentedControl *_sortSegment;
	NSString *_info;
	DepartureTimesView *_depView;
	BOOL segSetup;
	
}

@property (nonatomic, retain) UISegmentedControl *sortSegment;
@property (nonatomic, retain) NSString *info;
@property (nonatomic, retain) DepartureTimesView *depView;

- (void)sortSegmentChanged:(id)sender;
- (UISegmentedControl*) createSegmentedControl:(NSArray *)segmentTextContent parent:(UIView *)parent action:(SEL)action;

@end
