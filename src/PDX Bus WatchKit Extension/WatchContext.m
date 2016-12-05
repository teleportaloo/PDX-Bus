//
//  WatchContext.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/15.
//  Copyright © 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchContext.h"
#import "DebugLogging.h"

@implementation WatchContext

- (void)dealloc
{
    self.sceneName = nil;
    [super dealloc];
}

- (void)pushFrom:(WKInterfaceController *)parent
{
    [parent pushControllerWithName:self.sceneName context:self];
}

- (void)delayedPushFrom:(WKInterfaceController *)parent
{
    DEBUG_LOG(@"delayedPushFrom: %@\n", self.sceneName);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
       [parent pushControllerWithName:self.sceneName context:self];
    });
    
}



@end
