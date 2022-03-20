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
#import "UIColor+DarkMode.h"

@interface RouteColorBlobView ()

@property (nonatomic) UIColor *color;
@property (nonatomic) bool square;

@end

@implementation RouteColorBlobView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    
    return self;
}

- (bool)setRouteColorLine:(RailLines)line {
    PtrConstRouteInfo info = [TriMetInfo infoForLine:line];
    
    if (info != nil) {
        self.color = [TriMetInfo cachedColor:info->html_color];
        _square = info->streetcar;
        self.hidden = NO;
        [self setNeedsDisplay];
    } else {
        self.hidden = YES;
        [self setNeedsDisplay];
    }
    
    self.backgroundColor = [UIColor clearColor];
    
    return !self.hidden;
}

- (void)setRouteColor:(NSString *)route {
    PtrConstRouteInfo info = [TriMetInfo infoForRoute:route];
    
    if (info != nil && route != nil) {
        self.color = [TriMetInfo cachedColor:info->html_color];
        _square = info->streetcar;
        self.hidden = NO;
        [self setNeedsDisplay];
    } else {
        self.hidden = YES;
        [self setNeedsDisplay];
    }
    
    self.backgroundColor = [UIColor clearColor];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    if (!self.hidden) {
        CGMutablePathRef fillPath = CGPathCreateMutable();
        CGRect outerSquare;
        
        CGFloat width = fmin(CGRectGetWidth(rect), CGRectGetHeight(rect));
        
        outerSquare.origin.x = 1 + CGRectGetMidX(rect) - width / 2;
        outerSquare.origin.y = 1 + CGRectGetMidY(rect) - width / 2;
        outerSquare.size.width = width - 2;
        outerSquare.size.height = width - 2;
        
        if (_square) {
            CGRect innerSquare = CGRectInset(outerSquare, 1, 1);
            CGPathAddRect(fillPath, NULL, innerSquare);
        } else {
            CGPathAddEllipseInRect(fillPath, NULL, outerSquare);
        }
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        const CGFloat *components = CGColorGetComponents(self.color.CGColor);
        
        if (components == nil) {
            static const CGFloat black[] = { 0.0, 0.0, 0.0 };
            components = black;
        }
        
        if (components[0] == 0.0 && components[1] == 0.0 && components[2] == 0.0) {
            CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
        } else {
            CGContextSetRGBStrokeColor(context, components[0], components[1], components[2], 1.0);
        }
        
        CGContextSetLineWidth(context, 0.5);
        CGContextSetRGBFillColor(context, components[0], components[1], components[2], self.hidden ? 0.0 : 1.0);
        CGContextAddPath(context, fillPath);
        CGContextDrawPath(context, kCGPathFillStroke);
        CGPathRelease(fillPath);
    }
}

@end
