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
#import "Settings.h"
#import "PDXBusCore.h"
#import "MainQueueSync.h"

@interface StoppableFetcher () {
    long long _progress;
    long long _expected;
}

@property (strong) NSURLSessionDataTask *sessionDataTask;

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

- (void)fetchDataByPolling:(NSString *)query {
    DEBUG_FUNC();
    const double pollingTime = 0.25;
    NSURL *url = [NSURL URLWithString:query];
    NSThread *thisThread = [NSThread currentThread];
    
    // DEBUG_LOG(@"Query: %@\n", query);
    
    self.rawData = nil;
    
    self.dataComplete = NO;
    self.timedOut = NO;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
    self.sessionDataTask = [session dataTaskWithURL:url];
    [self.sessionDataTask resume];
    
    int pollingCount = 0;
    
    NSDate *giveUpTime = nil;
    
    if (self.giveUp > 0) {
        giveUpTime = [NSDate dateWithTimeIntervalSinceNow:self.giveUp];
    }
    
    [self setNetworkActivityVisable:YES];

    while (!self.dataComplete) {
        [NSThread sleepForTimeInterval:pollingTime];
        
        // NSLog(@"Polling...\n");
        pollingCount++;
        
        if (thisThread.cancelled) {
            DEBUG_LOG(@"Cancelled\n");
            self.rawData = nil;
            [self.sessionDataTask cancel];
            self.dataComplete = YES;
        }
        
        if (giveUpTime != nil) {
            NSDate *now = [NSDate date];
            DEBUG_LOG(@"Time: %f\n", [giveUpTime timeIntervalSinceDate:now]);
            
            if ([giveUpTime compare:now] == NSOrderedAscending) {
                DEBUG_LOG(@"timed out: %f\n", [giveUpTime timeIntervalSinceDate:now]);
                self.rawData = nil;
                [self.sessionDataTask cancel];
                self.timedOut = YES;
                self.dataComplete = YES;
            }
        }
    }
    
    DEBUG_LOG(@"Data done: %lu\n", (unsigned long)self.rawData.length);
    
    [self setNetworkActivityVisable:NO];
    
    [session invalidateAndCancel];
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
    
    DEBUG_LOG_MAYBE(_expected != response.expectedContentLength, @"Expected length changed: %lld\n", response.expectedContentLength);
    
    _expected = response.expectedContentLength;
    _progress = 0;
    [self expectedSize:_expected];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    if (self.rawData != nil) {
        // DEBUG_LOG(@"Data %lu\n", (unsigned long)[data length]);
        [self.rawData appendData:data];
        
        _progress += data.length;
        [self progressed:_progress expected:_expected];
    }
}

- (void)      URLSession:(NSURLSession *)session
                    task:(NSURLSessionTask *)task
    didCompleteWithError:(NSError *)error {
    if (error != nil && self.dataComplete == NO) {
        self.rawData = nil;
        self.dataComplete = YES;
        self.errorMsg = error.localizedDescription;
        ERROR_LOG(@"Connection error %@\n", [error localizedDescription]);
    } else {
        self.dataComplete = YES;
    }
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
    if (error != nil && self.dataComplete == NO) {
        self.rawData = nil;
        self.dataComplete = YES;
        self.errorMsg = error.localizedDescription;
        ERROR_LOG(@"Connection error %@\n", [error localizedDescription]);
    } else {
        self.dataComplete = YES;
    }
}

- (void)expectedSize:(long long)expected {
}

- (void)progressed:(long long)progress expected:(long long)expected {
}

@end
