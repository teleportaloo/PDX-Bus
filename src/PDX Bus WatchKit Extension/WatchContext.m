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

- (void)pushFrom:(WKInterfaceController *)parent
{
    [parent pushControllerWithName:self.sceneName context:self];
}

- (void)delayedTimerFired:(NSTimer *)timer
{
    WKInterfaceController *parent = timer.userInfo;
    
    DEBUG_LOG(@"delayedTimerFired: %@ parent\n%@\n", self.sceneName, parent.description);
    
    [parent pushControllerWithName:self.sceneName context:self];
}

- (void)delayedPushFrom:(WKInterfaceController *)parent
{
    DEBUG_LOG(@"delayedPushFrom: %@\n", self.sceneName);
    [NSTimer scheduledTimerWithTimeInterval:0.3
                                     target:self
                                   selector:@selector(delayedTimerFired:)
                                   userInfo:parent
                                    repeats:NO];
}



@end
