//
//  RailMapHotSpots.m
//  PDX Bus
//
//  Created by Andrew Wallace on 3/1/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogUserInterface

#import "RailMapHotSpots.h"
#import "RailMapView.h"
#import "NSString+Helper.h"

#pragma mark Rail Map Hotspots

@interface RailMapHotSpots () {
    CGPoint _touchPoint;
    RailMap *_railMap;
}

@property (nonatomic) int selectedItem;


@end

@implementation RailMapHotSpots

static HotSpot *hotSpotRegions;

- (instancetype)initWithImageView:(UIView *)mapView map:(RailMap *)map {
    self = [super initWithFrame:CGRectMake(0, 0, mapView.frame.size.width, mapView.frame.size.height)];
    self.backgroundColor = [UIColor clearColor];
    
    self.mapView = mapView;
    
    [self.mapView addSubview:self];
    self.showAll = NO;
    self.selectedItem = -1;
    
    _railMap = map;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        hotSpotRegions = RailMapView.hotspotRecords;
    });
    
    return self;
}

- (void)touchAtPoint:(CGPoint)point {
    self.selectedItem = -1;
    _touchPoint = point;
    self.alpha = 1.0;
    [self setNeedsDisplay];
    
    [self fadeOut];
}

- (void)selectItem:(int)i {
    self.selectedItem = i;
    _touchPoint.x = 0;
    _touchPoint.y = 0;
    
    switch (hotSpotRegions[i].action.firstUnichar) {
        case kLinkTypeHttp:
        case kLinkTypeWiki:
        case kLinkTypeStop:
        case kLinkTypeDir:
        case kLinkType1:
        case kLinkType2:
        case kLinkType3:
        case kLinkTypeTest:
            self.alpha = 1.0;
            [self setNeedsDisplay];
            break;
            
        case kLinkTypeNorth:
            break;
    }
}

- (void)fadeOut {
    if (!self.showAll) {
        [UIView animateWithDuration:1.0 animations:^{
            self.alpha = 0.0;
        } completion:^(BOOL finished){
        }];
    } 
}

+ (void)setFillAndStrokeColor:(CGContextRef)context color:(UIColor *)col {
    CGFloat red, green, blue, alpha;
    [col getRed:&red green:&green blue:&blue alpha:&alpha];
    CGContextSetRGBFillColor(context, red, green, blue, 0.5);
    CGContextSetStrokeColorWithColor(context, col.CGColor);
}

- (void)drawHotspot:(HotSpot *)hs context:(CGContextRef)context {
    DEBUG_LOGB(self.showAll);
    
    if (hs->action.firstUnichar == '#') {
        [RailMapHotSpots setFillAndStrokeColor:context color:[UIColor greenColor]];
    } else if (hs->touched && self.showAll && hs->action.firstUnichar != kLinkTypeTest ) {
        [RailMapHotSpots setFillAndStrokeColor:context color:[UIColor yellowColor]];
    } else {
        UIColor *col;
        switch (hs->action.firstUnichar) {
            default:
            case kLinkTypeHttp:
                col = [UIColor orangeColor];
                break;
                
            case kLinkTypeTest:
                col = [UIColor blackColor];
                break;
                
            case kLinkTypeWiki:
                col = [UIColor redColor];
                break;
                
            case kLinkTypeStop:
            case kLinkTypeDir:
                col = [UIColor modeAwareBlue];
                break;
                
            case kLinkType1:
            case kLinkType2:
            case kLinkType3:
                col = [UIColor modeAwareBlue];
                break;
                
            case kLinkTypeNorth:
                col = [UIColor grayColor];
                break;
        }
        [RailMapHotSpots setFillAndStrokeColor:context color:col];
    }
    
    if (HOTSPOT_IS_POLY(hs)) {
        const CGPoint *vertices = hs->coords.vertices;
        int nVertices = hs->nVertices;
        
        // Draw curves between the midpoints of the polygon's sides with the
        // vertex as the control point.
        
        CGContextMoveToPoint(context, (vertices[0].x + vertices[1].x) / 2, (vertices[0].y + vertices[1].y) / 2);
        
        for (int i = 1; i < hs->nVertices; i++) {
            CGContextAddQuadCurveToPoint(context, vertices[i].x, vertices[i].y, (vertices[i].x + vertices[(i + 1) % nVertices].x) / 2, (vertices[i].y + vertices[(i + 1) % nVertices].y) / 2);
        }
        
        CGContextAddQuadCurveToPoint(context, vertices[0].x, vertices[0].y, (vertices[0].x + vertices[1].x) / 2, (vertices[0].y + vertices[1].y) / 2);
        CGContextFillPath(context);
    } else if (HOTSPOT_IS_RECT(hs)) {
        CGContextFillEllipseInRect(context, *hs->coords.rect);
    }
}

