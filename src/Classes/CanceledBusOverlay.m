//
//  CanceledBusOverlay.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/15/14.
//  Copyright (c) 2014 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "CanceledBusOverlay.h"

@implementation CanceledBusOverlay

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        // Initialization code
    }
    
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    if (!self.hidden) {
        CGMutablePathRef fillPath = CGPathCreateMutable();
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, self.hidden ? 0.0 : 1.0);
        CGContextSetLineWidth(context, 2);
        
        CGPathMoveToPoint(fillPath, NULL, rect.origin.x, rect.origin.y);
        CGPathAddLineToPoint(fillPath, NULL, rect.origin.x + rect.size.width, rect.origin.y + rect.size.height);
        
        CGPathMoveToPoint(fillPath, NULL, rect.origin.x + rect.size.width, rect.origin.y);
        CGPathAddLineToPoint(fillPath, NULL, rect.origin.x, rect.origin.y + rect.size.height);
        
        CGContextAddPath(context, fillPath);
        CGContextStrokePath(context);
        
        CGPathRelease(fillPath);
    }
}

@end
