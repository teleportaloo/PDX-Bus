//
//  BackgroundTaskContainer.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/20/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "TaskController.h"
#import "ProgressModalView.h"

@protocol BackgroundTaskDone <NSObject>

@property (nonatomic, readonly) UIInterfaceOrientation backgroundTaskOrientation;

- (void)backgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled;

@optional

@property (nonatomic, readonly) bool backgroundTaskWait;

- (void)backgroundTaskStarted;

@end

@class TaskState;

@interface BackgroundTaskContainer : NSObject  <TaskController, ProgressDelegate>

@property (atomic, strong)      NSString *title;
@property (strong)              ProgressModalView *progressModal;             // atomic for thread safety
@property (atomic, weak)        id<BackgroundTaskDone>     callbackComplete;  // weak
@property (atomic, strong)      UIViewController *controllerToPop;
@property (atomic, strong)      NSString *help;
@property (nonatomic, readonly) bool taskCancelled;
@property (nonatomic, readonly) bool running;
@property (atomic)              bool debugMessages;

- (void)taskStartWithTotal:(NSInteger)total title:(NSString *)title;
- (void)taskItemsDone:(NSInteger)itemsDone;
- (void)taskCompleted:(UIViewController *)viewController;
- (void)taskSetErrorMsg:(NSString *)errMsg;
- (void)taskSetHelpText:(NSString *)helpText;
- (void)taskCancel;
- (void)taskRunAsync:(UIViewController * (^)(TaskState *taskState))block;

+ (BackgroundTaskContainer *)create:(id<BackgroundTaskDone>)done;

@end
