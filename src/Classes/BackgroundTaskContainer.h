//
//  BackgroundTaskContainer.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/20/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ProgressModalView.h"
#import "TaskController.h"
#import <Foundation/Foundation.h>

#import "TaskContainer.h"

@class TaskState;

@protocol BackgroundTaskDone <NSObject>

@property(nonatomic, readonly) UIInterfaceOrientation backgroundTaskOrientation;

- (void)backgroundTaskDone:(UIViewController *)viewController
                 cancelled:(bool)cancelled;

@optional

@property(nonatomic, readonly) bool backgroundTaskWait;

- (void)backgroundTaskStarted;

@end

@interface BackgroundTaskContainer : TaskContainer <ProgressDelegate>

@property(atomic, strong) NSString *title;
@property(strong) ProgressModalView *progressModal; // atomic for thread safety
@property(atomic, strong) NSString *help;
@property(atomic, weak) id<BackgroundTaskDone> callbackComplete; // weak

+ (BackgroundTaskContainer *)create:(id<BackgroundTaskDone>)done;

@end
