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


#import "NSString+Core.h"
#import <Foundation/Foundation.h>

#define CODE_COMMENT(A)                                                                            \
    CODE_LOG(                                                                                      \
        @"\n%@\n",                                                                                 \
        [NSString textSeparatedStringFromEnumerator:(A) selector:@selector(self) separator:@"\n"])
#define CODE_FILE(X)                                                                               \
    do {                                                                                           \
        [CodeWriter file:X];                                                                       \
        CODE_RULE;                                                                                 \
        CODE_LOG(@"// FILE: %@", (X));                                                             \
        CODE_RULE;                                                                                 \
        CODE_LOG(@"// clang-format off");                                                          \
        CODE_LOG(@"// uncrustify-off");                                                            \
    } while (0)
#define CODE_RULE                                                                                  \
    CODE_STRING(@"//"                                                                              \
                @"-------------------------------------------------------------------------------" \
                @"-------------------")
#define CODE_LOG(format, args...)                                                                  \
    do {                                                                                           \
        [CodeWriter write:[NSString stringWithFormat:(format), ##args]];                           \
    } while (0)
#define CODE_STRING(S)                                                                             \
    do {                                                                                           \
        [CodeWriter write:(S)];                                                                    \
    } while (0)
#define CODE_LOG_FILE_END                                                                          \
    do {                                                                                           \
        [CodeWriter dump];                                                                         \
        [CodeWriter moveIntoPlace];                                                                \
    } while (0)

// Gap here to stop script replacing this macro
#define CODE_LICENSE                                                                               \
    CODE_STRING(@"\n/* INSERT_"                                                                    \
                @"LICENSE */\n\n")

NS_ASSUME_NONNULL_BEGIN

@interface CodeWriter : NSObject

+ (void)file:(NSString *)file;
+ (void)write:(NSString *)str;
+ (void)dump;
+ (CodeWriter *)sharedInstance;
+ (void)moveIntoPlace;

@end

NS_ASSUME_NONNULL_END
