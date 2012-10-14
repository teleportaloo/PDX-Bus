//
//  RouteColorBlobView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/6/10.
//  Copyright 2010. All rights reserved.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import "RouteColorBlobView.h"
#import "debug.h"
#import "TriMetRouteColors.h"

@implementation RouteColorBlobView

@synthesize red		= _red;
@synthesize green	= _green;
@synthesize blue	= _blue;
@synthesize square  = _square;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}

- (bool)setRouteColorLine:(RAILLINES)line
{
	ROUTE_COL *rcol = [TriMetRouteColors rawColorForLine:line];
	
	if (rcol !=nil)
	{
		_red	= rcol->r;
		_green	= rcol->g;
		_blue	= rcol->b;
        _square = rcol->square;
		self.hidden	= NO;
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
	ROUTE_COL *rcol = [TriMetRouteColors rawColorForRoute:route];

	if (rcol !=nil && route!=nil)
	{
		_red	= rcol->r;
		_green	= rcol->g;
		_blue	= rcol->b;
        _square = rcol->square;
		self.hidden	= NO;
		[self setNeedsDisplay];
	}
	else 
	{
		self.hidden = YES;
		[self setNeedsDisplay];
	}
	
	self.backgroundColor = [UIColor clearColor];
}

#define min(X,Y) ((X)<(Y)?(X):(Y))


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
	
	CGMutablePathRef fillPath = CGPathCreateMutable();
	
	// CGPathAddRects(fillPath, NULL, &rect, 1);
	
	CGRect outerSquare;
	
	CGFloat width = min(CGRectGetWidth(rect), CGRectGetHeight(rect));
	
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

	
//	DEBUG_LOG(@"%f %f %f\n", _red, _green, _blue);
    	
    CGPathRelease(fillPath);

}

- (void)dealloc {
    [super dealloc];
}


@end
