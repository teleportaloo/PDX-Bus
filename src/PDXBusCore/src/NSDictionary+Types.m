//
//  NSDictionary+Types.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/11/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DebugLogging.h"
#import "NSDictionary+Types.h"
#import "TaskDispatch.h"
#import <objc/runtime.h>

#define DEBUG_LEVEL_FOR_FILE LogXML

NSString const *caseKey = @"pdxbus";

// This now assumes this is a dictionionary of strings - as this is the type
// passed in. We don't have to check it any more!

#define OBJ_FOR_KEY(D, K) D[key]

@implementation NSDictionary (Types)

// #define ATR_DEBUG_LOG DEBUG_LOG
#define ATR_DEBUG_LOG(format, args...)

- (NSString *)nullOrStringForKey:(NSString *)key {
    NSString *val = OBJ_FOR_KEY(self, key);

    if (val == nil || !XML_STR_CLASS(val)) {
        return nil;
    }

    if (val.length == 0) {
        return nil;
    }

    return val;
}

- (NSString *)zeroLenOrStringForKey:(NSString *)key {
    NSString *val = [self nullOrStringForKey:key];

    if (val == nil) {
        return @"";
    }

    return val;
}

- (NSNumber *)nullOrNumForKey:(NSString *)key {
    NSString *val = OBJ_FOR_KEY(self, key);

    if (val == nil || !XML_STR_CLASS(val)) {
        return nil;
    }

    return @(val.integerValue);
}

- (TriMetTime)getTimeForKey:(NSString *)key {
    NSString *val = OBJ_FOR_KEY(self, key);

    return (TriMetTime)XML_NON_NULL_STR(val).longLongValue;
}

- (NSDate *)getDateForKey:(NSString *)key {
    NSString *val = OBJ_FOR_KEY(self, key);

    if (val == nil || !XML_STR_CLASS(val) || val.length == 0 ||
        val.integerValue == 0) {
        return nil;
    }

    return TriMetToNSDate((TriMetTime)val.longLongValue);
}

- (NSInteger)missingOrIntForKey:(NSString *_Nonnull)key
                        missing:(NSInteger)missing {
    NSString *val = OBJ_FOR_KEY(self, key);

    if (val == nil) {
        return missing;
    }

    return val.integerValue;
}

- (TriMetDistance)getDistanceForKey:(NSString *)key {
    NSString *val = OBJ_FOR_KEY(self, key);

    return XML_NON_NULL_STR(val).longLongValue;
}

- (double)getDoubleForKey:(NSString *)key {
    NSString *val = OBJ_FOR_KEY(self, key);

    return XML_NON_NULL_STR(val).doubleValue;
}

- (bool)getBoolForKey:(NSString *)key {
    static NSDictionary<NSString *, NSNumber *> *bools;

    DoOnce((^{
      bools = @{
          @"true" : @(true),
          @"false" : @(false),
          @"yes" : @(true),
          @"no" : @(false),
          @"1" : @(true),
          @"0" : @(false),
          @"" : @(false)
      };
    }));

    NSString *val = OBJ_FOR_KEY(self, key);

    if (val) {

        NSNumber *result = bools[val.lowercaseString];

        if (result != nil) {
            return result.boolValue;
        }

        WARNING_LOG(@"XML: Unexpected bool %@", val);
    }

    return false;
}

@end
