//
//  DepartureSortTableView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/17/09.
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
