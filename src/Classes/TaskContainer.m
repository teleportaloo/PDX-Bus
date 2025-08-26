//
//  TaskContainer.m
//  PDX Bus
//
//  Created by Andy Wallace on 9/7/22.
//  Copyright © 2022 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogTask

#import "TaskContainer.h"
#import "BackgroundTaskContainer.h"
#import "DebugLogging.h"
#import "MainQueueSync.h"
#import "RootViewController.h"
#import "TaskDispatch.h"
#import "TaskState.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIApplication+Compat.h"

@interface TaskContainer ()
@property(atomic, retain)
    NSMapTable<NSObject *, dispatch_block_t> *cancelObservers;

@end

@implementation TaskContainer

- (void)taskCancel {
    DEBUG_FUNC();

    if (self.backgroundThread != nil) {

        if (!self.backgroundThread.cancelled) {
            [self.backgroundThread cancel];
            for (dispatch_block_t block in self.cancelObservers
                     .objectEnumerator) {
                block();
            }
        }
    }
}

- (void)addCancelObserver:(NSObject *)key block:(dispatch_block_t)block {
    [self.cancelObservers setObject:block forKey:key];
}

- (void)removeCancelObserver:(NSObject *)key {
    [self.cancelObservers removeObjectForKey:key];
}

- (bool)taskCancelled {
    DEBUG_FUNC();

    if (self.backgroundThread == nil) {
        return YES;
    }

    return self.backgroundThread.isCancelled;
}

- (bool)running {
    return (self.backgroundThread != nil);
}

- (instancetype)init {
    if ((self = [super init])) {
        self.cancelObservers = [NSMapTable
            mapTableWithKeyOptions:NSPointerFunctionsOpaquePersonality
                      valueOptions:NSPointerFunctionsStrongMemory];
    }

    return self;
}

- (void)taskStartWithTotal:(NSInteger)total title:(NSString *)title {
    self.backgroundThread = [NSThread currentThread];
}

- (void)taskSubtext:(NSString *)subtext {
}

- (void)taskItemsDone:(NSInteger)itemsDone {
}

- (void)taskTotalItems:(NSInteger)totalItems {
}

- (void)finish {
    DEBUG_FUNC();

    self.controllerToPop = nil;
    self.backgroundThread = nil;
}

- (void)runBlock:(UIViewController * (^)(TaskState *taskState))block {
    static NSMutableData *globalSyncObject;

    DoOnce(^{
      globalSyncObject = [[NSMutableData alloc] initWithLength:1];
    });

    // This forces the background thread only to run one at a time - no
    // deadlock!

    @synchronized(globalSyncObject) {
        @autoreleasepool {
            self.backgroundThread = [NSThread currentThread];
            TaskState *taskState = [TaskState state:self];

            NSDate *start = [NSDate date];

            // Run the block (synchronously here, but could be async if you
            // wrap)
            // We ensure we at least block for a while as otherwise the
            // screen flashes and it is annoying.
            UIViewController *result = block(taskState);

            NSTimeInterval elapsed =
                [[NSDate date] timeIntervalSinceDate:start];
            NSTimeInterval remaining = 0.3 - elapsed;

            if (remaining > 0) {
                [NSThread sleepForTimeInterval:remaining];
            }

            [self taskCompleted:result];
        }
    }
}

- (void)taskRunAsync:(UIViewController * (^)(TaskState *state))block {
    // We need to use the NSThread mechanism so we can cancel it easily, but I
    // want to use the blocks as it makes the passing of variables very easy.
    [self performSelectorInBackground:@selector(runBlock:)
                           withObject:[block copy]];
}

- (void)taskCompleted:(UIViewController *)viewController {
    DEBUG_FUNC();
    DEBUG_PROGRESS(self, @"task done");

    [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
      DEBUG_FUNC();
      self.controllerToPop = viewController;

      DEBUG_PROGRESS(self, @"finishing");

      if (self.errMsg) {
          UIAlertController *alert =
              [UIAlertController simpleOkWithTitle:nil message:self.errMsg];

          UIViewController *top = UIApplication.topViewController;

          [top presentViewController:alert
                            animated:YES
                          completion:^{
                            [self finish];
                          }];
          self.errMsg = nil;
      } else {
          DEBUG_LOG(@"finish");
          [self finish];
      }
    }];
}

- (void)taskSetErrorMsg:(NSString *)errMsg {
    self.errMsg = errMsg;
}

- (bool)debugMessages {
    return NO;
}

- (void)taskSetHelpText:(NSString *)helpText {
}

- (void)triMetXML:(TriMetXML *)xml startedFetchingData:(bool)fromCache {
}

- (void)triMetXML:(TriMetXML *)xml finishedFetchingData:(bool)fromCache {
}

- (void)triMetXML:(TriMetXML *_Nonnull)xml
    incrementalBytes:(long long)incremental {
}

@end
