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

@interface StoppableFetcher : NSObject <NSURLSessionDelegate>


@property (nonatomic, copy) NSString *errorMsg;
@property (strong) NSMutableData *rawData;
@property (nonatomic) bool timedOut;
@property (nonatomic) float giveUp;
@property (atomic) bool dataComplete;


- (void)fetchDataByPolling:(NSString *)query;
- (instancetype)init;
- (void)expectedSize:(long long)expected;
- (void)progressed:(long long)progress expected:(long long)expected;
- (void)cancel;

@end
