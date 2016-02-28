//
//  InterfaceControllerWithBackgroundThread.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/28/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface InterfaceControllerWithBackgroundThread : WKInterfaceController
{
    NSThread *_backgroundThread;
}

@property (atomic, retain) NSThread *backgroundThread;

- (void)startBackgroundTask;
- (void)cancelBackgroundTask;


- (id)backgroundTask;
- (void)taskFinishedMainThread:(id)arg;
@end
