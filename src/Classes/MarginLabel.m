//
//  MarginLabel.m
//  PDX Bus
//
//  Created by Andy Wallace on 9/11/22.
//  Copyright © 2022 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MarginLabel.h"

@implementation MarginLabel

- (void)drawTextInRect:(CGRect)rect {

    UIEdgeInsets insets = UIEdgeInsetsMake(self.topInset, self.leftInset,
                                           self.bottomInset, self.rightInset);
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

- (CGSize)intrinsicContentSize {
    CGSize size = super.intrinsicContentSize;
    return CGSizeMake(size.width + self.leftInset + self.rightInset,
                      size.height + self.topInset + self.bottomInset);
}

- (void)setBounds:(CGRect)newBounds {
    [super setBounds:newBounds];
    self.preferredMaxLayoutWidth =
        self.bounds.size.width - (self.leftInset + self.rightInset);
}

@end
