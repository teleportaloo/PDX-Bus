//
//  LegShapeParser.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/31/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "StoppableFetcher.h"
#import "DataFactory.h"


@interface ShapeObject: DataFactory

@end

@interface ShapeCoord : ShapeObject
{
	CLLocationCoordinate2D _coord;
}

@property (nonatomic) CLLocationDegrees latitude;
@property (nonatomic) CLLocationDegrees longitude;
@property (nonatomic) CLLocationCoordinate2D coord;

@end

@interface ShapeCoordEnd : ShapeObject
{
    bool _direct;
    UIColor *_color;
}

@property (nonatomic)           bool direct;
@property (nonatomic, retain)   UIColor *color;

+ (ShapeCoordEnd*)makeDirect:(bool)direct color:(UIColor *)color;

@end

@interface LegShapeParser : StoppableFetcher {
	NSMutableArray<ShapeObject *> * _shapeCoords;
	NSString *                      _lineURL;
}

@property (nonatomic, retain) NSMutableArray *shapeCoords;
@property (nonatomic, copy)   NSString *lineURL;

- (void)fetchCoords;

@end
