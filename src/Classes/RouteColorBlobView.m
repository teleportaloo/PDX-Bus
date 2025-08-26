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
#import "NSString+MoreMarkup.h"
#import "TaskDispatch.h"
#import "TriMetInfo+UI.h"
#import "UIColor+HTML.h"
#import "UIFont+Utility.h"
#import <CoreText/CoreText.h>

@interface RouteColorBlobView ()

@property(nonatomic) UIColor *color;
@property(nonatomic) UIColor *strokeColor;
@property(nonatomic) bool square;
@property(nonatomic) CGPathDrawingMode drawingMode;
@property(nonatomic) NSAttributedString *route;
@property(nonatomic) CGFloat lineWidth;

@end

@implementation RouteColorBlobView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }

    return self;
}

- (void)setRouteHtmlColor:(uint32_t)color {
    self.color = HTML_COLOR(color);
    _drawingMode = kCGPathStroke;
    _strokeColor = self.color;
}

- (void)setRouteColorInfo:(PtrConstRouteInfo)info {
    if (info != nil) {
        self.color = HTML_COLOR(info->html_color);
        if (info->html_stroke_color == RGB_SAME) {
            self.strokeColor = self.color;
        } else {
            self.strokeColor = HTML_COLOR(info->html_stroke_color);
        }

        switch (info->lineType) {
        case LineTypeMAX:
        case LineTypeTram:
        case LineTypeWES:
            _square = false;
            _drawingMode = kCGPathFillStroke;
            _lineWidth = 0.5;
            self.route = nil;
            break;
        case LineTypeBus: {
            static UIFont *tinyFont;
            DoOnce(^{
              tinyFont = [UIFont monospacedDigitSystemFontOfSize:14.0];
            });

            self.route =
                [[NSString stringWithFormat:@"#W%ld", info->route_number]
                    attributedStringFromMarkUpWithFont:tinyFont];

            _square = false;
            _drawingMode = kCGPathFillStroke;
            _lineWidth = 0.5;
            break;
        }
        case LineTypeStreetcar:
            _square = true;
            _drawingMode = kCGPathFillStroke;
            _lineWidth = 0.5;
            self.route = nil;
            break;
        case LineTypeMAXBus:
            _square = false;
            _drawingMode = kCGPathStroke;
            _lineWidth = 3;
            self.route = nil;
        }

        self.hidden = NO;
        [self setNeedsDisplay];
    } else {
        self.hidden = YES;
        [self setNeedsDisplay];
    }
}

- (bool)setRouteColorLine:(TriMetInfo_ColoredLines)line {
    PtrConstRouteInfo info = [TriMetInfo infoForLine:line];
    [self setRouteColorInfo:info];
    self.backgroundColor = [UIColor clearColor];
    return !self.hidden;
}

- (void)setRouteColor:(NSString *)route {
    if (route) {
        PtrConstRouteInfo info = [TriMetInfo infoForRoute:route];
        [self setRouteColorInfo:info];
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

        outerSquare.origin.x =
            0.75 + CGRectGetMidX(rect) - width / 2 + (_lineWidth / 2);
        outerSquare.origin.y =
            0.75 + CGRectGetMidY(rect) - width / 2 + (_lineWidth / 2);
        outerSquare.size.width = width - 1.5 - _lineWidth;
        outerSquare.size.height = width - 1.5 - _lineWidth;

        if (_square) {
            CGRect innerSquare = CGRectInset(outerSquare, 1, 1);
            CGPathAddRect(fillPath, NULL, innerSquare);
        } else {
            CGPathAddEllipseInRect(fillPath, NULL, outerSquare);
        }

        CGContextRef context = UIGraphicsGetCurrentContext();
        
        [self.strokeColor setStroke];

        CGContextSetLineWidth(context, _lineWidth);
        
        [self.color setFill];
        
        CGContextAddPath(context, fillPath);
        CGContextDrawPath(context, _drawingMode);
        CGPathRelease(fillPath);

        if (_route != 0) {
            CTLineRef line =
                CTLineCreateWithAttributedString((CFAttributedStringRef)_route);
            CGAffineTransform trans = CGAffineTransformMakeScale(1, -1);
            CGContextSetTextMatrix(context, trans);
            CGRect stringRect = CTLineGetImageBounds(line, context);
            CGContextSetTextPosition(
                context,
                outerSquare.origin.x +
                    (outerSquare.size.width - stringRect.size.width - 2) / 2,
                rect.size.height -
                    (outerSquare.origin.y +
                     (outerSquare.size.height - stringRect.size.height) / 2));
            CTLineDraw(line, context);
            CFRelease(line);
        }
    }
}

@end
