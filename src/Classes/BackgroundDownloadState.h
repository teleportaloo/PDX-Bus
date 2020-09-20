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


#import "DataFactory.h"

@class TriMetXML;

typedef void (^backgroundFinalCompletion) (void);
typedef void (^backgroundCompletionHandler) (TriMetXML *xml, backgroundFinalCompletion completion);


@interface BackgroundDownloadState : DataFactory

@property (nonatomic, copy) NSString *progress;
@property (nonatomic, retain) NSURLSessionDownloadTask *task;
@property (nonatomic, retain) TriMetXML *xml;
@property (nonatomic, copy) backgroundCompletionHandler handler;

@end
