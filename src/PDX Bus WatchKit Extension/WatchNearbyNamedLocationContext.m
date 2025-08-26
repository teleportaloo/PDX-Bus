//
//  WatchNearbyNamedLocationContext.m
//  PDX Bus WatchKit Extension
//
//  Created by Andrew Wallace on 4/26/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchNearbyNamedLocationContext.h"
#import "WatchNearbyInterfaceController.h"

@implementation WatchNearbyNamedLocationContext

- (instancetype)init {
    if ((self = [super initWithSceneName:kNearbyScene])) {
    }
    return self;
}

+ (WatchNearbyNamedLocationContext *)contextWithName:(NSString *)name
                                            location:(CLLocation *)loc {
    WatchNearbyNamedLocationContext *result =
        [[WatchNearbyNamedLocationContext alloc] init];

    result.name = name;
    result.loc = loc;

    return result;
}

@end
