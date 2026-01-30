//
//  TaskState.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/2/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "TaskState.h"

@interface TaskState () {
    dispatch_queue_t _queue;
}

@property (nonatomic, strong) id<TaskController> taskController;

@end

@implementation TaskState

+ (instancetype)state:(id<TaskController>)taskController {
    return [[[self class] alloc] init:taskController];
}

- (instancetype)init:(id<TaskController>)taskController {
    if ((self = [super init])) {
        self.taskController = taskController;
        _queue = dispatch_queue_create("org.teleportaloo.taskstate.queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)displayTotal {
    dispatch_async(_queue, ^{
      [self.taskController taskTotalItems:self.total];
    });
}

- (void)displayItemsDone {
    dispatch_async(_queue, ^{
      [self.taskController taskItemsDone:self.itemsDone];
    });
}

- (void)startAtomicTask:(NSString *)title {
    dispatch_async(_queue, ^{
      self.total = 1;
      [self startTask:title];
    });
}

- (void)atomicTaskItemDone {
    dispatch_async(_queue, ^{
      self.itemsDone = 1;
      [self displayItemsDone];
    });
}

- (void)startTask:(NSString *)title {
    dispatch_async(_queue, ^{
      [self.taskController taskStartWithTotal:self.total title:title];
    });
}

- (void)decrementTotalAndDisplay {
    dispatch_async(_queue, ^{
      self.total--;
      [self displayTotal];
    });
}

- (void)incrementItemsDoneAndDisplay {
    dispatch_async(_queue, ^{
      self.itemsDone++;
      [self displayItemsDone];
    });
}

- (void)taskStartWithTotal:(NSInteger)total title:(NSString *)title {
    dispatch_async(_queue, ^{
      self.total = total;
      [self.taskController taskStartWithTotal:total title:title];
    });
}

- (void)taskItemsDone:(NSInteger)itemsDone {
    dispatch_async(_queue, ^{
      self.itemsDone = itemsDone;
      [self.taskController taskItemsDone:itemsDone];
    });
}

- (void)taskTotalItems:(NSInteger)totalItems {
    dispatch_async(_queue, ^{
      self.total = totalItems;
      [self.taskController taskTotalItems:totalItems];
    });
}

- (void)taskSubtext:(NSString *)subtext {
    dispatch_async(_queue, ^{
      DEBUG_LOG_NSString(subtext);
      [self.taskController taskSubtext:subtext];
    });
}

- (void)taskCompleted:(UIViewController *)viewController {
    dispatch_async(_queue, ^{
      [self.taskController taskCompleted:viewController];
    });
}

- (void)taskSetErrorMsg:(NSString *)errMsg {
    dispatch_async(_queue, ^{
      [self.taskController taskSetErrorMsg:errMsg];
    });
}

- (void)taskRunAsync:(UIViewController * (^)(TaskState *))block {
    dispatch_async(_queue, ^{
      [self.taskController taskRunAsync:block];
    });
}

- (void)taskCancel {
    dispatch_async(_queue, ^{
      [self.taskController taskCancel];
    });
}

- (bool)taskCancelled {
    __block bool result = NO;
    dispatch_sync(_queue, ^{
      result = [self.taskController taskCancelled];
    });
    return result;
}

- (bool)debugMessages {
    __block bool result = NO;
    dispatch_async(_queue, ^{
      result = [self.taskController debugMessages];
    });
    return result;
}

- (void)triMetXML:(TriMetXML *_Nonnull)xml startedFetchingData:(bool)fromCache {
    dispatch_async(_queue, ^{
      [self.taskController triMetXML:xml startedFetchingData:fromCache];
    });
}

- (void)triMetXML:(TriMetXML *_Nonnull)xml finishedFetchingData:(bool)fromCache {
    dispatch_async(_queue, ^{
      [self.taskController triMetXML:xml finishedFetchingData:fromCache];
    });
}

- (void)triMetXML:(TriMetXML *_Nonnull)xml incrementalBytes:(long long)incremental {
    dispatch_async(_queue, ^{
      [self.taskController triMetXML:xml incrementalBytes:incremental];
    });
}

- (void)addCancelObserver:(NSObject *)key block:(dispatch_block_t)block {
    dispatch_async(_queue, ^{
      [self.taskController addCancelObserver:key block:block];
    });
}
- (void)removeCancelObserver:(NSObject *)key {
    dispatch_async(_queue, ^{
      [self.taskController removeCancelObserver:key];
    });
}

@end
