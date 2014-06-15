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

@interface ShapeCoord : NSObject
{
	CLLocationCoordinate2D _coord;
}

@property (nonatomic) bool end;
@property (nonatomic) CLLocationDegrees latitude;
@property (nonatomic) CLLocationDegrees longitude;
@property (nonatomic) CLLocationCoordinate2D coord;

+ (ShapeCoord*) makeEnd;

@end



@interface LegShapeParser : StoppableFetcher {
	NSMutableArray *_shapeCoords;
	NSString *_lineURL;
}

@property (nonatomic, retain) NSMutableArray *shapeCoords;
@property (nonatomic, retain) NSString *lineURL;

- (void)fetchCoords;

@end
