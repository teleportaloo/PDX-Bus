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

#if TARGET_OS_WATCH
#else
@class TaskState;
#endif

typedef void (^ParallelBlock)(void);

@interface RunParallelBlocks : NSObject

+ (instancetype)instance;

- (void)startBlock:(ParallelBlock)block;
- (void)waitForBlocks;

#if TARGET_OS_WATCH
#else
- (void)waitForBlocksWithState:(TaskState *)state;
#endif

@end

NS_ASSUME_NONNULL_END


