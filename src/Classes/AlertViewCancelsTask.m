//
//  AlertViewCancelsTask.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/21/11.
//  Copyright (c) 2011 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "AlertViewCancelsTask.h"

@implementation AlertViewCancelsTask

@synthesize backgroundTask = _backgroundTask;
@synthesize caller         = _caller;

- (void)dealloc
{
    self.backgroundTask = nil;
    self.caller         = nil;
    
    [super dealloc];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.backgroundTask.callbackWhenFetching backgroundCompleted:self.caller];
    [self release];
}


@end
