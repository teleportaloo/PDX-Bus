//
//  BlockColorView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/2/17.
//  Copyright © 2017 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BlockColorView.h"

@interface BlockColorView () {
    UIColor *_color;
}

@end

@implementation BlockColorView
@dynamic color;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _color = nil;
        self.backgroundColor = [UIColor clearColor];
    }

    return self;
}

- (void)dealloc {
    _color = nil;
}

- (void)setColor:(UIColor *)color {
    _color = color;
    [self setNeedsDisplay];
}

- (UIColor *)color {
    return _color;
}

- (void)drawRect:(CGRect)rect {
    UIColor *col = self.color;

    if (col == nil) {
        col = [UIColor clearColor];
    }

    [col setFill];
    UIRectFill(rect);
}

@end
