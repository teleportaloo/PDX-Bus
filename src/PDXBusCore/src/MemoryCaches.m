//
//  MemoryCaches.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/19/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//

#include "DebugLogging.h"



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MemoryCaches.h"

@implementation MemoryCaches

- (instancetype)init {
	if ((self = [super init]))
	{
		_caches = [[NSMutableSet alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[_caches release];
	[super dealloc];
	
}

+ (MemoryCaches*)singleton
{
    static MemoryCaches *caches = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        caches = [[MemoryCaches alloc] init];
    });
    return caches;
}

+ (void)memoryWarning
{
    DEBUG_LOG(@"Clearing caches\n");
    MemoryCaches *caches = [MemoryCaches singleton];
    
    for (id<ClearableCache> cache in caches->_caches)
    {
        [cache memoryWarning];
    }
}

+ (void)addCache:(id<ClearableCache>)cache
{
    MemoryCaches *caches = [MemoryCaches singleton];
    
    [caches->_caches addObject:cache];
    
}

+ (void)removeCache:(id<ClearableCache>)cache
{
    MemoryCaches *caches = [MemoryCaches singleton];
    
    [caches->_caches removeObject:cache];
}

@end
