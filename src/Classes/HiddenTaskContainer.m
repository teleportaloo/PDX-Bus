//
//  HiddenTaskContainer.m
//  PDX Bus
//
//  Created by Andy Wallace on 9/7/22.
//  Copyright © 2022 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogTask

#import "HiddenTaskContainer.h"

@implementation HiddenTaskContainer

- (void)dealloc {
    _hiddenTaskCallback = nil;
}

- (void)finish {
    DEBUG_FUNC();

    bool cancelled =
        (self.backgroundThread != nil && self.backgroundThread.cancelled);

    [self.hiddenTaskCallback hiddenTaskDone:self.controllerToPop
                                  cancelled:cancelled];

    [super finish];

    self.hiddenTaskCallback = nil;
}

@end
