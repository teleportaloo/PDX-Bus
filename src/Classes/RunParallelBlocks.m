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

@interface RunParallelBlocks () {
    dispatch_queue_t _syncQueue;
    dispatch_semaphore_t _allDone;
}

@property (nonatomic, strong) NSMutableSet<NSThread *> *rawRunningThreads;
@property (nonatomic, strong) NSMutableSet<NSNumber *> *rawRunningBlocks;
@property (nonatomic) NSInteger items;

@end

@implementation RunParallelBlocks

+ (instancetype)instance {
    return [[[self class] alloc] init];
}

- (instancetype)init {
    if ((self = [super init])) {
        _rawRunningThreads = [NSMutableSet set];
        _rawRunningBlocks = [NSMutableSet set];
        _syncQueue = dispatch_queue_create("org.teleportaloo.pdxbus.parallel.sync",
                                           DISPATCH_QUEUE_CONCURRENT);
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

- (NSInteger)nextKey {
    __block NSInteger key = 0;
    dispatch_barrier_sync(_syncQueue, ^{
      key = self.items++;
    });
    return key;
}

- (void)startBlock:(ParallelBlock)block {
    if (!block)
        return;

    if ([NSThread currentThread].isCancelled)
        return;

    if (Settings.networkInParallel) {
        NSInteger key = self.nextKey;
        __weak typeof(self) weakSelf = self;

        ParallelBlock wrapper = ^{
          __strong typeof(self) strongSelf = weakSelf;
          if (!strongSelf)
              return; // If self is gone, just bail out

          NSThread *thread = [NSThread currentThread];
          dispatch_barrier_async(self->_syncQueue, ^{
            [strongSelf.rawRunningThreads addObject:thread];
          });

          if (!thread.isCancelled) {
              block();
          }

          dispatch_barrier_sync(self->_syncQueue, ^{
            [strongSelf.rawRunningBlocks removeObject:@(key)];
            [strongSelf.rawRunningThreads removeObject:thread];

            DEBUG_LOG(
                @"Task %ld done. %ld tasks left", (long)key, (long)self.rawRunningBlocks.count);

            if (self.rawRunningBlocks.count == 0 && strongSelf->_allDone) {
                dispatch_semaphore_signal(strongSelf->_allDone);
            }
          });
        };

        dispatch_barrier_async(self->_syncQueue, ^{
          [self.rawRunningBlocks addObject:@(key)];
        });

        [self performSelectorInBackground:@selector(runBlock:) withObject:[wrapper copy]];
    } else {
        (void)self.nextKey;
        if (![NSThread currentThread].isCancelled) {
            block();
        }
    }
}

- (NSInteger)runningCount {
    __block NSInteger count = 0;
    dispatch_sync(_syncQueue, ^{
      count = self.rawRunningBlocks.count;
    });
    return count;
}

- (void)waitForBlocks {
    DEBUG_FUNC();

    if (self.runningCount == 0) {
        DEBUG_FUNCEX();
        return;
    }

    _allDone = dispatch_semaphore_create(0);

    DEBUG_LOG(@"Waiting for %ld tasks", (long)self.rawRunningBlocks.count);

    while (dispatch_semaphore_wait(_allDone,
                                   dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.5)) != 0) {

        if ([NSThread currentThread].isCancelled) {
            [self cancelAllThreads];
        }
    }

    DEBUG_FUNCEX();
}

#if TARGET_OS_WATCH
#else

- (void)waitForBlocksWithState:(TaskState *)state {
    DEBUG_FUNC();

    if (self.runningCount == 0) {
        DEBUG_FUNCEX();
        return;
    }

    _allDone = dispatch_semaphore_create(0);

    __weak __typeof(self) weakSelf = self;

    [state addCancelObserver:self
                       block:^{
                         __strong typeof(self) strongSelf = weakSelf;
                         if (!strongSelf)
                             return; //
                         [strongSelf cancelAllThreads];
                       }];

    DEBUG_LOG(@"Waiting for %ld tasks", (long)self.rawRunningBlocks.count);

    dispatch_semaphore_wait(_allDone, DISPATCH_TIME_FOREVER);

    [state removeCancelObserver:self];

    DEBUG_FUNCEX();
}
#endif // TARGET_OS_WATCH

- (void)cancelAllThreads {
    DEBUG_LOG(@"Cancelling all threads");
    dispatch_sync(_syncQueue, ^{
      for (NSThread *thread in self.rawRunningThreads) {
          [thread cancel];
      }
    });
}

@end
