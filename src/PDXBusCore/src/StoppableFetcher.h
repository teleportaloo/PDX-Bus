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



@interface StoppableFetcher : NSObject
    <NSURLSessionDelegate
#ifdef BASE_IOS12
        ,NSURLSessionDelegate
#endif
    >
{
    long long           _expected;
    long long           _progress;
}

@property (nonatomic, copy) NSString *errorMsg;

#ifdef BASE_IOS12
@property (strong) NSURLSessionDataTask *connection;
#else
@property (strong) NSURLConnection *connection;
#endif
@property (strong) NSMutableData *rawData;
@property (nonatomic) bool timedOut;
@property (nonatomic) float giveUp;
@property bool dataComplete;

- (void)fetchDataByPolling:(NSString *)query;
- (instancetype)init;
- (void)expectedSize:(long long)expected;
- (void)progressed:(long long)progress;

@end
