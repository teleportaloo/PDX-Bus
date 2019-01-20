//
//  TripPlannerOptions.h
//  PDX Bus
//
//  Created by Andrew Wallace on 8/15/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"
#import "XMLTrips.h"
#import "TripPlannerBaseView.h"

@interface TripPlannerOptions : TripPlannerBaseView

@property (nonatomic, strong) UISegmentedControl *walkSegment;
@property (nonatomic, strong) UISegmentedControl *modeSegment;
@property (nonatomic, strong) UISegmentedControl *minSegment;
@property (nonatomic, copy)   NSString *info;

- (void)walkSegmentChanged:(id)sender;
- (void)modeSegmentChanged:(id)sender;
- (void)minSegmentChanged:(id)sender;
- (UISegmentedControl*) createSegmentedControl:(NSArray *)segmentTextContent parent:(UIView *)parent action:(SEL)action;

@end
