//
//  FilledCircleView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/5/16.
//  Copyright © 2016 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "FilledCircleView.h"

@implementation FilledCircleView

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code

    CGMutablePathRef fillPath = CGPathCreateMutable();

    CGRect outerSquare;

    CGFloat width = fmin(CGRectGetWidth(rect), CGRectGetHeight(rect));

    outerSquare.origin.x = CGRectGetMidX(rect) - width / 2;
    outerSquare.origin.y = CGRectGetMidY(rect) - width / 2;
    outerSquare.size.width = width;
    outerSquare.size.height = width;

    const CGFloat *colors = CGColorGetComponents(self.fillColor.CGColor);

    CGPathAddEllipseInRect(fillPath, NULL, outerSquare);

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetRGBFillColor(context, colors[0], colors[1], colors[2], 1.0);
    CGContextAddPath(context, fillPath);
    CGContextFillPath(context);

    CGPathRelease(fillPath);
}

@end
