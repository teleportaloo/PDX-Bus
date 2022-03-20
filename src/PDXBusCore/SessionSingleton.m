//
//  SessionSingleton.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/12/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "SessionSingleton.h"
#import "DebugLogging.h"
#import "NSHTTPURLResponse+Headers.h"

#define DEBUG_LEVEL_FOR_FILE kLogNetworking

@interface SessionSingleton ()

@property (nonatomic, retain) NSMutableDictionary<NSNumber *, id<NSURLSessionDataDelegate>> *tasks;
@property (nonatomic, retain) NSURLSession *session;
@property (nonatomic, retain) NSURLCache *urlCache;

@end

#define DEBUG_TASK(T) DEBUG_LOGO(T.originalRequest.URL.absoluteString);  DEBUG_LOGO(T)
#define DEBUG_DELEGATE(P) DEBUG_LOGO(P)

@implementation SessionSingleton

static SessionSingleton *singleton;
static NSMutableData *syncObject;

+ (instancetype)sharedInstance {

    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        syncObject = [[NSMutableData alloc] initWithLength:1];
    });
    
    @synchronized (syncObject) {
        if (singleton == nil) {
            singleton = [[SessionSingleton alloc] init];
        }
    }
    
    return singleton;
}

+ (void)clearCache
{
    [[SessionSingleton sharedInstance].urlCache removeAllCachedResponses];
}

+ (NSInteger)cacheSizeInBytes
{
    return [SessionSingleton sharedInstance].urlCache.currentDiskUsage;
}

+ (void)removeTask:(NSURLSessionDataTask *)task {
    [[SessionSingleton sharedInstance] removeTask:task];
}

- (void)removeTask:(NSURLSessionDataTask *)task {
    if (task) {
        @synchronized (syncObject) {
            [self.tasks removeObjectForKey:@(task.taskIdentifier)];
            
            DEBUG_LOG(@"Task done %ld - #%ld", (long)self.tasks.count, (long)task.taskIdentifier);
        }
    }
}

