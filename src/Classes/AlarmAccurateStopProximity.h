//
//  AlarmAccurateStopProximity.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/11/11.
//  Copyright 2011 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AlarmTask.h"
#import "MapPin.h"
#import "Settings.h"
#import <Foundation/Foundation.h>

@interface AlarmAccurateStopProximity
    : AlarmTask <CLLocationManagerDelegate, MapPin>

- (void)setStop:(NSString *)stopId loc:(CLLocation *)loc desc:(NSString *)desc;
- (instancetype)initWithAccuracy:(bool)accurate;

@end
