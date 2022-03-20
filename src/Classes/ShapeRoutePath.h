//
//  ShapeRoutePath.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/12/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "ShapeCoord.h"
#import "ShapeSegment.h"
#import "ShapeCompactSegment.h"

#define kShapeNoRoute (-1)

@interface ShapeRoutePath : NSObject <NSSecureCoding>

@property (nonatomic, strong) NSMutableArray<id<ShapeSegment>> *segments;
@property (nonatomic, copy) NSString *dirDesc;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic)  NSInteger route;
@property (nonatomic)  bool direct;

- (NSMutableArray<RoutePolyline *> *)addPolylines:(NSMutableArray<RoutePolyline *> *)lines;

@end
