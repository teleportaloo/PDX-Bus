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


#pragma clag diagnostic pop

#include "TriMetTypes.h"

@interface DepartureTrip : NSObject {
	NSString *      _name;
	unsigned long   _distance;
	unsigned long   _progress;
	TriMetTime      _startTime;
	TriMetTime      _endTime;
	
}
@property (nonatomic, copy)   NSString *name;
@property (nonatomic) unsigned long distance;
@property (nonatomic) unsigned long progress;
@property (nonatomic) TriMetTime startTime;
@property (nonatomic) TriMetTime endTime;

- (instancetype)init;

@end
