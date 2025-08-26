//
//  BackGroundDownloader.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/26/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BackgroundDownloader.h"
#import "Settings.h"
#import "TaskDispatch.h"

@interface BackgroundDownloader ()

@property(strong, atomic)
    NSMutableDictionary<NSString *, NSString *> *absQueryFromOriginal;
@property(strong, atomic)
    NSMutableDictionary<NSString *, BackgroundDownloadState *>
        *stateForAbsQuery;

@end

@implementation BackgroundDownloader

- (instancetype)init {
    if ((self = [super init])) {
        self.stateForAbsQuery = [NSMutableDictionary dictionary];
        self.absQueryFromOriginal = [NSMutableDictionary dictionary];
    }

    return self;
}

+ (NSString *)absQuery:(NSURLSessionDownloadTask *)task {
    NSURLRequest *originalRequest = task.originalRequest;

    return originalRequest.URL.absoluteString;
}

+ (BackgroundDownloader *)sharedInstance {
    static BackgroundDownloader *singleton = nil;

    DoOnce(^{
      singleton = [[BackgroundDownloader alloc] init];
    });

    return singleton;
}

- (bool)isFetching:(NSString *)query {
    @synchronized(self.absQueryFromOriginal) {
        NSString *absQuery = self.absQueryFromOriginal[query];
        return absQuery != nil;
    }
}

- (void)cancel:(NSString *)query {
    @synchronized(self.absQueryFromOriginal) {
        NSString *absQuery = self.absQueryFromOriginal[query];

        if (absQuery) {
            BackgroundDownloadState *state = self.stateForAbsQuery[absQuery];

            if (state) {
                state.progress = nil;
                [state.task cancel];
            }
        }
    }
}

- (bool)startFetchInBackground:(TriMetXML *)xml
                         query:(NSString *)query
                    completion:(BackgroundCompletionHandler)completionHander;
{
    @synchronized(self.absQueryFromOriginal) {
        if (self.absQueryFromOriginal[query] != nil) {
            return NO;
        }

        NSString *fullQuery =  xml.queryTransformer(xml, query);

        NSURLRequest *request =
            [NSURLRequest requestWithURL:[NSURL URLWithString:fullQuery]];

        NSURLSessionConfiguration *config = [NSURLSessionConfiguration
            backgroundSessionConfigurationWithIdentifier:@"PDX Bus background"];

        config.requestCachePolicy =
            NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
        config.allowsCellularAccess = !Settings.kmlWifiOnly;

        NSURLSession *backgroundSession = [NSURLSession
            sessionWithConfiguration:config
                            delegate:self
                       delegateQueue:[NSOperationQueue mainQueue]];

        NSURLSessionDownloadTask *task =
            [backgroundSession downloadTaskWithRequest:request];

        NSString *absQuery = [BackgroundDownloader absQuery:task];

        self.absQueryFromOriginal[fullQuery] = absQuery;

        BackgroundDownloadState *state = [BackgroundDownloadState new];

        state.task = task;
        state.handler = completionHander;
        state.xml = xml;
        xml.cacheTime = [NSDate date];
        state.progress = NSLocalizedString(@"0%", "@inital progress");

        self.stateForAbsQuery[absQuery] = state;
        [task resume];
    }

    return YES;
}

- (void)URLSession:(NSURLSession *)session
                 downloadTask:(NSURLSessionDownloadTask *)downloadTask
                 didWriteData:(int64_t)bytesWritten
            totalBytesWritten:(int64_t)totalBytesWritten
    totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    @synchronized(self.absQueryFromOriginal) {
        NSString *absQuery = [BackgroundDownloader absQuery:downloadTask];
        BackgroundDownloadState *state = self.stateForAbsQuery[absQuery];

        if (totalBytesExpectedToWrite > 0) {
            double percentDone =
                (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
            state.progress =
                [NSString stringWithFormat:@"%.0f%%", percentDone * 100.0];
        } else {
            NSString *result = nil;

            if (bytesWritten < 1024) {
                result =
                    [NSString stringWithFormat:@"%d Bytes", (int)bytesWritten];
            } else if (bytesWritten < (1024 * 1024)) {
                result = [NSString
                    stringWithFormat:@"%.2f K",
                                     (((float)(bytesWritten)) / 1024.0)];
            } else {
                result = [NSString
                    stringWithFormat:@"%.2f MB",
                                     ((float)(bytesWritten) / (1024 * 1024))];
            }

            state.progress = result;
        }
    }
}

- (void)URLSession:(NSURLSession *)session
                 downloadTask:(NSURLSessionDownloadTask *)downloadTask
    didFinishDownloadingToURL:(NSURL *)location {
    @synchronized(self.absQueryFromOriginal) {
        NSString *absQuery = [BackgroundDownloader absQuery:downloadTask];
        // Either move the data from the location to a permanent location, or do
        // something with the data at that location.
        BackgroundDownloadState *state = self.stateForAbsQuery[absQuery];

        if (state && state.xml) {
            state.xml.rawData = [NSMutableData dataWithContentsOfURL:location];

            NSError *error = nil;

            if (![[NSFileManager defaultManager] removeItemAtURL:location
                                                           error:&error]) {
                LOG_NSError(error);
            }

            if (state.handler) {
                state.handler(state.xml, ^{
                  [self remove:absQuery];
                });
            } else {
                [self remove:absQuery];
            }
        }
    }
}

- (void)remove:(NSString *)absQuery {
    @synchronized(self.absQueryFromOriginal) {
        [self.stateForAbsQuery removeObjectForKey:absQuery];

        [self.absQueryFromOriginal
            enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key,
                                                NSString *_Nonnull obj,
                                                BOOL *_Nonnull stop) {
              if ([obj isEqualToString:absQuery]) {
                  *stop = YES;
                  [self.absQueryFromOriginal removeObjectForKey:key];
              }
            }];
    }
}

- (void)URLSession:(NSURLSession *)session
                    task:(NSURLSessionTask *)task
    didCompleteWithError:(nullable NSError *)error {
    @synchronized(self.absQueryFromOriginal) {
        if ([task isKindOfClass:[NSURLSessionDownloadTask class]]) {
            NSURLSessionDownloadTask *downloadTask =
                (NSURLSessionDownloadTask *)task;

            NSString *absQuery = [BackgroundDownloader absQuery:downloadTask];

            [self remove:absQuery];
        }

        [session invalidateAndCancel];
    }
}

- (NSString *)progess:(NSString *)query {
    @synchronized(self.absQueryFromOriginal) {
        NSString *absQuery = self.absQueryFromOriginal[query];

        if (absQuery) {
            BackgroundDownloadState *state = self.stateForAbsQuery[absQuery];

            if (state) {
                return state.progress;
            }
        }
    }
    return nil;
}

@end
