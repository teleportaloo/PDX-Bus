//
//  SegmentCell.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/27/11.
//  Copyright 2011. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "SegmentCell.h"

#define kSegRowWidth        320.0
#define kSegRowHeight        50.0
#define kUISegHeight        40.0
#define kUISegWidth            310.0
// #define kUISegWidth            200.0

@implementation SegmentCell

- (void)createSegmentWithContent:(NSArray*)content target:(NSObject *)target action:(SEL)action
{
    CGRect frame = CGRectMake((kSegRowWidth-kUISegWidth)/2, (kSegRowHeight - kUISegHeight)/2 , kUISegWidth, kUISegHeight);
    
    self.segment                        = [[UISegmentedControl alloc] initWithItems:content];
    self.segment.frame                    = frame;
    self.segment.autoresizingMask        = UIViewAutoresizingFlexibleWidth;
    [self.segment addTarget:target action:action forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.segment];
    [self layoutSubviews];
}


+ (CGFloat)segmentCellHeight
{
    return kSegRowHeight;
}


@end
