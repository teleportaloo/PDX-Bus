//
//  BackgroundDownloader.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/26/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//

#import "TriMetXML.h"
#import "BackgroundDownloadState.h"



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


NS_ASSUME_NONNULL_BEGIN

@interface BackgroundDownloader : NSObject <NSURLSessionDelegate>

+ (BackgroundDownloader *)sharedInstance;

- (bool)startFetchInBackground:(TriMetXML *)xml query:(NSString*)query completion:(BackgroundCompletionHandler)completionHander;
- (bool)isFetching:(NSString*)query;
- (void)cancel:(NSString*)query;
- (NSString * _Nullable)progess:(NSString*)query;

@end

NS_ASSUME_NONNULL_END
