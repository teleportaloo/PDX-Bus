//
//  LinkChecker.h
//  PDX BusTests
//
//  Created by Andrew Wallace on 5/9/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LinkChecker : NSObject<NSURLSessionDelegate>
{

}

@property (nonatomic, copy) NSString *context;

+ (instancetype)withContext:(NSString *)context;
- (instancetype)initWithContext:(NSString *)context;
- (void)checkWikiLink:(NSString *)wiki;
- (void)checkLink:(NSString *)link;
- (void)checkLinksInAttributedString:(NSAttributedString *)string;

- (bool)done;
- (void)waitUntilDone;

@end

NS_ASSUME_NONNULL_END
