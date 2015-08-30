//
//  InterfaceControllerWithBackgroundThread.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/28/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

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
