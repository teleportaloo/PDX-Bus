//
//  RailStation+Sort.h
//  PDX Bus
//
//  Created by Andy Wallace on 8/17/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RailStation.h"

NS_ASSUME_NONNULL_BEGIN

@interface RailStation (Sort)


// This should only be used for testing and generating arrays - there is
// a nice table of pre-sorted stations provided... this was used to make it.
+ (NSArray<RailStation *> *)sortedStations;

@end

NS_ASSUME_NONNULL_END
