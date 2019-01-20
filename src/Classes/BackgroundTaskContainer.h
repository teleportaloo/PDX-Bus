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
#import "BackgroundTaskController.h"
#import "ProgressModalView.h"

@protocol BackgroundTaskDone <NSObject>

@property (nonatomic, readonly) UIInterfaceOrientation backgroundTaskOrientation;

- (void)backgroundTaskDone:(UIViewController*)viewController cancelled:(bool)cancelled;

@optional

@property (nonatomic, readonly) bool backgroundTaskWait;

- (void)backgroundTaskStarted;

@end


@interface BackgroundTaskContainer : NSObject  <BackgroundTaskController,ProgressDelegate>

@property (atomic, strong)      NSString *                 title;
@property (strong)              ProgressModalView *        progressModal;     // atomic for thread safety
@property (atomic, weak)        id<BackgroundTaskDone>     callbackComplete;  // weak
@property (atomic, strong)      NSString *                 errMsg;
@property (atomic, strong)      UIViewController *         controllerToPop;
@property (atomic, strong)      NSString *                 help;
@property (atomic, strong)      NSThread *                 backgroundThread;
@property (nonatomic, readonly) bool                       taskCancelled;
@property (nonatomic, readonly) bool                       running;
@property (atomic)              bool                       debugMessages;

- (void)taskStartWithItems:(NSInteger)items title:(NSString *)title;
- (void)taskItemsDone:(NSInteger)itemsDone;
- (void)taskCompleted:(UIViewController*)viewController;
- (void)taskSetErrorMsg:(NSString *)errMsg;
- (void)taskSetHelpText:(NSString*)helpText;
- (void)taskCancel;
- (void)taskRunAsync:(UIViewController * (^)(void)) block;


+ (BackgroundTaskContainer*) create:(id<BackgroundTaskDone>) done;

@end
