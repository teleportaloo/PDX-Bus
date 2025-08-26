//
//  TaskContainer.h
//  PDX Bus
//
//  Created by Andy Wallace on 9/7/22.
//  Copyright © 2022 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TaskController.h"
#import <Foundation/Foundation.h>

@interface TaskContainer : NSObject <TaskController>

@property(atomic, strong) NSThread *backgroundThread;

@property(nonatomic, readonly) bool running;
@property(atomic, strong) NSString *errMsg;
@property(atomic, strong) UIViewController *controllerToPop;

- (void)finish;

@end
