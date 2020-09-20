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

#define kSegRowWidth  320.0
#define kSegRowHeight 50.0
#define kUISegHeight  40.0
#define kUISegWidth   310.0
// #define kUISegWidth          200.0

@interface SegmentCell ()

@property (nonatomic, strong) UISegmentedControl *segment;

@end

@implementation SegmentCell

- (void)createSegmentWithContent:(NSArray *)content target:(NSObject *)target action:(SEL)action {
    CGRect frame = CGRectMake((kSegRowWidth - kUISegWidth) / 2, (kSegRowHeight - kUISegHeight) / 2, kUISegWidth, kUISegHeight);
    
    self.segment = [[UISegmentedControl alloc] initWithItems:content];
    self.segment.frame = frame;
    self.segment.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.isAccessibilityElement = NO;
    [self.segment addTarget:target action:action forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.segment];
    [self layoutSubviews];
}

+ (instancetype)tableView:(UITableView *)tableView reuseIdentifier:(NSString *)reuseIdentifier cellWithContent:(NSArray *)content target:(NSObject *)target action:(SEL)action selectedIndex:(NSInteger)index {
    SegmentCell *cell = (SegmentCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    
    if (cell == nil) {
        cell = [[[self class] alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:reuseIdentifier];
        [cell createSegmentWithContent:content
                                target:target
                                action:action];
    }
    
    cell.segment.selectedSegmentIndex = index;
    return cell;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.imageView) {
        CGFloat imageRight = self.imageView.frame.origin.x + self.imageView.frame.size.width;
        
        if (self.segment.frame.origin.x <= imageRight) {
            CGFloat adjustment = imageRight - self.segment.frame.origin.x + 5;
            
            CGRect frame = self.segment.frame;
            
            frame.origin.x += adjustment;
            frame.size.width -= adjustment;
            
            self.segment.frame = frame;
        }
    }
}

+ (CGFloat)rowHeight {
    return kSegRowHeight;
}

@end
