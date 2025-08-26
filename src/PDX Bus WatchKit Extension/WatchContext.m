//
//  WatchContext.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "WatchContext.h"
#import "DebugLogging.h"
#import "TaskDispatch.h"

@implementation WatchContext

+ (instancetype)contextWithSceneName:(NSString *)sceneName {
    return [[[self class] alloc] initWithSceneName:sceneName];
}

- (instancetype)initWithSceneName:(NSString *)sceneName {
    if ((self = [super init])) {
        self.sceneName = sceneName;
    }
    return self;
}

- (void)pushFrom:(WKInterfaceController *)parent {
    [parent pushControllerWithName:self.sceneName context:self];
}

- (void)delayedPushFrom:(WKInterfaceController *)parent
             completion:(void (^)(void))completion {
    DEBUG_LOG(@"delayedPushFrom: %@\n", self.sceneName);

    MainTaskDelay(0.4, ^{
      [parent pushControllerWithName:self.sceneName context:self];

      if (completion) {
          completion();
      }
    });
}

@end
