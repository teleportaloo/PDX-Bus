//
//  RunParallelBlocks.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/30/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef  void (^ParallelBlock)(void);

@interface RunParallelBlocks : NSObject

+ (instancetype)instance;

- (void)startBlock:(ParallelBlock)block;
- (void)waitForBlocks;

@end

NS_ASSUME_NONNULL_END
