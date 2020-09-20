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


#import "TaskState.h"

@interface TaskState ()

@property (nonatomic, retain)  id<TaskController> taskController;

@end

@implementation TaskState

+ (instancetype)state:(id<TaskController>)taskController {
    TaskState *state = [[[self class] alloc] init];
    
    state.taskController = taskController;
    
    return state;
}

- (void)displayTotal {
    [self.taskController taskTotalItems:self.total];
}

- (void)displayItemsDone {
    [self.taskController taskItemsDone:self.itemsDone];
}

- (void)startAtomicTask:(NSString *)title {
    self.total = 1;
    [self startTask:title];
}

- (void)atomicTaskItemDone {
    self.itemsDone = 1;
    [self displayItemsDone];
}

- (void)startTask:(NSString *)title {
    [self.taskController taskStartWithTotal:self.total title:title];
}

- (void)decrementTotalAndDisplay {
    self.total--;
    [self displayTotal];
}

- (void)incrementItemsDoneAndDisplay {
    self.itemsDone++;
    [self displayItemsDone];
}

- (void)taskStartWithTotal:(NSInteger)total title:(NSString *)title {
    self.total = total;
    [self.taskController taskStartWithTotal:total title:title];
}

- (void)taskItemsDone:(NSInteger)itemsDone {
    self.itemsDone = itemsDone;
    [self.taskController taskItemsDone:itemsDone];
}

- (void)taskTotalItems:(NSInteger)totalItems {
    self.total = totalItems;
    [self.taskController taskTotalItems:totalItems];
}

- (void)taskSubtext:(NSString *)subtext {
    [self.taskController taskSubtext:subtext];
}

- (void)taskCompleted:(UIViewController *)viewController {
    [self.taskController taskCompleted:viewController];
}

- (void)taskSetErrorMsg:(NSString *)errMsg {
    [self.taskController taskSetErrorMsg:errMsg];
}

- (void)taskRunAsync:(UIViewController * (^)(TaskState *))block {
    [self.taskController taskRunAsync:block];
}

- (void)taskCancel {
    [self.taskController taskCancel];
}

- (bool)taskCancelled {
    return [self.taskController taskCancelled];
}

- (bool)debugMessages {
    return [self.taskController debugMessages];
}

- (void)triMetXML:(TriMetXML *_Nonnull)xml finishedParsingData:(NSUInteger)size fromCache:(bool)fromCache {
    [self.taskController triMetXML:xml finishedParsingData:size fromCache:fromCache];
}

- (void)triMetXML:(TriMetXML *_Nonnull)xml startedParsingData:(NSUInteger)size fromCache:(bool)fromCache {
    [self.taskController triMetXML:xml startedParsingData:size fromCache:fromCache];
}

- (void)triMetXML:(TriMetXML *_Nonnull)xml startedFetchingData:(bool)fromCache {
    [self.taskController triMetXML:xml startedFetchingData:fromCache];
}

- (void)triMetXML:(TriMetXML *_Nonnull)xml finishedFetchingData:(bool)fromCache {
    [self.taskController triMetXML:xml finishedFetchingData:fromCache];
}

- (void)triMetXML:(TriMetXML *_Nonnull)xml expectedSize:(long long)expected {
    [self.taskController triMetXML:xml expectedSize:expected];
}

- (void)triMetXML:(TriMetXML *_Nonnull)xml progress:(long long)progress of:(long long)expected {
    [self.taskController triMetXML:xml progress:progress of:expected];
}

@end
