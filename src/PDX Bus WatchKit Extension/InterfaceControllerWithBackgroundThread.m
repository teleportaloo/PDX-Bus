//
//  InterfaceControllerWithBackgroundThread.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/28/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "InterfaceControllerWithBackgroundThread.h"
#import "DebugLogging.h"

@interface InterfaceControllerWithBackgroundThread ()

@end


@implementation InterfaceControllerWithBackgroundThread



- (id)backgroundTask
{
    return nil;
}

- (bool)backgroundThreadRunning
{
    @synchronized(self)
    {
        return self.backgroundThread !=nil;
    }
}

- (void)executebackgroundTask:(id)unused
{
    @autoreleasepool {
    
        @synchronized(self)
        {
            if (self.backgroundThread !=nil)
            {
                return;
            }
            
            self.backgroundThread = [NSThread currentThread];
        }
        
        id result = [self backgroundTask];
        
        if (![NSThread currentThread].isCancelled)
        {
            [self performSelectorOnMainThread:@selector(taskFinishedMainThread:) withObject:result waitUntilDone:NO];
        }
        else
        {
            ExtensionDelegate  *extensionDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
            
            if (extensionDelegate.backgrounded)
            {
                DEBUG_LOG(@"Saving for wake\n");
                extensionDelegate.wakeDelegate = self;
            }
            
            [self performSelectorOnMainThread:@selector(taskFailedMainThread:) withObject:result waitUntilDone:NO];
        }
        
        @synchronized(self)
        {
            self.backgroundThread = nil;
        }
    
    }
}

- (void)extentionForgrounded
{
    [self startBackgroundTask];
}

-(void)receiveProgress:(id)unused
{
    [self progress:_progress total:_total];
}

- (void)sendProgress:(int)progress total:(int)total
{
    _progress = progress;
    _total = total;
    
    [self performSelectorOnMainThread:@selector(receiveProgress:) withObject:nil waitUntilDone:NO];

}


- (void)startBackgroundTask
{
    @synchronized(self)
    {
        [NSThread detachNewThreadSelector:@selector(executebackgroundTask:) toTarget:self withObject:nil];
    }
}

- (void)cancelBackgroundTask
{
    @synchronized(self)
    {
        [self.backgroundThread cancel];
    }
}

- (void)progress:(int)state total:(int)total
{
    
}

- (void)taskFinishedMainThread:(id)result
{
    
}

- (void)taskFailedMainThread:(id)result
{
    
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [self cancelBackgroundTask];
    [super didDeactivate];
}

- (void)delayedPush:(WatchContext *)context completion:(void (^)(void))block
{
    if (!self.displayed)
    {
        self.delayedContext = context;
        self.delayedBlock = block;
    }
    else
    {
        [context delayedPushFrom:self completion:block];
    }
}

- (void)didAppear
{
    self.displayed = YES;

    if (self.delayedContext)
    {
        [self.delayedContext delayedPushFrom:self completion:self.delayedBlock];
        self.delayedContext = nil;
        self.delayedBlock = nil;
    }
}

@end



