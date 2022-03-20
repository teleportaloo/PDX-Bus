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

@property (nonatomic, strong)  id<TaskController> taskController;

@end

@implementation TaskState

+ (instancetype)state:(id<TaskController>)taskController {
    TaskState *state = [[[self class] alloc] init];
    
    state.taskController = taskController;
    
    return state;
}

- (void)displayTotal {
    @synchronized (self) {
        [self.taskController taskTotalItems:self.total];
    }
}

- (void)displayItemsDone {
    @synchronized (self) {
        [self.taskController taskItemsDone:self.itemsDone];
    }
}

- (void)startAtomicTask:(NSString *)title {
    @synchronized (self) {
        self.total = 1;
        [self startTask:title];
    }
}

- (void)atomicTaskItemDone {
    @synchronized (self) {
        self.itemsDone = 1;
        [self displayItemsDone];
    }
}

- (void)startTask:(NSString *)title {
    @synchronized (self) {
        [self.taskController taskStartWithTotal:self.total title:title];
    }
}

- (void)decrementTotalAndDisplay {
    @synchronized (self) {
        self.total--;
        [self displayTotal];
    }
}

- (void)incrementItemsDoneAndDisplay {
    @synchronized (self) {
        self.itemsDone++;
        [self displayItemsDone];
    }
}

- (void)taskStartWithTotal:(NSInteger)total title:(NSString *)title {
    @synchronized (self) {
        self.total = total;
        [self.taskController taskStartWithTotal:total title:title];
    }
}

- (void)taskItemsDone:(NSInteger)itemsDone {
    @synchronized (self) {
        self.itemsDone = itemsDone;
        [self.taskController taskItemsDone:itemsDone];
    }
}

- (void)taskTotalItems:(NSInteger)totalItems {
    @synchronized (self) {
        self.total = totalItems;
        [self.taskController taskTotalItems:totalItems];
    }
}

- (void)taskSubtext:(NSString *)subtext {
    @synchronized (self) {
        [self.taskController taskSubtext:subtext];
    }
}

- (void)taskCompleted:(UIViewController *)viewController {
    @synchronized (self) {
        [self.taskController taskCompleted:viewController];
    }
}

- (void)taskSetErrorMsg:(NSString *)errMsg {
    @synchronized (self) {
        [self.taskController taskSetErrorMsg:errMsg];
    }
}

- (void)taskRunAsync:(UIViewController * (^)(TaskState *))block {
    @synchronized (self) {
        [self.taskController taskRunAsync:block];
    }
}

- (void)taskCancel {
    @synchronized (self) {
        [self.taskController taskCancel];
    }
}

- (bool)taskCancelled {
    @synchronized (self) {
        return [self.taskController taskCancelled];
    }
}

- (bool)debugMessages {
    @synchronized (self) {
        return [self.taskController debugMessages];
    }
}

- (void)triMetXML:(TriMetXML *_Nonnull)xml startedFetchingData:(bool)fromCache {
    @synchronized (self) {
        [self.taskController triMetXML:xml startedFetchingData:fromCache];
    }
}

- (void)triMetXML:(TriMetXML *_Nonnull)xml finishedFetchingData:(bool)fromCache {
    @synchronized (self) {
        [self.taskController triMetXML:xml finishedFetchingData:fromCache];
    }
}


- (void)triMetXML:(TriMetXML * _Nonnull)xml incrementalBytes:(long long)incremental {
    @synchronized (self) {
        [self.taskController triMetXML:xml incrementalBytes:incremental];
    }
}


@end
