//
//  SessionSingleton.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/12/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SessionSingleton
    : NSObject <NSURLSessionDataDelegate, NSURLSessionDelegate>

+ (instancetype)sharedInstance;
- (NSURLSessionDataTask *_Nullable)
    dataTaskWithURL:(NSURL *)url
        cachePolicy:(NSURLRequestCachePolicy)cachePolicy
           delegate:(id<NSURLSessionDataDelegate>)delegate;
+ (NSURLSessionDataTask *_Nullable)
    dataTaskWithURL:(NSURL *)url
        cachePolicy:(NSURLRequestCachePolicy)cachePolicy
           delegate:(id<NSURLSessionDataDelegate>)delegate;
+ (void)removeTask:(NSURLSessionDataTask *)task;
+ (void)clearCache;
+ (NSCachedURLResponse *)response:(NSCachedURLResponse *)cachedResponse
           withExpirationDuration:(NSTimeInterval)duration;
+ (NSInteger)cacheSizeInBytes;

@end

NS_ASSUME_NONNULL_END
