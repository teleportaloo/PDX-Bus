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


#define DEBUG_LEVEL_FOR_FILE kLogNetworking

#import "StoppableFetcher.h"
#import "DebugLogging.h"
#import "Settings.h"
#import "PDXBusCore.h"
#import "MainQueueSync.h"
#import "SessionSingleton.h"
#import "NSHTTPURLResponse+Headers.h"

@interface StoppableFetcher () {
    long long _progress;
    long long _expected;
}

@property (strong) NSURLSessionDataTask *sessionDataTask;
@property (atomic) bool dataReady;

@end

@implementation StoppableFetcher

- (instancetype)init {
    if ((self = [super init])) {
        self.giveUp = Settings.networkTimeout;
    }
    
    return self;
}

- (void)cancel {
    [self.sessionDataTask cancel];
}

- (void)dealloc {
    DEBUG_FUNC();
}

- (long long)expected {
    return _expected;
}

- (void)setNetworkActivityVisable:(bool)visable
{
#if !defined(PDXBUS_EXTENSION) && !TARGET_OS_MACCATALYST && !defined(PDXBUS_WATCH)
    [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
        UIApplication *app = [UIApplication sharedApplication];
        
        if (app.networkActivityIndicatorVisible!=visable) {
            app.networkActivityIndicatorVisible = visable;
        }
    }];
#endif
}

- (void)fetchDataByPolling:(NSString *)query cachePolicy:(NSURLRequestCachePolicy)cachePolicy {
    DEBUG_FUNC();
    
    @synchronized (self) {
        const double pollingTime = 0.2;
        NSURL *url = [NSURL URLWithString:query];
        NSThread *thisThread = [NSThread currentThread];
        
        self.rawData = nil;
        self.fetchDone = dispatch_semaphore_create(0);
        self.timedOut = NO;
        
        self.sessionDataTask = [SessionSingleton dataTaskWithURL:url cachePolicy:cachePolicy delegate:self];
        
        if (self.sessionDataTask)
        {
            [self.sessionDataTask resume];
            
            int pollingCount = 0;
            
            NSDate *giveUpTime = nil;
            
            if (self.giveUp > 0) {
                giveUpTime = [NSDate dateWithTimeIntervalSinceNow:self.giveUp];
            }
            
            self.dataReady = NO;
            
            [self setNetworkActivityVisable:YES];
            
            while (dispatch_semaphore_wait(self.fetchDone, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * pollingTime)) != 0) {
                DEBUG_LOGO(self.fetchDone);
                pollingCount++;
                
                if (thisThread.cancelled) {
                    DEBUG_LOG(@"Cancelled\n");
                    self.rawData = nil;
                    [self.sessionDataTask cancel];
                    dispatch_semaphore_signal(self.fetchDone);
                    DEBUG_LOGO(self.fetchDone);
                }
                
                if (giveUpTime != nil) {
                    NSDate *now = [NSDate date];
                    DEBUG_LOG(@"Time: %f\n", [giveUpTime timeIntervalSinceDate:now]);
                    
                    if ([giveUpTime compare:now] == NSOrderedAscending) {
                        DEBUG_LOG(@"timed out: %f\n", [giveUpTime timeIntervalSinceDate:now]);
                        self.rawData = nil;
                        [self.sessionDataTask cancel];
                        self.timedOut = YES;
                        dispatch_semaphore_signal(self.fetchDone);
                        DEBUG_LOGO(self.fetchDone);
                    }
                }
            }
            DEBUG_LOGO(self.fetchDone);
            
            self.dataReady = YES;
            
            [SessionSingleton removeTask:self.sessionDataTask];
            self.fetchDone = nil;
            self.sessionDataTask = nil;
        }
        
        [self setNetworkActivityVisable:NO];
    }
    
    
    DEBUG_LOG(@"Data done: %lu\n", (unsigned long)self.rawData.length);
}

- (void)    URLSession:(NSURLSession *)session
              dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveResponse:(NSURLResponse *)response
     completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    if (response.expectedContentLength != -1 && response.expectedContentLength < (32 * 1024)) {
        self.rawData = [NSMutableData dataWithCapacity:(NSInteger)response.expectedContentLength];
    } else {
        self.rawData = [NSMutableData data];
    }
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        
        if (httpResponse.olderThanMaxAge) {
            completionHandler(NSURLSessionResponseCancel);
            return;
        }
    }
    
    DEBUG_LOG_MAYBE(_expected != response.expectedContentLength, @"Expected length changed: %lld\n", response.expectedContentLength);
    
    _expected = response.expectedContentLength;
    _progress = 0;
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    if (self.rawData != nil) {
        // DEBUG_LOG(@"Data %lu\n", (unsigned long)[data length]);
        [self.rawData appendData:data];
        
        _progress += data.length;
        [self incrementalBytes:data.length];
    }
}

- (void)      URLSession:(NSURLSession *)session
                    task:(NSURLSessionTask *)task
    didCompleteWithError:(NSError *)error {
    if (error != nil && self.dataReady == NO) {
        self.rawData = nil;
        self.networkErrorMsg = error.localizedDescription;
        ERROR_LOG(@"Connection error %@\n", [error localizedDescription]);
    }
    
    dispatch_semaphore_signal(self.fetchDone);
    DEBUG_LOGO(self.fetchDone);
}

- (void)incrementalBytes:(long long)incremental {
}

@end