- (void)drawBlob:(CGContextRef)context {
    // Drawing code
    
    CGMutablePathRef fillPath = CGPathCreateMutable();
    
    // CGPathAddRects(fillPath, NULL, &rect, 1);
    CGFloat width = 20.0;
    CGRect rect = CGRectMake(_touchPoint.x - width / 2.0,
                             _touchPoint.y - width / 2.0,
                             width,
                             width);
    
    CGRect square;
    
    // CGFloat width = min(CGRectGetWidth(rect), CGRectGetHeight(rect));
    
    square.origin.x = CGRectGetMidX(rect) - width / 2;
    square.origin.y = CGRectGetMidY(rect) - width / 2;
    square.size.width = width;
    square.size.height = width;
    
    CGPathAddEllipseInRect(fillPath, NULL, square);
    
    //    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //    CGContextSetRGBFillColor(context, _red , _green, _blue, self.hidden ? 0.0 : 1.0);
    CGContextAddPath(context, fillPath);
    CGContextFillPath(context);
    
    //    DEBUG_LOG(@"%f %f %f\n", _red, _green, _blue);
    
    CGPathRelease(fillPath);
}

- (void)drawRect:(CGRect)rect {
    {
        static CGFloat dash [] = { 5.0, 5.0 };
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        
        CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 0.5);
        CGContextSetLineDash(context, 5.0, dash, 2);
        CGContextSetLineWidth(context, 1.0);
        
        
        HotSpot *hs;
        
        if (!self.showAll) {
            if (self.selectedItem != -1) {
                [self drawHotspot:(hotSpotRegions + self.selectedItem) context:context];
            } else if (_touchPoint.x != 0.0) {
                [self drawBlob:context];
            }
        } else {
            if (self.selectedItem == -1 && _touchPoint.x != 0.0) {
                [self drawBlob:context];
            }
            
            for (int j = _railMap->firstHotspot; j <= _railMap->lastHotspot; j++) {
                hs = hotSpotRegions + j;
                
                if (hs->nVertices > 0) {
                    [self drawHotspot:hs context:context];
                }
            }
            
            CGContextSetStrokeColorWithColor(context, [UIColor orangeColor].CGColor);
            
            for (CGFloat x = 0; x <  _railMap->xTiles; x++) {
                CGFloat xp = x * _railMap->tileSize.width;
                CGContextMoveToPoint(context, xp, 0);
                CGContextAddLineToPoint(context, xp, _railMap->size.height);
            }
            
            for (CGFloat y = 0; y < _railMap->yTiles; y++) {
                CGFloat yp = y * _railMap->tileSize.height;
                DEBUG_LOG(@"yp %f\n", yp);
                CGContextMoveToPoint(context, 0,                     yp);
                CGContextAddLineToPoint(context, _railMap->size.width,  yp);
            }
            
            CGContextSetTextDrawingMode(context, kCGTextFill); // This is the default
            [[UIColor blackColor] setFill]; // This is the default
            
            CGContextSetTextMatrix(context, CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0));
            
            for (int x = 0; x < _railMap->xTiles; x++) {
                for (int y = 0; y < _railMap->yTiles; y++) {
                    CGFloat xp = x * _railMap->tileSize.width  + _railMap->tileSize.width / 2.0;
                    CGFloat yp = y * _railMap->tileSize.height + _railMap->tileSize.height / 2.0;
                    
                    ConstHotSpotIndex *index = _railMap->tiles[x][y].hotspots;
                    
                    int count = 0;
                    
                    while (*index != MAP_LAST_INDEX) {
                        index++;
                        count++;
                    }
                    
                    NSString *sizeText = [NSString stringWithFormat:@"%d", count];
                    
                    [sizeText drawAtPoint:CGPointMake(xp, yp)
                           withAttributes:@{ NSFontAttributeName: [UIFont fontWithName:@"Helvetica"
                                                                                  size:12] }];
                }
            }
            
            CGContextDrawPath(context, kCGPathStroke);
            
            //  CGContextStrokePath(context);
        }
        
        // CGContextStrokePath(context);
    }
}

@end
