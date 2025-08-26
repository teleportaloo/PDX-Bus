//
//  StoppableFetcherTests.m
//  PDX BusTests
//
//  Created by Andy Wallace on 8/20/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


@import XCTest;
@import ObjectiveC.runtime;

#import "SessionSingleton.h"
#import "StoppableFetcher.h"

// MARK: - Test URLProtocol
// Produces a 200 OK after a configurable delay, or never completes if delay <
// 0.
static NSTimeInterval gCompletionDelay = 1.0;

static NSString *const kHandledKey = @"com.pdxbus.DelayedURLProtocol.handled";

@interface DelayedURLProtocol : NSURLProtocol
@end

@implementation DelayedURLProtocol
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if ([NSURLProtocol propertyForKey:kHandledKey inRequest:request])
        return NO;
    return YES;
}
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSMutableURLRequest *r = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:kHandledKey inRequest:r];

    if (gCompletionDelay < 0) {
        // Intentionally never call client; used to hold the request forever.
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(gCompletionDelay * NSEC_PER_SEC)),
                   dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
                     NSHTTPURLResponse *resp =
                         [[NSHTTPURLResponse alloc] initWithURL:r.URL
                                                     statusCode:200
                                                    HTTPVersion:@"HTTP/1.1"
                                                   headerFields:@{}];
                     [self.client URLProtocol:self
                           didReceiveResponse:resp
                           cacheStoragePolicy:NSURLCacheStorageNotAllowed];
                     NSData *data =
                         [@"ok" dataUsingEncoding:NSUTF8StringEncoding];
                     [self.client URLProtocol:self didLoadData:data];
                     [self.client URLProtocolDidFinishLoading:self];
                   });
}
- (void)stopLoading {
}
@end

// MARK: - Swizzle SessionSingleton to return a session using our URLProtocol
// Production method signature we’re replacing:
//
// + (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url
//                               cachePolicy:(NSURLRequestCachePolicy)cachePolicy
//                                  delegate:(id<NSURLSessionDataDelegate>)delegate;

static NSURLSessionDataTask *
Test_dataTaskWithURL(id selfClass, SEL _cmd, NSURL *url,
                     NSURLRequestCachePolicy cachePolicy,
                     id<NSURLSessionDataDelegate> delegate) {
    NSURLSessionConfiguration *cfg =
        [NSURLSessionConfiguration ephemeralSessionConfiguration];
    cfg.requestCachePolicy = cachePolicy;
    cfg.protocolClasses = @[ DelayedURLProtocol.class ];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:cfg
                                                          delegate:delegate
                                                     delegateQueue:nil];
    return [session dataTaskWithURL:url];
}

static IMP gOrigIMP = NULL;

static void SwizzleSessionSingleton(void) {
    Class cls = objc_getClass("SessionSingleton");
    SEL sel = @selector(dataTaskWithURL:cachePolicy:delegate:);
    Method m = class_getClassMethod(cls, sel);
    gOrigIMP = method_getImplementation(m);
    method_setImplementation(m, (IMP)Test_dataTaskWithURL);
}

static void UnswizzleSessionSingleton(void) {
    if (!gOrigIMP)
        return;
    Class cls = objc_getClass("SessionSingleton");
    SEL sel = @selector(dataTaskWithURL:cachePolicy:delegate:);
    Method m = class_getClassMethod(cls, sel);
    method_setImplementation(m, gOrigIMP);
    gOrigIMP = NULL;
}

// MARK: - Tests

@interface StoppableFetcherTests : XCTestCase
@end

@implementation StoppableFetcherTests

+ (void)setUp {
    [super setUp];
    SwizzleSessionSingleton();
}

+ (void)tearDown {
    UnswizzleSessionSingleton();
    [super tearDown];
}

// Helper to run fetch synchronously (StoppableFetcher already blocks inside)
- (StoppableFetcher *)runFetcherWithURLString:(NSString *)url
                                       giveUp:(NSTimeInterval)giveUp
                              completionDelay:(NSTimeInterval)delay
                                     cancelAt:(NSTimeInterval)cancelAtOrNegOne {
    gCompletionDelay = delay;

    StoppableFetcher *f = [[StoppableFetcher alloc] init];
    f.giveUp = (float)giveUp;

    // Start on a background thread so we can cancel if needed
    XCTestExpectation *done =
        [self expectationWithDescription:@"fetch finished"];

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
      [f fetchDataByPolling:url cachePolicy:NSURLRequestUseProtocolCachePolicy];
      [done fulfill];
    });

    if (cancelAtOrNegOne >= 0) {
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW,
                          (int64_t)(cancelAtOrNegOne * NSEC_PER_SEC)),
            dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
              [f cancel];
            });
    }

    [self waitForExpectations:@[ done ] timeout:10.0];
    return f;
}

// 1) Timeout occurs BEFORE the URLSession completes. Later, delegate fires with
// error.
//    This used to crash if didComplete signaled a nil semaphore.
//    With your guarded signal, it should be safe and `timedOut == YES`.
- (void)testTimeoutThenLateCompletion_NoCrash_TimedOutSet {
    // Make the protocol finish after 1.0s, but give up after 0.2s
    StoppableFetcher *f =
        [self runFetcherWithURLString:@"https://example.com/slow"
                               giveUp:0.2
                      completionDelay:1.0
                             cancelAt:-1];

    XCTAssertTrue(f.timedOut,
                  @"Expected timedOut to be set after giveUp threshold.");
    XCTAssertNil(f.rawData, @"Raw data should be nil on timeout.");
    // If you log "fetchDone was nil at completion" from the delegate, that
    // indicates the race was hit and survived.
}

// 2) Explicit cancel happens BEFORE the URLSession completes.
//    Expect no crash and nil data / no timedOut flag.
- (void)testCancelThenLateCompletion_NoCrash {
    // Completion after 1.0s; cancel at 0.1s; no timeout window
    StoppableFetcher *f =
        [self runFetcherWithURLString:@"https://example.com/cancel"
                               giveUp:5.0
                      completionDelay:1.0
                             cancelAt:0.1];

    XCTAssertFalse(f.timedOut, @"Cancel path should not mark timedOut.");
    XCTAssertNil(f.rawData, @"Raw data should be nil after cancel.");
}

// 3) Successful request within giveUp window.
//    Expect data present and not timed out.
- (void)testSuccess_NoTimeout_NoCancel {
    // Completion after 0.1s; giveUp after 2.0s
    StoppableFetcher *f =
        [self runFetcherWithURLString:@"https://example.com/ok"
                               giveUp:2.0
                      completionDelay:0.1
                             cancelAt:-1];

    XCTAssertFalse(f.timedOut);
    XCTAssertNotNil(f.rawData);
    XCTAssertGreaterThan(f.rawData.length, 0u);
}

@end
