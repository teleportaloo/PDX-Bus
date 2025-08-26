//
//  RunParallelBlocks.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/30/21.
//  Maintains NSThread.cancel semantics
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RunParallelBlocks.h"
#import "DebugLogging.h"
#import "Settings.h"
#import "TaskState.h"

#define DEBUG_LEVEL_FOR_FILE LogTask

@interface RunParallelBlocks ()

@property(nonatomic, strong) NSMutableSet<NSThread *> *runningThreads;
@property(nonatomic, strong) NSMutableSet<NSNumber *> *runningBlocks;
@property(nonatomic) NSInteger items;
@property(nonatomic, strong) dispatch_semaphore_t allDone;

@end

@implementation RunParallelBlocks

+ (instancetype)instance {
    return [[[self class] alloc] init];
}

- (instancetype)init {
    if ((self = [super init])) {
        _runningThreads = [NSMutableSet set];
        _runningBlocks = [NSMutableSet set];
    }
    return self;
}

- (void)dealloc {
    DEBUG_FUNC();
}

- (void)runBlock:(ParallelBlock)block {
    if (![NSThread currentThread].isCancelled && block) {
        block();
    }
}

- (void)startBlock:(ParallelBlock)block {
    if (!block)
        return;

    @synchronized(self) {
        if ([NSThread currentThread].isCancelled)
            return;

        if (Settings.networkInParallel) {
            NSInteger key = self.items++;
            __weak typeof(self) weakSelf = self;

            ParallelBlock wrapper = ^{
              __strong typeof(self) strongSelf = weakSelf;
              if (!strongSelf)
                  return; // If self is gone, just bail out

              NSThread *thread = [NSThread currentThread];
              @synchronized(strongSelf) {
                  [strongSelf.runningThreads addObject:thread];
              }

              if (!thread.isCancelled) {
                  block();
              }

              @synchronized(strongSelf) {
                  [strongSelf.runningBlocks removeObject:@(key)];
                  [strongSelf.runningThreads removeObject:thread];

                  DEBUG_LOG(@"Task %ld done. %ld tasks left", (long)key,
                            (long)self.runningBlocks.count)

                  if (strongSelf.runningBlocks.count == 0 &&
                      strongSelf.allDone) {
                      dispatch_semaphore_signal(strongSelf.allDone);
                  }
              }
            };

            [self.runningBlocks addObject:@(key)];
            [self performSelectorInBackground:@selector(runBlock:)
                                   withObject:[wrapper copy]];
        } else {
            self.items++;
            if (![NSThread currentThread].isCancelled) {
                block();
            }
        }
    }
}

- (void)waitForBlocks {
    DEBUG_FUNC();

    @synchronized(self) {
        if (self.runningBlocks.count == 0) {
            DEBUG_FUNCEX();
            return;
        }
        self.allDone = dispatch_semaphore_create(0);

        DEBUG_LOG(@"Waiting for %ld tasks", (long)self.runningBlocks.count)
    }

    while (dispatch_semaphore_wait(
               self.allDone,
               dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.5)) != 0) {

        @synchronized(self) {
            if ([NSThread currentThread].isCancelled) {
                [self cancelAllThreads];
            }
        }
    }

    DEBUG_FUNCEX();
}

#if TARGET_OS_WATCH
#else

- (void)waitForBlocksWithState:(TaskState *)state {
    DEBUG_FUNC();

    @synchronized(self) {
        if (self.runningBlocks.count == 0) {
            DEBUG_FUNCEX();
            return;
        }
        self.allDone = dispatch_semaphore_create(0);

        __weak __typeof(self) weakSelf = self;
        
        [state addCancelObserver:self
                           block:^{
                             [weakSelf cancelAllThreads];
                           }];

        DEBUG_LOG(@"Waiting for %ld tasks", (long)self.runningBlocks.count)
    }

    dispatch_semaphore_wait(self.allDone, DISPATCH_TIME_FOREVER);
    
    @synchronized(self) {
        [state removeCancelObserver:self];
    }

    DEBUG_FUNCEX();
}
#endif

- (void)cancelAllThreads {
    DEBUG_FUNC();
    for (NSThread *thread in self.runningThreads) {
        [thread cancel];
    }
}

@end
