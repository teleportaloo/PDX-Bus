//
//  TripPlannerOptions.h
//  PDX Bus
//
//  Created by Andrew Wallace on 8/15/09.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"
#import "XMLTrips.h"
#import "TripPlannerBaseView.h"

@interface TripPlannerOptions : TripPlannerBaseView {
	UISegmentedControl *_walkSegment;
	UISegmentedControl *_modeSegment;
	UISegmentedControl *_minSegment;
	NSString *_info;	
}

@property (nonatomic, retain) UISegmentedControl *walkSegment;
@property (nonatomic, retain) UISegmentedControl *modeSegment;
@property (nonatomic, retain) UISegmentedControl *minSegment;
@property (nonatomic, retain) NSString *info;

- (void)walkSegmentChanged:(id)sender;
- (void)modeSegmentChanged:(id)sender;
- (void)minSegmentChanged:(id)sender;
- (UISegmentedControl*) createSegmentedControl:(NSArray *)segmentTextContent parent:(UIView *)parent action:(SEL)action;

@end
