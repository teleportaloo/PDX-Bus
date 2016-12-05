//
//  DepartureTrip.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>

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
