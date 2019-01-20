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


#import "WatchContext.h"
#import "DebugLogging.h"

@implementation WatchContext


- (void)pushFrom:(WKInterfaceController *)parent
{
    [parent pushControllerWithName:self.sceneName context:self];
}

- (void)delayedPushFrom:(WKInterfaceController *)parent completion:(void (^)(void))completion
{
    DEBUG_LOG(@"delayedPushFrom: %@\n", self.sceneName);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [parent pushControllerWithName:self.sceneName context:self];
        if (completion)
        {
            completion();
        }
    });
    
}



@end
