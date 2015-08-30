//
//  InterfaceControllerWithBackgroundThread.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/28/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

#import "InterfaceControllerWithBackgroundThread.h"

@interface InterfaceControllerWithBackgroundThread ()

@end


@implementation InterfaceControllerWithBackgroundThread


@synthesize backgroundThread = _backgroundThread;

- (void)dealloc
{
    self.backgroundThread = nil;
    
    [super dealloc];
}


- (id)backgroundTask
{
    return nil;
}

- (void)executebackgroundTask:(id)arg
{
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
    
    @synchronized(self)
    {
        self.backgroundThread = nil;
    }
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


- (void)taskFinishedMainThread:(id)arg
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

@end



