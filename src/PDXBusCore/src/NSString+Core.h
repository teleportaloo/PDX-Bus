//
//  NSString+Core.h
//  PDX Bus
//
//  Created by Andy Wallace on 3/9/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "NSString+Convenience.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Core)

// UI helpers
- (NSMutableString *_Nonnull)phonetic;

@end

NS_ASSUME_NONNULL_END
