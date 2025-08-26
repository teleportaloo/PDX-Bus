//
//  DetourSorter.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/7/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Detour.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSMutableDictionary<NSNumber *, Detour *> AllTriMetDetours;

@interface DetourSorter : NSObject

@property(nonatomic, strong) NSMutableOrderedSet<NSNumber *> *detourIds;
@property(atomic, strong) AllTriMetDetours *allDetours;
@property(nonatomic) NSInteger systemWideCount;

- (void)safeAddDetour:(Detour *)detour;
- (void)sort;
- (void)clear;
- (bool)hasNonSystemDetours;

@end

NS_ASSUME_NONNULL_END
