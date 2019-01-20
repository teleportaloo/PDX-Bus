//
//  FilledCircleView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/5/16.
//  Copyright © 2016 Teleportaloo. All rights reserved.
//

#import "FilledCircleView.h"

@implementation FilledCircleView

@synthesize fillColor = _fillColor;


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
// Drawing code

    CGMutablePathRef fillPath = CGPathCreateMutable();

    // CGPathAddRects(fillPath, NULL, &rect, 1);

    CGRect outerSquare;

    CGFloat width = fmin(CGRectGetWidth(rect), CGRectGetHeight(rect));

    outerSquare.origin.x = CGRectGetMidX(rect) - width/2;
    outerSquare.origin.y = CGRectGetMidY(rect) - width/2;
    outerSquare.size.width = width;
    outerSquare.size.height = width;
    
    const CGFloat *colors =  CGColorGetComponents(self.fillColor.CGColor);


    CGPathAddEllipseInRect(fillPath, NULL, outerSquare);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, colors[0] , colors[1], colors[2], 1.0);
    CGContextAddPath(context, fillPath);
    CGContextFillPath(context);
    
    
    //    DEBUG_LOG(@"%f %f %f\n", _red, _green, _blue);
    
    CGPathRelease(fillPath);
    
}


@end
