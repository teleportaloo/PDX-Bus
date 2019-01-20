//
//  DepartureTrip.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



// There is an analysis error in CGColorSpace.h - this will suppress
// that error for that case only. 
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"
#pragma clang diagnostic ignored "-Wnullability-completeness-on-arrays"

#import <Foundation/Foundation.h>
#import "DataFactory.h"


#pragma clag diagnostic pop

#include "TriMetTypes.h"

@interface DepartureTrip : DataFactory

@property (nonatomic, copy)   NSString *name;
@property (nonatomic) unsigned long distance;
@property (nonatomic) unsigned long progress;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *endTime;
@property (nonatomic, copy) NSString *route;
@property (nonatomic, copy) NSString *dir;


- (instancetype)init;

@end