- (instancetype)init {
    if ((self = [super init])) {
        NSUInteger cacheSizeMemory  = 8*1024*1024;
        NSUInteger cacheSizeDisk    = 50*1024*1024;
        
        self.urlCache = [[NSURLCache alloc] initWithMemoryCapacity:cacheSizeMemory diskCapacity:cacheSizeDisk diskPath:nil];
       
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.URLCache = self.urlCache;
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        self.tasks = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (id<NSURLSessionDataDelegate>)delegateForTask:(NSURLSessionTask *)task selector:(SEL)selector {
    NSURLSessionDataTask *dataTask = (NSURLSessionDataTask *)task;
    
    id<NSURLSessionDataDelegate> delegate;
    
    @synchronized (syncObject) {
        delegate = self.tasks[@(dataTask.taskIdentifier)];
    }
    
    if ([delegate respondsToSelector:selector]) {
        return delegate;
    }
    
    return nil;
}

+ (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url cachePolicy:(NSURLRequestCachePolicy)cachePolicy delegate:(id<NSURLSessionDataDelegate>)delegate {
    SessionSingleton *session =  [SessionSingleton sharedInstance];
    
    return [session dataTaskWithURL:url cachePolicy:cachePolicy delegate:delegate];
}

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url cachePolicy:(NSURLRequestCachePolicy)cachePolicy delegate:(id<NSURLSessionDataDelegate>)delegate {
    NSURLSessionDataTask *task = nil;
    
    @synchronized (syncObject) {
        if (self.session != nil) {
            NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:cachePolicy timeoutInterval:DBL_MAX];
            
            task = [self.session dataTaskWithRequest:request];
            
            self.tasks[@(task.taskIdentifier)] = delegate;
            DEBUG_LOG(@"Task started %ld - #%ld", (long)self.tasks.count, (long)task.taskIdentifier);
        }
    }
    return task;
}

- (void)URLSession:(NSURLSession *)session taskIsWaitingForConnectivity:(NSURLSessionTask *)task API_AVAILABLE(macos(10.13), ios(11.0), watchos(4.0), tvos(11.0)) {
    id<NSURLSessionTaskDelegate> delegate = [self delegateForTask:task selector:_cmd];
    
    DEBUG_TASK(task);
    DEBUG_DELEGATE(delegate);
    
    if (delegate) {
        [delegate URLSession:session taskIsWaitingForConnectivity:task];
    }
}


- (void)            URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
    willPerformHTTPRedirection:(NSHTTPURLResponse *)response
                    newRequest:(NSURLRequest *)request
             completionHandler:(void (^)(NSURLRequest *_Nullable))completionHandler {
    id<NSURLSessionTaskDelegate> delegate = [self delegateForTask:task selector:_cmd];
    
    DEBUG_TASK(task);
    DEBUG_DELEGATE(delegate);
    
    if (delegate) {
        [delegate URLSession:session task:task
  willPerformHTTPRedirection:response
                  newRequest:request
           completionHandler:completionHandler];
        return;
    }
    
    completionHandler(request);
}

- (void)          URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
             didSendBodyData:(int64_t)bytesSent
              totalBytesSent:(int64_t)totalBytesSent
    totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    id<NSURLSessionTaskDelegate> delegate = [self delegateForTask:task selector:_cmd];
    
    DEBUG_TASK(task);
    DEBUG_DELEGATE(delegate);
    
    if (delegate) {
        [delegate URLSession:session task:task
             didSendBodyData:bytesSent
              totalBytesSent:totalBytesSent
    totalBytesExpectedToSend:totalBytesExpectedToSend];
    }
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
                                  willCacheResponse:(NSCachedURLResponse *)proposedResponse
                                  completionHandler:(void (^)(NSCachedURLResponse * _Nullable cachedResponse))completionHandler
{
    id<NSURLSessionDataDelegate> delegate = [self delegateForTask:dataTask selector:_cmd];
    
    DEBUG_TASK(dataTask);
    DEBUG_DELEGATE(delegate);
    
    if (delegate) {
        [delegate URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
    } else {
        completionHandler(proposedResponse);
    }
}


- (void)        URLSession:(NSURLSession *)session
                      task:(NSURLSessionTask *)task
didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) {
    id<NSURLSessionTaskDelegate> delegate = [self delegateForTask:task selector:_cmd];
    
    DEBUG_TASK(task);
    DEBUG_DELEGATE(delegate);
    DEBUG_LOG(@"Task time: %@, %f, redirects %d", task.originalRequest.URL.host, metrics.taskInterval.duration, (int)metrics.redirectCount);

    
    if (delegate) {
        [delegate URLSession:session
                        task:task
  didFinishCollectingMetrics:metrics];
    }
}

/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 */
- (void)      URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
    didCompleteWithError:(nullable NSError *)error {
    
    id<NSURLSessionDataDelegate> delegate = [self delegateForTask:task selector:_cmd];
    
    DEBUG_TASK(task);
    DEBUG_DELEGATE(delegate);
    
    if (delegate) {
        [delegate URLSession:session
                        task:task
        didCompleteWithError:error];
    }
    
    [self removeTask:(NSURLSessionDataTask *)task];
}

/* The task has received a response and no further messages will be
 * received until the completion block is called. The disposition
 * allows you to cancel a request or to turn a data task into a
 * download task. This delegate message is optional - if you do not
 * implement it, you can get the response as a property of the task.
 *
 * This method will not be called for background upload tasks (which cannot be converted to download tasks).
 */
- (void)    URLSession:(NSURLSession *)session
              dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveResponse:(NSURLResponse *)response
     completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    id<NSURLSessionDataDelegate> delegate = [self delegateForTask:dataTask selector:_cmd];
    
    DEBUG_TASK(dataTask);
    DEBUG_DELEGATE(delegate);
    
    if (delegate) {
        [delegate   URLSession:session
                      dataTask:dataTask
            didReceiveResponse:response
             completionHandler:completionHandler];
        return;
    }
    
    completionHandler(NSURLSessionResponseAllow);
}

/* Notification that a data task has become a download task.  No
 * future messages will be sent to the data task.
 */
- (void)       URLSession:(NSURLSession *)session
                 dataTask:(NSURLSessionDataTask *)dataTask
    didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    id<NSURLSessionDataDelegate> delegate = [self delegateForTask:dataTask selector:_cmd];
    
    DEBUG_TASK(dataTask);
    DEBUG_DELEGATE(delegate);
    
    if (delegate) {
        [delegate URLSession:session
                    dataTask:dataTask
       didBecomeDownloadTask:downloadTask];
    }
}

/* Sent when data is available for the delegate to consume.  It is
 * assumed that the delegate will retain and not copy the data.  As
 * the data may be discontiguous, you should use
 * [NSData enumerateByteRangesUsingBlock:] to access it.
 */
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    id<NSURLSessionDataDelegate> delegate = [self delegateForTask:dataTask selector:_cmd];
    
    DEBUG_TASK(dataTask);
    DEBUG_DELEGATE(delegate);
    
    if (delegate) {
        [delegate URLSession:session
                    dataTask:dataTask
              didReceiveData:data];
    }
    
#if 0 // Some test code for a random failure
    @synchronized (syncObject) {
        static int killer;
    
        killer++;
    
        if (killer == 5)
        {
            [session invalidateAndCancel];
            killer = 0;
        }
    }
#endif
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
    
    LOG_NSERROR(error);
    
    @synchronized (syncObject) {
        singleton = nil;
        self.session = nil;;
        [self.tasks removeAllObjects];
    }
}


+ (NSCachedURLResponse*)response:(NSCachedURLResponse *)cachedResponse
          withExpirationDuration: (NSTimeInterval)duration {
    
    if ([cachedResponse.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)[cachedResponse response];
       
        
        NSHTTPURLResponse *newResponse = [httpResponse withMaxAge:duration];
        
        cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:newResponse
                                                                  data:[cachedResponse.data mutableCopy]
                                                              userInfo:newResponse.allHeaderFields
                                                         storagePolicy:cachedResponse.storagePolicy];
    }
    return cachedResponse;
}

@end
