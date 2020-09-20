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


#import <Foundation/Foundation.h>
#import "Detour.h"

NS_ASSUME_NONNULL_BEGIN

@interface DetourSorter : DataFactory

@property (nonatomic, strong) NSMutableOrderedSet<NSNumber*> *detourIds;
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, Detour*> *allDetours;
@property (nonatomic) NSInteger systemWideCount;

- (void)add:(Detour *)detour;
- (void)sort;
- (void)clear;

@end

NS_ASSUME_NONNULL_END
