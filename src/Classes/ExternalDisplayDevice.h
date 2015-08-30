//
//  ExternalDisplayDevice.h
//  PDX Bus
//
//  Created by Andrew Wallace on 12/29/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import <Foundation/Foundation.h>

@class ExternalDisplayDevice;
@class AlarmFetchArrivalsTask;

@protocol  ExternalDisplayDeviceDelegate <NSObject>

- (void)displayAvailable:(ExternalDisplayDevice*)display;
- (void)displayGone:(ExternalDisplayDevice*)display;
- (void)updateSent:(ExternalDisplayDevice*)display;

@end

@interface ExternalDisplayDevice : NSObject
{
    id<ExternalDisplayDeviceDelegate> _delegate;
    NSString *_taskKey;
}
@property (nonatomic, assign) id<ExternalDisplayDeviceDelegate> delegate; // weak
@property (nonatomic, retain) NSString *taskKey;

- (void)getSupportAndStartCallbacks;
- (void)displayEnded:(AlarmFetchArrivalsTask *)task;
- (void)updateDisplay:(AlarmFetchArrivalsTask *)task;
- (bool)running;


@end
