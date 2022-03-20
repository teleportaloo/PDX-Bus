//
//  Trip.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DepartureTrip.h"

@implementation DepartureTrip

- (instancetype)init {
    if ((self = [super init])) {
        self.distanceFeet = 0;
        self.progressFeet = 0;
        self.startTime = 0;
        self.endTime = 0;
        self.dir = nil;
        self.route = nil;
    }
    
    return self;
}

@end
