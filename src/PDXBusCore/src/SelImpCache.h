//
//  SelImpCache.h
//  PDX Bus
//
//  Created by Andy Wallace on 8/18/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    SEL __nullable sel;
    IMP __nullable imp;
} SelImpPair;

typedef NSString * (^SelectorNameBlock)(NSString *);

typedef NSMutableDictionary<NSString *, NSValue *> *SelImpCache;
typedef NSMapTable<Class, SelImpCache> *SelImpClassCache;

@interface NSMapTable (SelImpCache)

- (NSMutableDictionary *)cacheForClass:(Class)cls;

- (SelImpPair)selImpForElement:(NSString *)elementName
                       selName:(SelectorNameBlock)nameBlock
                           obj:(NSObject *)obj
                         debug:(NSString *)debug;

@end

@interface NSMutableDictionary (SelImpCache)

- (SelImpPair)selImpForElement:(NSString *)elementName
                       selName:(SelectorNameBlock)nameBlock
                           obj:(NSObject *)obj
                         debug:(NSString *)debug;

@end

NS_ASSUME_NONNULL_END
