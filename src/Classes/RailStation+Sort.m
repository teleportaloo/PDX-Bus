//
//  RailStation+Sort.m
//  PDX Bus
//
//  Created by Andy Wallace on 8/17/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RailStation+Sort.h"

@implementation RailStation (Sort)

+ (NSArray<RailStation *> *)sortedStations {
    NSMutableArray<RailStation *> *stations = [NSMutableArray array];
    int i;
    int nHotSpots = HotSpotArrays.sharedInstance.hotSpotCount;

    for (i = 0; i < nHotSpots; i++) {
        RailStation *station = [RailStation fromHotSpotIndex:i];

        if (station) {
            [stations addObject:station];
        }
    }

    [stations sortUsingSelector:@selector(compareUsingName:)];

    return stations;
}

- (NSComparisonResult)compareUsingName:(RailStation *)inStation {
    return [self.name compare:inStation.name
                      options:(NSNumericSearch | NSCaseInsensitiveSearch)];
}

@end
