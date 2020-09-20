//
//  ShapeCompactSegment.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/8/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ShapeCompactSegment.h"
#import "RoutePolyline.h"
#import "ShapeRoutePath.h"
#import "ShapeMutableSegment.h"

#define kKeyCoords   @"c"

@interface ShapeCompactSegment () {
    NSInteger _count;
}

@end

@implementation ShapeCompactSegment

@synthesize count = _count;

- (void)dealloc {
    free(_coords);
}

- (instancetype)initFromMutable:(ShapeMutableSegment *)seg {
    
    if (self = [super init]) {
        
        if (seg.coords && seg.coords.count > 0) {
            CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) * seg.coords.count);
            CLLocationCoordinate2D *p = coords;
        
            for (ShapeCoord *c in seg.coords) {
                *p = c.coord;
                p++;
            }
        
            self.coords = coords;
            self.count = seg.coords.count;
        }
    }
    
    return self;
}


- (instancetype)init {
    if (self = [super init]) {
    }
    
    return self;
}

- (ShapeCompactSegment *)compact {
    return self;
}

- (bool)isEqual:(id<ShapeSegment>)seg {
    if (seg) {
        if (self.count == seg.count) {
            ShapeCompactSegment *compact = seg.compact;
            
            if (compact && compact.coords && self.coords) {
                return memcmp(self.coords, compact.coords, _count * sizeof(_coords[0])) == 0;
            }
        }
    }
    
    return NO;
}

- (RoutePolyline *)polyline:(UIColor *)color dashPatternId:(int)dashPatternId dashPhase:(CGFloat)dashPhase path:(ShapeRoutePath *)path {
    RoutePolyline *polyLine = [RoutePolyline polylineWithCoordinates:self.coords count:self.count];
    
    polyLine.color = color;
    polyLine.dashPatternId = dashPatternId;
    polyLine.dashPhase = dashPhase;
    polyLine.desc = path.desc;
    
    if (path.route != kShapeNoRoute) {
        polyLine.route = [NSString stringWithFormat:@"%lu", (unsigned long)path.route];
        polyLine.dir = path.dirDesc;
    }
    
    return polyLine;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (_coords && _count > 0) {
        [aCoder encodeBytes:(uint8_t *)_coords length:sizeof(_coords[0]) * _count forKey:kKeyCoords];
    }
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super init])) {
        NSUInteger length = 0;
        const uint8_t *bytes = [aDecoder decodeBytesForKey:kKeyCoords returnedLength:&length];
        
        // check size
        if (length % sizeof(CLLocationCoordinate2D) == 0) {
            _count = length / sizeof(CLLocationCoordinate2D);
            _coords = (CLLocationCoordinate2D *)malloc(length);
            memcpy(_coords, bytes, length);
        }
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

@end

