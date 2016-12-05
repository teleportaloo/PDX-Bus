//
//  BackgroundTaskContainer.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/20/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BackgroundTaskContainer.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"
#import "DebugLogging.h"

@implementation BackgroundTaskContainer

@synthesize progressModal			= _progressModal;
@synthesize callbackComplete		= _callbackComplete;
@synthesize callbackWhenFetching	= _callbackWhenFetching;
@synthesize backgroundThread		= _backgroundThread;
@synthesize title                   = _title;
@synthesize help                    = _help;
@synthesize errMsg                  = _errMsg;
@synthesize controllerToPop         = _controllerToPop;

static int taskCount;
static NSNumber *syncObject;

- (void)dealloc {
	self.progressModal = nil;
	self.callbackComplete = nil;
	self.callbackWhenFetching = nil;
	self.backgroundThread = nil;
    self.errMsg           = nil;
    self.controllerToPop  = nil;
    self.help             = nil;
    self.title            = nil;
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

-(void)BackgroundStartMainThread:(NSNumber *)items
{
	TriMetTimesAppDelegate *app = [TriMetTimesAppDelegate singleton];
	
	if (self.progressModal == nil)
	{
		
		if ([self.callbackComplete respondsToSelector:@selector(backgroundTaskStarted)])
		{
			[self.callbackComplete backgroundTaskStarted];
		}
		
		self.progressModal = [ProgressModalView initWithSuper:app.window items:items.intValue
														title:self.title
													 delegate:(self.backgroundThread!=nil?self:nil)
												  orientation:[self.callbackComplete BackgroundTaskOrientation]];
		
		[app.window addSubview:self.progressModal];
        
        [self.progressModal addHelpText:self.help];
	}
	else 
	{
		self.progressModal.totalItems = items.intValue;
	}
}


-(void)backgroundStart:(int)items title:(NSString *)title
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
	
        DEBUG_LOGLU(taskCount);
		// Cancel this immediately if there is one already running
		if (taskCount > 1)
		{
			[[NSThread currentThread] cancel];
		}
        else
        {
            self.backgroundThread = [NSThread currentThread];
        }
	}
	
	[self performSelectorOnMainThread:@selector(BackgroundStartMainThread:) withObject:@(items) waitUntilDone:YES];
	
	if ([self.callbackComplete respondsToSelector:@selector(backgroundTaskWait)])
	{
		while([self.callbackComplete backgroundTaskWait])
		{
			[NSThread sleepForTimeInterval:0.3];
		}
	}	
}


-(void)backgroundSubtext:(NSString *)subtext
{
	[self.progressModal addSubtext:subtext]; 
	
}

-(void)BackgroundItemsDoneMainThread:(NSNumber*)itemsDone
{
	[self.progressModal itemsDone:itemsDone.intValue];
}


-(void)backgroundItemsDone:(int)itemsDone
{
	[self performSelectorOnMainThread:@selector(BackgroundItemsDoneMainThread:) withObject:@(itemsDone) waitUntilDone:YES];
}

-(void)BackgroundTotalItemsMainThread:(NSNumber*)totalItems
{
    [self.progressModal totalItems:totalItems.intValue];
}

-(void)backgroundItems:(int)totalItems
{
    [self performSelectorOnMainThread:@selector(BackgroundTotalItemsMainThread:) withObject:@(totalItems) waitUntilDone:YES];
}


-(void)finish
{
    bool cancelled = (self.backgroundThread !=nil && self.backgroundThread.cancelled);
    [self.callbackComplete BackgroundTaskDone:self.controllerToPop cancelled:cancelled];
    self.controllerToPop = nil;
    self.backgroundThread = nil;
    
    self.callbackWhenFetching = nil;
	self.progressModal = nil;
	
	
	@synchronized (syncObject)
	{
		taskCount--;
	}
}

-(void)BackgroundCompletedMainThread:(UIViewController *)viewController
{

    
    self.controllerToPop = viewController;
	
	if (self.progressModal)
	{
		[self.progressModal removeFromSuperview];
	}
    
    if (self.errMsg)
    {
        UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:nil
                                                           message:self.errMsg
                                                          delegate:self
                                                 cancelButtonTitle:NSLocalizedString(@"OK", @"button text")
                                                 otherButtonTitles:nil ] autorelease];
        [alert show];
    }
    else
    {
        [self finish];
    }
	
}

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self finish];
}


-(void)backgroundCompleted:(UIViewController *)viewController
{
	[self performSelectorOnMainThread:@selector(BackgroundCompletedMainThread:) withObject:viewController waitUntilDone:YES];	
}

- (void)backgroundSetErrorMsg:(NSString *)errMsg
{
    self.errMsg = errMsg;
}

- (void)BackgroundSetHelpText:(NSString *)helpText
{
    [self.progressModal addHelpText:helpText];
}


@end
