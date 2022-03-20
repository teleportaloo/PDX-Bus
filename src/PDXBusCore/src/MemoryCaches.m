//
//  MemoryCaches.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/19/14.
//  Copyright (c) 2014 Andrew Wallace
//




/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogDataManagement

#import "DebugLogging.h"
#import "MemoryCaches.h"

@interface MemoryCaches () {
    NSHashTable<id<ClearableCache>> *_caches;
}

@end

@implementation MemoryCaches

- (instancetype)init {
    if ((self = [super init])) {
        _caches = [NSHashTable weakObjectsHashTable];
    }
    
    return self;
}

+ (MemoryCaches *)sharedInstance {
    static MemoryCaches *caches = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        caches = [[MemoryCaches alloc] init];
    });
    return caches;
}

+ (void)memoryWarning {
    DEBUG_LOG(@"Clearing caches\n");
    MemoryCaches *caches = [MemoryCaches sharedInstance];
    
    for (id<ClearableCache> cache in caches->_caches) {
        if (cache !=nil) {
            [cache memoryWarning];
        }
    }
}

+ (void)addCache:(id<ClearableCache>)cache {
    [[MemoryCaches sharedInstance]->_caches addObject:cache];
}

+ (void)removeCache:(id<ClearableCache>)cache {
    [[MemoryCaches sharedInstance]->_caches removeObject:cache];
}

@end
