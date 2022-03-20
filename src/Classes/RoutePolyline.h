//
//  RoutePolyline.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/17/16.
//  Copyright © 2016 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <MapKit/MapKit.h>

#define kPolyLineSegLength     (4)
#define kPolyLinePatternDirect (5)
#define kPolyLinePatternBus    (1)

@class RoutePin;

@interface RoutePolyline : MKPolyline {
    CLLocationCoordinate2D _touchPosition;
}

@property (nonatomic, strong) UIColor *color;
@property (nonatomic) CGFloat dashPhase;
@property (weak, nonatomic, readonly) NSArray<NSNumber *> *dashPattern;
@property (nonatomic) int dashPatternId;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *route;
@property (nonatomic, copy) NSString *dir;

- (MKPolylineRenderer *)renderer;
- (RoutePin *)routePin;

@end
