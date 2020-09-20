//
//  CodeWriter.h
//  PDX Bus
//
//  Created by Andrew Wallace on 3/7/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "NSString+Helper.h"

#ifdef CREATE_MAX_ARRAYS
#define CODE_COMMENT(A)            CODE_LOG(@"\n%@\n",  [NSString textSeparatedStringFromEnumerator:(A) selector:@selector(self) separator:@"\n"])
#define CODE_FILE(X)               CODE_RULE; CODE_LOG(@"// FILE :%@", (X)); CODE_RULE;
#define CODE_RULE         CODE_STRING(@"//------------------------------------------------------------------------------")
#define CODE_LOG(format, args ...) [CodeWriter write:[NSString stringWithFormat:(format), ## args]]
#define CODE_STRING(S)             [CodeWriter write:(S)]
#define CODE_LOG_FILE_END [CodeWriter dump]
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CodeWriter : NSObject

+ (void)write:(NSString *)str;
+ (void)        dump;
+ (CodeWriter *)sharedInstance;

@end

NS_ASSUME_NONNULL_END
