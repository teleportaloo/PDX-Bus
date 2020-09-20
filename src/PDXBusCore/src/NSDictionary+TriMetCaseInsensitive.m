//
//  NSDictionary+TriMetCaseInsensitive.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/11/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "NSDictionary+TriMetCaseInsensitive.h"
#import <objc/runtime.h>

NSString const *caseKey = @"pdxbus";

// This now assumes this is a dictionionary of strings - as this is the type passed in.
// We don't have to check it any more!

// Actually XML is case senstive.  Out of an abundence of caution we also do a case-insensative search when not found.
// #define OBJ_FOR_KEY(D, K) D[K]
#define OBJ_FOR_KEY(D, K) [D objectForCaseInsensitiveKey:key]

@implementation NSDictionary (TriMetCaseInsensitive)

// #define ATR_DEBUG_LOG DEBUG_LOG
#define ATR_DEBUG_LOG(format, args ...)

- (id)objectForCaseInsensitiveKey:(NSString *)key {
    // Most cases will be a match and this is a hash based search so very
    // fast, so only do the simplistic case insensitive search if we didn't
    // find it.
    
    NSObject *result = self[key];
    
    if (result == nil) {
        NSDictionary *associatedCaseInsensativeDict = (NSDictionary *)objc_getAssociatedObject(self, &caseKey);
        
        if (associatedCaseInsensativeDict == nil) {
            NSMutableDictionary *mutableCaseInsensativeDict = [NSMutableDictionary dictionary];
        
            [self enumerateKeysAndObjectsUsingBlock: ^void (NSString *dictionaryKey, NSString *val, BOOL *stop)
             {
                mutableCaseInsensativeDict[dictionaryKey.lowercaseString] = val;
            }];
        
            objc_setAssociatedObject(self, &caseKey, mutableCaseInsensativeDict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            associatedCaseInsensativeDict = mutableCaseInsensativeDict;
            ATR_DEBUG_LOG(@"New    case-insensative dictionary %p %@", associatedCaseInsensativeDict, key);
        }
        else
        {
            ATR_DEBUG_LOG(@"Reused case-insensative dictionary %p %@", associatedCaseInsensativeDict, key);
        }
        return associatedCaseInsensativeDict[key.lowercaseString];
    }
    else
    {
        ATR_DEBUG_LOG(@"Use    case-sensative   dictionary %p %@", self, key);
    }
    
    return result;
}

- (NSString *)nullOrSafeStringForKey:(NSString *)key {
    NSString *val = OBJ_FOR_KEY(self, key);
    
    if (val == nil || !XML_STR_CLASS(val)) {
        return nil;
    }
    
    if (val.length == 0) {
        return nil;
    }
    
    return val;
}

- (NSNumber *)nullOrSafeNumForKey:(NSString *)key {
    NSString *val = OBJ_FOR_KEY(self, key);
    
    if (val == nil || !XML_STR_CLASS(val)) {
        return nil;
    }
    
    return @(val.integerValue);
}

- (NSInteger)zeroOrSafeIntForKey:(NSString *)key {
    NSString *val = OBJ_FOR_KEY(self, key);
    
    if (val == nil || !XML_STR_CLASS(val)) {
        return 0;
    }
    
    return [val integerValue];
}

- (TriMetTime)getTimeForKey:(NSString *)key {
    NSString *val = OBJ_FOR_KEY(self, key);
    
    return (TriMetTime)XML_NON_NULL_STR(val).longLongValue;
}

- (NSDate *)getDateForKey:(NSString *)key {
    NSString *val = OBJ_FOR_KEY(self, key);
    
    if (val == nil || !XML_STR_CLASS(val) || val.length == 0 || val.integerValue == 0) {
        return nil;
    }
    
    return TriMetToNSDate((TriMetTime)val.longLongValue);
}

- (NSInteger)getNSIntegerForKey:(NSString *)key {
    NSString *val = OBJ_FOR_KEY(self, key);
    
    return XML_NON_NULL_STR(val).integerValue;
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
    NSString *val = OBJ_FOR_KEY(self, key);
    
    return ([XML_NON_NULL_STR(val) compare:@"true" options:NSCaseInsensitiveSearch] == NSOrderedSame);
}

@end
