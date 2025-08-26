//
//  NSMutableDictionary+SelImpCache.m
//  PDX Bus
//
//  Created by Andy Wallace on 8/18/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogXML

#import "SelImpCache.h"
#import "DebugLogging.h"

static inline NSValue *BoxSelImpPair(SelImpPair p) {
    return [NSValue valueWithBytes:&p objCType:@encode(SelImpPair)];
}

static inline SelImpPair UnboxSelImpPair(NSValue *v) {
    SelImpPair o;
    [v getValue:&o];
    return o;
}

@implementation NSMapTable (SelImpCache)

- (NSMutableDictionary *)cacheForClass:(Class)cls {
    NSMutableDictionary *cache = [self objectForKey:cls];

    if (cache == nil) {
        cache = [NSMutableDictionary new];
        [self setObject:cache forKey:cls];
    }

    return cache;
}

- (SelImpPair)selImpForElement:(NSString *)elementName
                       selName:(SelectorNameBlock)nameBlock
                           obj:(NSObject *)obj
                         debug:(NSString *)debug {

    NSMutableDictionary *cache = [self cacheForClass:obj.class];

    return [cache selImpForElement:elementName
                           selName:nameBlock
                               obj:obj
                             debug:debug];
}

@end

@implementation NSMutableDictionary (SelImpCache)

- (SelImpPair)selImpForElement:(NSString *)elementName
                       selName:(SelectorNameBlock)nameBlock
                           obj:(NSObject *)obj
                         debug:(NSString *)debug {

    SelImpPair elSelImp = {NULL, NULL};

    NSValue *selImpValue = [self objectForKey:elementName];

    if (selImpValue == nil) {
        NSString *selName = nameBlock(elementName);
        SEL elementSel = NSSelectorFromString(selName);

        if (![obj respondsToSelector:elementSel]) {
            DEBUG_LOG(@"M %@ <- %d not %@\n", debug, (int)self.count + 1,
                      elementName);
        } else {
            elSelImp.sel = elementSel;
            elSelImp.imp = [obj methodForSelector:elementSel];
            DEBUG_LOG(@"M %@ <- %d    %@\n", debug, (int)self.count + 1,
                      elementName);
        }
        [self setObject:BoxSelImpPair(elSelImp) forKey:elementName];
    } else {
        elSelImp = UnboxSelImpPair(selImpValue);

        if (elSelImp.imp != NULL) {
            DEBUG_LOG(@"C %@ ->     %@\n", debug, elementName);
        } else {
            DEBUG_LOG(@"C %@ -> not %@\n", debug, elementName);
        }
    }

    return elSelImp;
}

@end
