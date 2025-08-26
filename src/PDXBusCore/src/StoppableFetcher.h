//
//  StoppableFetcher.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/31/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>

@interface StoppableFetcher : NSObject <NSURLSessionDataDelegate>

@property(nonatomic, copy) NSString *networkErrorMsg;
@property(strong) NSMutableData *rawData;
@property(nonatomic) bool timedOut;
@property(nonatomic) float giveUp;
@property(atomic, strong) dispatch_semaphore_t fetchDone;

- (void)fetchDataByPolling:(NSString *)query
               cachePolicy:(NSURLRequestCachePolicy)cachePolicy;
- (void)incrementalBytes:(long long)incremental;
- (instancetype)init;
- (void)cancel;

@end
