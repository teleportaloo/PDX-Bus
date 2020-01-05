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
#import "DataFactory.h"
#import <CoreLocation/CoreLocation.h>

@class RoutePolyline;

@interface ShapeCoord : DataFactory
{
    CLLocationCoordinate2D _coord;
}

@property (nonatomic) CLLocationDegrees latitude;
@property (nonatomic) CLLocationDegrees longitude;
@property (nonatomic) CLLocationCoordinate2D coord;

+ (instancetype) coordWithLat:(CLLocationDegrees)lat lng:(CLLocationDegrees)lng;

@end

@class ShapeCompactSegment;
@class ShapeRoutePath;

@interface ShapeSegment : DataFactory <NSCoding>

- (bool)isEqual:(ShapeSegment*)seg;
- (ShapeCompactSegment *) compact;

@property (nonatomic) NSInteger count;

@end

@interface ShapeCompactSegment : ShapeSegment
{
    NSInteger _count;
}

@property (nonatomic) CLLocationCoordinate2D *coords;


- (RoutePolyline*)polyline:(UIColor *)color dashPatternId:(int)dashPatternId
                 dashPhase:(CGFloat)dashPhase path:(ShapeRoutePath*)path;


@end

@interface ShapeMutableSegment : ShapeSegment

@property (nonatomic, strong) NSMutableArray<ShapeCoord *> *coords;

- (ShapeCompactSegment *) compact;

@end

#define kShapeNoRoute (-1)

@interface ShapeRoutePath : DataFactory <NSCoding>

@property (nonatomic, strong) NSMutableArray<ShapeSegment *> *segments;
@property (nonatomic, copy) NSString *dirDesc;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic)  NSInteger route;
@property (nonatomic)  bool direct;

- (NSMutableArray<RoutePolyline*>*) addPolylines:(NSMutableArray<RoutePolyline*>*)lines;

@end
