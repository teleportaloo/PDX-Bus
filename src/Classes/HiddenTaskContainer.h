//
//  HiddenTaskContainer.h
//  PDX Bus
//
//  Created by Andy Wallace on 9/7/22.
//  Copyright © 2022 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TaskContainer.h"

@protocol HiddenTaskDone <NSObject>

- (void)hiddenTaskDone:(UIViewController *)viewController
             cancelled:(bool)cancelled;
- (void)hiddenTaskStarted;

@end

@interface HiddenTaskContainer : TaskContainer

@property(atomic, strong) id<HiddenTaskDone> hiddenTaskCallback; // weak

@end
