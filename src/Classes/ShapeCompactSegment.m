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
#import "RouteMultiPolyline.h"
#import "ShapeMutableSegment.h"
#import "ShapeRoutePath.h"

#define kKeyCoords @"c"

@interface ShapeCompactSegment () {
    NSInteger _count;
}

@end

@implementation ShapeCompactSegment

@synthesize count = _count;

- (instancetype)initFromMutable:(ShapeMutableSegment *)seg {

    if (self = [super init]) {

        if (seg.coords && seg.coords.count > 0) {
            CLLocationCoordinate2D *coords =
                malloc(sizeof(CLLocationCoordinate2D) * seg.coords.count);
            CLLocationCoordinate2D *p = coords;

            for (ShapeCoord *c in seg.coords) {
                *p = c.coord;
                p++;
            }

            _coords = coords;
            _count = seg.coords.count;
        }
    }

    return self;
}

- (instancetype)init {
    if (self = [super init]) {
    }

    return self;
}

- (void)dealloc {
    free(_coords);
}

- (ShapeCompactSegment *)compact {
    return self;
}

- (bool)isEqual:(id<ShapeSegment>)seg {
    if (seg) {
        if (self.count == seg.count) {
            ShapeCompactSegment *compact = seg.compact;

            if (compact && compact.coords && self.coords) {
                return memcmp(self.coords, compact.coords,
                              _count * sizeof(_coords[0])) == 0;
            }
        }
    }

    return NO;
}

- (MKPolyline *)simplePolyline {
    return [MKPolyline polylineWithCoordinates:self.coords count:self.count];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (_coords && _count > 0) {
        [aCoder encodeBytes:(uint8_t *)_coords
                     length:sizeof(_coords[0]) * _count
                     forKey:kKeyCoords];
    }
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super init])) {
        NSUInteger length = 0;
        const uint8_t *bytes = [aDecoder decodeBytesForKey:kKeyCoords
                                            returnedLength:&length];

        // check size
        if (length % sizeof(CLLocationCoordinate2D) == 0) {
            _count = length / sizeof(CLLocationCoordinate2D);
            _coords = (CLLocationCoordinate2D *)malloc(length);
            memcpy(_coords, bytes, length);
        }
    }

    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end
