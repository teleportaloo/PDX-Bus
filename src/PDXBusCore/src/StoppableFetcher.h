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



@interface StoppableFetcher : NSObject <NSURLSessionDelegate> {
	NSMutableData *     _rawData;
	bool                _dataComplete;
	NSURLConnection *   _connection;
	NSString *          _errorMsg;
	float               _giveUp;
	bool                _timedOut;

}


@property (nonatomic, copy)   NSString *errorMsg;
@property (retain) NSURLConnection *connection;
@property bool dataComplete;
@property (retain) NSMutableData *rawData;
@property (nonatomic) float giveUp;
@property (nonatomic) bool timedOut;

- (void)fetchDataByPolling:(NSString *)query;
- (instancetype)init;

@end
