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


#define DEBUG_LEVEL_FOR_FILE LogNet

#import "StoppableFetcher.h"
#import "DebugLogging.h"
#import "MainQueueSync.h"
#import "NSHTTPURLResponse+Headers.h"
#import "PDXBusCore.h"
#import "SessionSingleton.h"
#import "Settings.h"

@interface StoppableFetcher () {
    long long _progress;
    long long _expected;
}

@property(strong) NSURLSessionDataTask *sessionDataTask;
@property(atomic) bool dataReady;

@end

@implementation StoppableFetcher

- (instancetype)init {
    if ((self = [super init])) {
        _giveUp = Settings.networkTimeout;
    }

    return self;
}

- (void)dealloc {
    DEBUG_FUNC();
}

- (void)cancel {
    [self.sessionDataTask cancel];
}

- (long long)expected {
    return _expected;
}

- (void)setNetworkActivityVisable:(bool)visable {
}

- (void)fetchDataByPolling:(NSString *)query
               cachePolicy:(NSURLRequestCachePolicy)cachePolicy {
    DEBUG_FUNC();

    @synchronized(self) {
        const double pollingTime = 0.2;
        NSURL *url = [NSURL URLWithString:query];
        NSThread *thisThread = [NSThread currentThread];

        self.rawData = nil;
        self.fetchDone = dispatch_semaphore_create(0);
        self.timedOut = NO;

        self.sessionDataTask = [SessionSingleton dataTaskWithURL:url
                                                     cachePolicy:cachePolicy
                                                        delegate:self];

        if (self.sessionDataTask) {
            [self.sessionDataTask resume];

            int pollingCount = 0;

            NSDate *giveUpTime = nil;

            if (self.giveUp > 0) {
                giveUpTime = [NSDate dateWithTimeIntervalSinceNow:self.giveUp];
            }

            self.dataReady = NO;

            [self setNetworkActivityVisable:YES];

            while (dispatch_semaphore_wait(
                       self.fetchDone,
                       dispatch_time(DISPATCH_TIME_NOW,
                                     NSEC_PER_SEC * pollingTime)) != 0) {
                DEBUG_LOG_description(self.fetchDone);
                pollingCount++;

                if (thisThread.cancelled) {
                    DEBUG_LOG(@"Cancelled\n");
                    self.rawData = nil;
                    [self.sessionDataTask cancel];
                    dispatch_semaphore_signal(self.fetchDone);
                    DEBUG_LOG_description(self.fetchDone);
                }

                if (giveUpTime != nil) {
                    NSDate *now = [NSDate date];
                    DEBUG_LOG(@"Time: %f\n",
                              [giveUpTime timeIntervalSinceDate:now]);

                    if ([giveUpTime compare:now] == NSOrderedAscending) {
                        DEBUG_LOG(@"timed out: %f\n",
                                  [giveUpTime timeIntervalSinceDate:now]);
                        self.rawData = nil;
                        [self.sessionDataTask cancel];
                        self.timedOut = YES;
                        dispatch_semaphore_signal(self.fetchDone);
                        DEBUG_LOG_description(self.fetchDone);
                    }
                }
            }
            DEBUG_LOG_description(self.fetchDone);

            self.dataReady = YES;

            [SessionSingleton removeTask:self.sessionDataTask];
            self.fetchDone = nil;
            self.sessionDataTask = nil;
        }

        [self setNetworkActivityVisable:NO];
    }

    DEBUG_LOG(@"Data done: %lu\n", (unsigned long)self.rawData.length);
}

- (void)URLSession:(NSURLSession *)session
              dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveResponse:(NSURLResponse *)response
     completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))
                           completionHandler {
    if (response.expectedContentLength != -1 &&
        response.expectedContentLength < (32 * 1024)) {
        self.rawData = [NSMutableData
            dataWithCapacity:(NSInteger)response.expectedContentLength];
    } else {
        self.rawData = [NSMutableData data];
    }

    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;

        if (httpResponse.olderThanMaxAge) {
            completionHandler(NSURLSessionResponseCancel);
            return;
        }
    }

    DEBUG_LOG_MAYBE(_expected != response.expectedContentLength,
                    @"Expected length changed: %lld\n",
                    response.expectedContentLength);

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

- (void)URLSession:(NSURLSession *)session
                    task:(NSURLSessionTask *)task
    didCompleteWithError:(NSError *)error {
    
    if (error && !self.dataReady) {
           self.rawData = nil;
           self.networkErrorMsg = error.localizedDescription;
           ERROR_LOG(@"Connection error: %@", error.localizedDescription);
       }

       dispatch_semaphore_t sem = self.fetchDone;   // take a snapshot
       if (sem) {
           dispatch_semaphore_signal(sem);
       } else {
           // Optional: log unexpected nil; helps prove the race
           ERROR_LOG(@"fetchDone was nil at completion (race?)");
       }

       DEBUG_LOG(@"fetchDone=%p signaled", sem);
}

- (void)incrementalBytes:(long long)incremental {
}

@end
