//
//  TaskState.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/2/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TaskController.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Provides a task with a local copy of total and items done.  These are not
// automatically refected to the UI until forced by the task. Otherwise this is
// a pass-though, almost a decorator pattern, but it makes is easier to refactor
// tasks into smaller subtasks and understand the flow.

@interface TaskState : NSObject <TaskController>

@property(nonatomic) NSInteger total;
@property(nonatomic) NSInteger itemsDone;

- (void)displayTotal;
- (void)displayItemsDone;
- (void)incrementItemsDoneAndDisplay;
- (void)decrementTotalAndDisplay;
- (void)startTask:(NSString *)title;
- (void)startAtomicTask:(NSString *)title;
- (void)atomicTaskItemDone;

+ (instancetype)state:(id<TaskController>)taskController;

@end

NS_ASSUME_NONNULL_END
