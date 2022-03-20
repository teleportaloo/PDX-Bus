//
//  ShapeSegment.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/8/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


NS_ASSUME_NONNULL_BEGIN

@class ShapeCompactSegment;
@class RoutePolyline;
@class ShapeRoutePath;

@protocol ShapeSegment<NSSecureCoding>

- (bool)isEqual:(id<ShapeSegment>)seg;
- (ShapeCompactSegment *)compact;
- (RoutePolyline *)polyline:(UIColor *)color dashPatternId:(int)dashPatternId
                  dashPhase:(CGFloat)dashPhase path:(ShapeRoutePath *)path;


@property (nonatomic) NSInteger count;

@end

NS_ASSUME_NONNULL_END
