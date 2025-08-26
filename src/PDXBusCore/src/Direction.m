//
//  Direction.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/11/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Direction.h"

@implementation Direction

+ (Direction *)withDir:(NSString *)dir desc:(NSString *)desc {
    Direction *direction = [Direction new];

    direction.dir = dir;
    direction.desc = desc;

    return direction;
}

- (NSComparisonResult)compare:(Direction *)other {
    return [self.dir compare:other.dir];
}

@end
