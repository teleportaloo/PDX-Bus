//
//  BlockColorView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/2/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BlockColorView.h"

@implementation BlockColorView
@dynamic color;

- (void)setColor:(UIColor *)color
{
    _color = color;
    [self setNeedsDisplay];
}

- (UIColor*)color
{
    return _color;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.color = nil;
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (void)dealloc
{
    self.color = nil;
    
}

- (void)drawRect:(CGRect)rect {
    UIColor *col = self.color;
    
    if (col == nil)
    {
        col = [UIColor clearColor];
    }

    [col setFill];
    UIRectFill( rect );
}


@end
