//
//  NSHTTPURLResponse+Headers.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/11/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define HTTP_NO_AGE (-1)

@interface NSHTTPURLResponse (Headers)

- (NSHTTPURLResponse *)withMaxAge:(NSTimeInterval)duration;
- (NSDate *)headerDate;
- (NSTimeInterval)headerMaxAge;
- (bool)olderThanMaxAge;
- (NSDate * _Nullable)maxAgeDate;
- (bool)hasMaxAge;

@end

NS_ASSUME_NONNULL_END
