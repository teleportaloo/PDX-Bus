//
//  StoppableFetcher.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/31/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "StoppableFetcher.h"
#import "DebugLogging.h"
#import "UserPrefs.h"
#import "PDXBusCore.h"

@implementation StoppableFetcher

@synthesize dataComplete = _dataComplete;
@synthesize rawData = _rawData;
@synthesize connection = _connection;
@synthesize errorMsg = _errorMsg;
@synthesize giveUp = _giveUp;
@synthesize timedOut = _timedOut;


- (instancetype)init
{
	if ((self = [super init]))
	{
		self.giveUp = [UserPrefs sharedInstance].networkTimeout;
	}
	return self;
}

- (void)dealloc {
	self.rawData = nil;
	self.connection = nil;
	self.errorMsg = nil;
	[super dealloc];
}





#ifndef PDXBUS_WATCH

void runSyncOnMainQueueWithoutDeadlocking(void (^block)(void))
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

- (void)fetchDataByPolling:(NSString *)query
{
	const double pollingTime = 0.125;
	NSURL *url = [NSURL URLWithString:query];
	NSURLRequest * request = [NSURLRequest requestWithURL:url];
	
	NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
	NSDate *future = [NSDate dateWithTimeIntervalSinceNow:pollingTime];
	NSThread *thisThread = [NSThread currentThread];
	
	// DEBUG_LOG(@"Query: %@\n", query);
	
	self.rawData = nil; 
	
	self.dataComplete = NO;
	self.timedOut = NO;
	
	self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	[self.connection start];
	
	int pollingCount = 0;
	
	NSDate *giveUpTime = nil;
	
	if (self.giveUp > 0)
	{
		giveUpTime = [NSDate dateWithTimeIntervalSinceNow:self.giveUp];
	}
    
    bool networkActivityIndicatorVisible = NO;

    runSyncOnMainQueueWithoutDeadlocking(^{
        bool networkActivityIndicatorVisible = [UIApplication sharedApplication].networkActivityIndicatorVisible;
        
        if (!networkActivityIndicatorVisible)
        {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        }
    });
	while (!self.dataComplete && [runLoop runMode: NSDefaultRunLoopMode beforeDate:future])
	{
		// NSLog(@"Polling...\n");
		pollingCount ++;
		future = [NSDate dateWithTimeIntervalSinceNow:pollingTime];
		
		if (thisThread.cancelled)
		{
			DEBUG_LOG(@"Cancelled\n");
			self.rawData = nil;
			[self.connection cancel];	
			self.dataComplete = YES;
		}
		
		if (giveUpTime !=nil)
		{
			NSDate *now = [NSDate date];
			DEBUG_LOG(@"Time: %f\n", [giveUpTime timeIntervalSinceDate:now]);
			if ([giveUpTime compare:now] == NSOrderedAscending)
			{
				DEBUG_LOG(@"timed out: %f\n", [giveUpTime timeIntervalSinceDate:now]);
				self.rawData = nil;
				[self.connection cancel];
				self.timedOut = YES;
				self.dataComplete = YES;
			}
			
		}
	}
	
	// DEBUG_LOG(@"Polling count %d\n", pollingCount);
    
    runSyncOnMainQueueWithoutDeadlocking (^{
        if (!networkActivityIndicatorVisible)
        {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        }
        
    });
}
#else

- (void)timerCallback:(id)unused
{
    
}
- (void)fetchDataByPolling:(NSString *)query
{
    NSURLSession *session =  [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    
    NSURL *url = [NSURL URLWithString:query];
    
    NSURLSessionDataTask *task = [session dataTaskWithURL:url];
    
    [task resume];
    
   
    const double pollingTime = 0.25;
    
    NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
    NSDate *future = [NSDate dateWithTimeIntervalSinceNow:pollingTime];
    NSThread *thisThread = [NSThread currentThread];
    
    
    
    // DEBUG_LOG(@"Query: %@\n", query);
    
    self.rawData = nil;
    
    self.dataComplete = NO;
    self.timedOut = NO;
    
    
    int pollingCount = 0;
    
    NSDate *giveUpTime = nil;
    
    if (self.giveUp > 0)
    {
        giveUpTime = [NSDate dateWithTimeIntervalSinceNow:self.giveUp];
    }
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:pollingTime*2 target:self selector:@selector(timerCallback:) userInfo:nil repeats:NO];
    
    [runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
    
    
    while (!self.dataComplete && [runLoop runMode: NSDefaultRunLoopMode beforeDate:future])
    {
        DEBUG_LOG(@"Polling...\n");
        pollingCount ++;
        future = [NSDate dateWithTimeIntervalSinceNow:pollingTime];
        
        [timer invalidate];
        timer = nil;
        
        timer = [NSTimer timerWithTimeInterval:pollingTime*2 target:self selector:@selector(timerCallback:) userInfo:nil repeats:NO];
        [runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
        
        if ([thisThread isCancelled])
        {
            DEBUG_LOG(@"Cancelled\n");
            self.rawData = nil;
            self.dataComplete = YES;
            [task cancel];
        }
        
        if (giveUpTime !=nil)
        {
            NSDate *now = [NSDate date];
            DEBUG_LOG(@"Time: %f\n", [giveUpTime timeIntervalSinceDate:now]);
            if ([giveUpTime compare:now] == NSOrderedAscending)
            {
                DEBUG_LOG(@"timed out: %f\n", [giveUpTime timeIntervalSinceDate:now]);
                self.rawData = nil;
                self.timedOut = YES;
                self.dataComplete = YES;
                [task cancel];
            }
            
        }
    }
    
    [timer invalidate];
    timer = nil;

    [session invalidateAndCancel];
    
    DEBUG_LOG(@"Polling time %f\n", pollingCount * pollingTime);
    
}




#endif


- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    
    if (response.expectedContentLength !=-1 && response.expectedContentLength < (32 * 1024))
    {
        self.rawData = [NSMutableData dataWithCapacity:(NSInteger)response.expectedContentLength];
    }
    else {
        self.rawData = [NSMutableData data];
    }
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    if (self.rawData !=nil)
    {
        // DEBUG_LOG(@"Data %lu\n", (unsigned long)[data length]);
        [self.rawData appendData:data];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    self.dataComplete = YES;
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error
{
    self.dataComplete = YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	// DEBUG_LOG(@"Expected length: %lld\n", response.expectedContentLength);
	
	// Don't pre-allocate more than 32K - seems like it could be a mistake if we need 32K!
	if (response.expectedContentLength !=-1 && response.expectedContentLength < (32 * 1024))
	{
        self.rawData = [NSMutableData dataWithCapacity:(NSInteger)response.expectedContentLength];
	}
	else {
        self.rawData = [NSMutableData data];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (self.rawData !=nil)
	{
		// DEBUG_LOG(@"Data %lu\n", (unsigned long)[data length]);
		[self.rawData appendData:data];
	}
}

- (void)connection:(NSURLConnection *)theConnection didFailWithError:(NSError *)error
{
	self.rawData = nil;
	self.dataComplete = YES;
	self.errorMsg = error.localizedDescription;
	ERROR_LOG(@"Connection error %@\n", [error localizedDescription]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection
{
	self.dataComplete = YES;
}


@end
