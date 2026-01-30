//
//  DebugLogging.h
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#ifndef __DEBUG_H
#define __DEBUG_H 1

#import <Foundation/Foundation.h>

#define DEBUG_LOG_BIT(X) 0x1 << (X)

typedef NS_ENUM(NSInteger, debugLogLevel) {
    LogSettings = DEBUG_LOG_BIT(0),
    LogNet = DEBUG_LOG_BIT(1),
    LogXML = DEBUG_LOG_BIT(2),
    LogParsing = DEBUG_LOG_BIT(3),
    LogTask = DEBUG_LOG_BIT(4),
    LogUI = DEBUG_LOG_BIT(5),
    LogData = DEBUG_LOG_BIT(6),
    LogTests = DEBUG_LOG_BIT(7),
    LogTestFiles = DEBUG_LOG_BIT(8),
    LogIntents = DEBUG_LOG_BIT(9),
    LogAlarms = DEBUG_LOG_BIT(10),
    LogWeb = DEBUG_LOG_BIT(11),
    LogMarkup = DEBUG_LOG_BIT(12),
    LogTipJar = DEBUG_LOG_BIT(13)
};

#import "DebugCommon.h"

#define LOG_PARSE_ERROR(error)                                                                     \
    do {                                                                                           \
        if (error) {                                                                               \
            WARNING_LOG(@"Parse error: %@\n", error.debugDescription);                             \
        }                                                                                          \
    } while (0)

#define DEBUG_CASE(x) DEBUG_LOG(@"Case    %s: %lu", #x, (unsigned long)(x))
#define DEBUG_DEFAULT(x) DEBUG_LOG(@"Default %s: %lu", #x, (unsigned long)(x))
#define NSSTR_FUNC [NSString stringWithUTF8String:__func__]

#define DEBUG_ASSERT_WARNING(C, s, ...)                                                            \
    do {                                                                                           \
        if (DEBUG_ON_FOR_FILE)                                                                     \
            if (!(C)) {                                                                            \
                NSLog(DEBUG_LOG_PREFIX "*** TEST WARNING %@",                                      \
                      DEBUG_LOG_PREFIX_VALS,                                                       \
                      [NSString stringWithFormat:(s), ##__VA_ARGS__]);                             \
            }                                                                                      \
    } while (0)

#define DEBUG_TEST_WARNING(s, ...)                                                                 \
    do {                                                                                           \
        if (DEBUG_ON_FOR_FILE) {                                                                   \
            NSLog(DEBUG_LOG_PREFIX @"*** TEST WARNING %@",                                         \
                  DEBUG_LOG_PREFIX_VALS,                                                           \
                  [NSString stringWithFormat:(s), ##__VA_ARGS__]);                                 \
        }                                                                                          \
    } while (0)
#endif // !__DEBUG_H
