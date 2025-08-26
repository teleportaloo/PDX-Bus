//
//  RoundedTransparentRectView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 3/14/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RoundedTransparentRectView.h"

@interface RoundedTransparentRectView ()

@end

@implementation RoundedTransparentRectView

- (instancetype)initWithFrame:(CGRect)frame {
    return [super initWithFrame:frame];
}

- (void)drawRect:(CGRect)rect {
    static const CGFloat cornerRadius = 10.0;

    CGMutablePathRef roundRectPath = CGPathCreateMutable();
    CGPathAddRoundedRect(roundRectPath, NULL, rect, cornerRadius, cornerRadius);

    CGPathCloseSubpath(roundRectPath);

    CGContextRef context = UIGraphicsGetCurrentContext();

    const CGFloat *components = CGColorGetComponents(self.color.CGColor);

    self.alpha = components[3];

    CGContextSetRGBFillColor(context, components[0], components[1],
                             components[2], components[3]);
    CGContextAddPath(context, roundRectPath);
    CGContextFillPath(context);

    CGContextSetRGBStrokeColor(context, 1, 1, 1, 0.25);
    CGContextAddPath(context, roundRectPath);
    CGContextStrokePath(context);

    CGPathRelease(roundRectPath);
}

@end
