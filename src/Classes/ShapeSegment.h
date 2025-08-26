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


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ShapeCompactSegment;
@class RouteMultiPolyline;
@class ShapeRoutePath;
@class MKPolyline;

@protocol ShapeSegment <NSSecureCoding>

- (bool)isEqual:(id<ShapeSegment>)seg;
- (ShapeCompactSegment *)compact;
- (MKPolyline *)simplePolyline;

@property(nonatomic) NSInteger count;

@end

NS_ASSUME_NONNULL_END
