//
//  ShapeMutableSegment.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/8/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ShapeMutableSegment.h"
#import "ShapeCompactSegment.h"
#import "ShapeCoord.h"

@implementation ShapeMutableSegment

@synthesize count;

- (instancetype)init {
    if (self = [super init]) {
        self.coords = [NSMutableArray array];
    }

    return self;
}

- (ShapeCompactSegment *)compact {
    return [[ShapeCompactSegment alloc] initFromMutable:self];
}

- (bool)isEqual:(nonnull id<ShapeSegment>)seg {
    if (self != seg) {
        return [self.compact isEqual:seg.compact];
    }
    return TRUE;
}

- (MKPolyline *)simplePolyline {
    return self.compact.simplePolyline;
}

- (NSInteger)count {
    return self.coords.count;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [self.compact encodeWithCoder:coder];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder {
    return nil;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end
