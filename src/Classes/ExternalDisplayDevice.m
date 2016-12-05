//
//  ExternalDisplayDevice.m
//  PDX Bus
//
//  Created by Andrew Wallace on 12/29/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ExternalDisplayDevice.h"

@implementation ExternalDisplayDevice

@synthesize delegate = _delegate;
@synthesize taskKey = _taskKey;

- (void)getSupportAndStartCallbacks
{
    
}

- (void)displayEnded:(AlarmFetchArrivalsTask *)task
{
    
}

- (void)updateDisplay:(AlarmFetchArrivalsTask *)task
{
    
}

- (bool)running
{
    return NO;
}


- (instancetype)init
{
    if ((self = [super init]))
    {
        self.delegate = nil;
        self.taskKey  = nil;
    }
    return self;
}

- (void)dealloc{
    self.taskKey = nil;
    self.delegate = nil;
    [super dealloc];
}

@end
