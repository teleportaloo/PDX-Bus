//
//  AlignedBarItemButton.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/1/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AlignedBarItemButton.h"

@implementation AlignedBarItemButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (UIButton*)suitableButtonRight:(bool)right
{
    UIButton *button = nil;

    AlignedBarItemButton *alignedButton = [AlignedBarItemButton buttonWithType:UIButtonTypeCustom];
    alignedButton.right = right;
    button = alignedButton;
    
    return button;
}

- (UIEdgeInsets)alignmentRectInsets {
    
    UIEdgeInsets insets;
    if (!self.right) {
        insets = UIEdgeInsetsMake(0, 9.0f, 0, 0);
    }
    else { // IF_ITS_A_RIGHT_BUTTON
        insets = UIEdgeInsetsMake(0, 0, 0, 9.0f);
    }
    return insets;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
