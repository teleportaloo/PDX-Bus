//
//  SegmentCell.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/27/11.
//  Copyright 2011. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>


@interface SegmentCell : UITableViewCell {
	UISegmentedControl *_segment;
}

@property (nonatomic, retain) UISegmentedControl *segment;


- (void)createSegmentWithContent:(NSArray*)content target:(NSObject *)target action:(SEL)action;
+ (CGFloat)segmentCellHeight;



@end
