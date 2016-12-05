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
#import "DataFactory.h"
#import "StopDistanceData.h"

@interface RouteDistanceData : DataFactory {
	NSString *_desc;
	NSString *_route;
	NSString *_type;
	NSMutableArray<StopDistanceData*> *_stops;
}

- (void)sortStopsByDistance;
- (NSComparisonResult)compareUsingDistance:(RouteDistanceData*)inStop;

@property (nonatomic, copy)   NSString *desc;
@property (nonatomic, copy)   NSString *route;
@property (nonatomic, copy)   NSString *type;
@property (nonatomic, retain) NSMutableArray<StopDistanceData*> *stops;

@end
