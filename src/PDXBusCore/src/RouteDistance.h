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
#import "StopDistance.h"

@interface RouteDistance : DataFactory

@property (nonatomic, strong) NSMutableArray<StopDistance*> *stops;
@property (nonatomic, copy)   NSString *route;
@property (nonatomic, copy)   NSString *desc;
@property (nonatomic, copy)   NSString *type;

- (NSComparisonResult)compareUsingDistance:(RouteDistance*)inStop;
- (void)sortStopsByDistance;

@end
