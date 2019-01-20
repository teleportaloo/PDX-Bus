//
//  RouteColorBlobView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/6/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RouteColorBlobView.h"
#import "DebugLogging.h"
#import "TriMetInfo.h"

@implementation RouteColorBlobView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}

- (bool)setRouteColorLine:(RAILLINES)line
{
    PC_ROUTE_INFO info = [TriMetInfo infoForLine:line];
    
    if (info !=nil)
    {
        _red    = COL_HTML_R(info->html_color);
        _green    = COL_HTML_G(info->html_color);
        _blue    = COL_HTML_B(info->html_color);
        _square = info->streetcar;
        self.hidden    = NO;
        [self setNeedsDisplay];
    }
    else 
    {
        self.hidden = YES;
        [self setNeedsDisplay];
    }
    
    self.backgroundColor = [UIColor clearColor];
    
    return !self.hidden;
    
}


- (void)setRouteColor:(NSString *)route
{
    PC_ROUTE_INFO info = [TriMetInfo infoForRoute:route];

    if (info !=nil && route!=nil)
    {
        _red    = COL_HTML_R(info->html_color);
        _green    = COL_HTML_G(info->html_color);
        _blue    = COL_HTML_B(info->html_color);
        _square = info->streetcar;
        self.hidden    = NO;
        [self setNeedsDisplay];
    }
    else 
    {
        self.hidden = YES;
        [self setNeedsDisplay];
    }
    
    self.backgroundColor = [UIColor clearColor];
}


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
    
    if (_square)
    {
        CGRect innerSquare = CGRectInset(outerSquare, 1, 1);
        CGPathAddRect(fillPath, NULL, innerSquare);
    }
    else
    {
        CGPathAddEllipseInRect(fillPath, NULL, outerSquare);
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, _red , _green, _blue, self.hidden ? 0.0 : 1.0);
    CGContextAddPath(context, fillPath);
    CGContextFillPath(context);

    
//    DEBUG_LOG(@"%f %f %f\n", _red, _green, _blue);
        
    CGPathRelease(fillPath);

}



@end
