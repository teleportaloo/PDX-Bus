//
//  InterfaceControllerWithBackgroundThread.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/28/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "WatchContext.h"
#import "ExtensionDelegate.h"

@interface InterfaceControllerWithBackgroundThread : WKInterfaceController<ExtentionWakeDelegate>

@property (atomic, strong)      NSThread *backgroundThread;
@property (nonatomic, readonly) bool backgroundThreadRunning;

- (void)startBackgroundTask;
- (void)cancelBackgroundTask;

- (void)delayedPush:(WatchContext *)context completion:(void (^)(void))completion;
- (void)sendProgress:(int)progress total:(int)total;

- (id)backgroundTask;
- (void)taskFinishedMainThread:(id)result;
- (void)taskFailedMainThread:(id)result;
- (void)progress:(int)state total:(int)total;
@end
