//
//  BackgroundTaskContainer.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/20/10.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import "BackgroundTaskContainer.h"
#import "TriMetTimesAppDelegate.h"
#import "debug.h"

@implementation BackgroundTaskContainer

@synthesize progressModal			= _progressModal;
@synthesize callbackComplete		= _callbackComplete;
@synthesize callbackWhenFetching	= _callbackWhenFetching;
@synthesize backgroundThread		= _backgroundThread;
@synthesize title                   = _title;
@synthesize errMsg                  = _errMsg;

static int taskCount;
static NSNumber *syncObject;

- (void)dealloc {
	self.progressModal = nil;
	self.callbackComplete = nil;
	self.callbackWhenFetching = nil;
	self.backgroundThread = nil;
    self.errMsg           = nil;
    [super dealloc];
}

+ (BackgroundTaskContainer*) create:(id<BackgroundTaskDone>) done
{
	BackgroundTaskContainer * btc = [[[BackgroundTaskContainer alloc] init] autorelease];
	
	btc.callbackComplete = done;	
	return btc;
		
}

- (void) ProgressDelegateCancel
{
	[self.backgroundThread cancel];
}

-(void)BackgroundStartMainThread:(id)arg
{
	NSNumber *num = arg;
	TriMetTimesAppDelegate *delegate = (TriMetTimesAppDelegate *)[UIApplication sharedApplication].delegate;
	
	if (self.progressModal == nil)
	{
		
		if ([self.callbackComplete respondsToSelector:@selector(BackgroundTaskStarted)])
		{
			[self.callbackComplete BackgroundTaskStarted];
		}
		
		self.progressModal = [ProgressModalView initWithSuper:delegate.window items:[num intValue] 
														title:self.title
													 delegate:(self.backgroundThread!=nil?self:nil)
												  orientation:[self.callbackComplete BackgroundTaskOrientation]];
		
		[delegate.window addSubview:self.progressModal];
	}
	else 
	{
		self.progressModal.items = [num intValue];
	}
}

-(void)BackgroundStart:(int)items title:(NSString *)title
{
	self.title = title;	
    self.errMsg = nil;
	
	if (syncObject == nil)
	{
		syncObject = [[NSNumber alloc] init];
	}
	
	@synchronized (syncObject)
	{
		taskCount++;
	
		DEBUG_LOG(@"Task count: %d\n", taskCount);
		// Cancel this immediately if there is one already running
		if (taskCount > 1)
		{
			[[NSThread currentThread] cancel];
		}
	}
	
	[self performSelectorOnMainThread:@selector(BackgroundStartMainThread:) withObject:[NSNumber numberWithInt:items] waitUntilDone:YES];
	
	if ([self.callbackComplete respondsToSelector:@selector(BackgroundTaskWait)])
	{
		while([self.callbackComplete BackgroundTaskWait])
		{
			[NSThread sleepForTimeInterval:0.3];
		}
	}	
}


-(void)BackgroundSubtext:(NSString *)subtext
{
	[self.progressModal addSubtext:subtext]; 
	
}

-(void)BackgroundItemsMainThread:(NSNumber*)itemsDone
{
	[self.progressModal itemsDone:[itemsDone intValue]];
}


-(void)BackgroundItemsDone:(int)itemsDone
{
	NSNumber *num = [NSNumber numberWithInt:itemsDone];
	[self performSelectorOnMainThread:@selector(BackgroundItemsMainThread:) withObject:num waitUntilDone:YES];	
}

-(void)BackgroundCompletedMainThread:(UIViewController *)viewController
{
	bool cancelled = (self.backgroundThread !=nil && [self.backgroundThread isCancelled]);
	
	if (self.progressModal)
	{
		[self.progressModal removeFromSuperview];
	}
    if (self.errMsg)
    {
        UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:nil
                                                           message:self.errMsg
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil ] autorelease];
        [alert show];
    }
	[self.callbackComplete BackgroundTaskDone:viewController cancelled:cancelled];
	self.callbackWhenFetching = nil;
	self.progressModal = nil;
	self.backgroundThread = nil;
	
	@synchronized (syncObject)
	{
		taskCount--;
	}
}

- (void)BackgroundThread:(NSThread *)thread
{
	self.backgroundThread = thread;	
}

-(void)BackgroundCompleted:(UIViewController *)viewController
{
	
	[self performSelectorOnMainThread:@selector(BackgroundCompletedMainThread:) withObject:viewController waitUntilDone:YES];	
}

- (void)BackgroundSetErrorMsg:(NSString *)errMsg
{
    self.errMsg = errMsg;
}


@end
