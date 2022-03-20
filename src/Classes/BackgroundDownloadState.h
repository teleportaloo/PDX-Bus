//
//  BackgroundDownloadState.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/26/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


@class TriMetXML;

typedef void (^BackgroundFinalCompletion) (void);
typedef void (^BackgroundCompletionHandler) (TriMetXML *xml, BackgroundFinalCompletion completion);


@interface BackgroundDownloadState : NSObject

@property (nonatomic, copy) NSString *progress;
@property (nonatomic, strong) NSURLSessionDownloadTask *task;
@property (nonatomic, strong) TriMetXML *xml;
@property (nonatomic, copy) BackgroundCompletionHandler handler;

@end
