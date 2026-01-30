//
//  ProgressLabel.m
//  iOS Core Lib
//
//  Created by Andy Wallace on 9/29/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//

// ProgressLabel.m
#import "ProgressLabel.h"
#import "UIColor+MoreDarkMode.h"

@interface ProgressLabel ()
@end

@implementation ProgressLabel

@synthesize progress = _progress;
@synthesize fillColor = _fillColor;
@synthesize verticalPadding = _verticalPadding;
@synthesize borderWidth = _borderWidth;
@synthesize borderColor = _borderColor;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    // Defaults
    _progress = 0.0;
    _fillColor = [[UIColor systemGreenColor] colorWithAlphaComponent:0.5];
    _verticalPadding = 2.0;
    _borderWidth = 1.0;
    _borderColor = _fillColor;

    // Clear background
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;

    // Layer border
    self.layer.borderWidth = _borderWidth;
    self.layer.borderColor = _borderColor.CGColor;
    self.layer.masksToBounds = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // Match corner radius to the fill's rounded height
    CGFloat radius =
        (CGRectGetHeight(self.bounds) - 2.0 * _verticalPadding - 2.0 * _borderWidth) / 2.0;
    self.layer.cornerRadius = MAX(radius, 0.0);
}

- (void)setProgress:(CGFloat)progress {
    _progress = MIN(MAX(progress, 0.0), 1.0);
    [self setNeedsDisplay];
}

- (void)setFillColor:(UIColor *)fillColor {
    _fillColor = fillColor;
    [self setNeedsDisplay];
}

- (void)setVerticalPadding:(CGFloat)verticalPadding {
    _verticalPadding = verticalPadding;
    [self setNeedsDisplay];
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = borderWidth;
    self.layer.borderWidth = borderWidth;
    [self setNeedsDisplay];
}

- (void)setBorderColor:(UIColor *)borderColor {
    _borderColor = borderColor;
    self.layer.borderColor = borderColor.CGColor;
}

- (void)drawTextInRect:(CGRect)rect {
    // Compute inner bounds inside the border
    CGRect innerBounds = UIEdgeInsetsInsetRect(
        self.bounds, UIEdgeInsetsMake(_borderWidth, _borderWidth, _borderWidth, _borderWidth));

    // Further inset vertically for padding
    CGRect padded = UIEdgeInsetsInsetRect(innerBounds, UIEdgeInsetsMake(0, 0, 0, 0));

    // Determine fill width based on progress
    CGRect fillRect = padded;
    fillRect.size.width = padded.size.width * _progress;

    // Draw rectangular fill bar flush to edges
    [self.fillColor setFill];
    UIRectFill(fillRect);

    // Draw text on top
    [super drawTextInRect:rect];
}

@end
