//
//  RouteDistance.h
//  PDX Bus
//
//  Created by Andrew Wallace on 1/9/11.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import <Foundation/Foundation.h>

@interface RouteDistanceData : NSObject {
	NSString *_desc;
	NSString *_route;
	NSString *_type;
	NSMutableArray *_stops;
}

- (void)sortStopsByDistance;
- (NSComparisonResult)compareUsingDistance:(RouteDistanceData*)inStop;

@property (nonatomic, retain) NSString *desc;
@property (nonatomic, retain) NSString *route;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSMutableArray *stops;

@end
