//
//  RoutePolyline.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/17/16.
//  Copyright © 2016 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RoutePolyline.h"
#import "RoutePin.h"

@implementation RoutePolyline

@dynamic dashPattern;




- (NSArray *)dashPattern
{
    static NSArray<NSArray *> *pattern;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pattern = @[ @[ @1,  @1 ],
                     @[ @3,  @5 ],
                     @[@kPolyLineSegLength,@(kPolyLineSegLength *2)],
                     @[@kPolyLineSegLength,@(kPolyLineSegLength *3)],
                     @[@kPolyLineSegLength,@(kPolyLineSegLength *4)],
                     @[ @2, @kPolyLineSegLength, @kPolyLineSegLength, @(kPolyLineSegLength*2) ]
                     ];
    });
    
    NSArray *result = nil;
    
    if (_dashPatternId < pattern.count)
    {
        result = pattern[_dashPatternId];
    }
    
    if (result == nil)
    {
        result = pattern[1];
    }
    
    return result;
}

- (MKPolylineRenderer *)renderer
{
    MKPolylineRenderer *lineView = [[MKPolylineRenderer alloc] initWithPolyline:self];
    lineView.strokeColor = self.color;
    lineView.lineWidth = 2.0;
    lineView.lineDashPattern = self.dashPattern;
    lineView.lineDashPhase = self.dashPhase;
    return lineView;
}

- (RoutePin*)routePin
{
    RoutePin *pin = [RoutePin data];
    pin.desc = self.desc;
    pin.dir = self.dir;
    pin.color = self.color;
    pin.route = self.route;
    
    return pin;
}


@end
