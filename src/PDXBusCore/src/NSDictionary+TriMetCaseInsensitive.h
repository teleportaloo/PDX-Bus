//
//  NSDictionary+TriMetCaseInsensitive.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/11/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "TriMetTypes.h"

NS_ASSUME_NONNULL_BEGIN

// We actually don't need to check for a string as this is only used for a NDictionary<NSString *, NSString *> type
// #define XML_STR_CLASS(X)        [(X) isKindOfClass:[NSString class]]
#define XML_STR_CLASS(X)        (TRUE)

#define XML_NON_NULL_STR(STR)   (XML_STR_CLASS(STR) ? (((STR) == nil ? @"?" : (STR))) : nil)

@interface NSDictionary (TriMetCaseInsensitive)

- (NSString *_Nullable)nullOrSafeStringForKey:(NSString *_Nonnull)key;
- (NSNumber *_Nullable)nullOrSafeNumForKey:(NSString *_Nonnull)key;
- (id _Nullable)objectForCaseInsensitiveKey:(NSString *)key;
- (TriMetDistance)getDistanceForKey:(NSString *_Nonnull)key;
- (NSDate *_Nullable)getDateForKey:(NSString *_Nonnull)key;
- (NSInteger)zeroOrSafeIntForKey:(NSString *_Nonnull)key;
- (NSInteger)getNSIntegerForKey:(NSString *_Nonnull)key;
- (TriMetTime)getTimeForKey:(NSString *_Nonnull)key;
- (double)getDoubleForKey:(NSString *_Nonnull)key;
- (bool)getBoolForKey:(NSString *_Nonnull)key;

@end

NS_ASSUME_NONNULL_END
