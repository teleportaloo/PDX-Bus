//
//  QueryCacheManager.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/16/11.
//  Copyright (c) 2011 Teleportaloo. All rights reserved.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import <Foundation/Foundation.h>
#import "UserPrefs.h"

#define kCacheDateAndTime   0
#define kCacheData          1

@interface QueryCacheManager : NSObject
{
    NSMutableDictionary *   _cache;
    NSString *              _fullFileName;
    int                     _maxSize;
}

@property (nonatomic) int maxSize;
@property (nonatomic, retain)   NSMutableDictionary *cache;
@property (nonatomic, retain)   NSString *fullFileName;


- (id)initWithFileName:(NSString *)shortFileName;
- (void)deleteCacheFile;
+ (NSString *)getCacheKey:(NSString *)query;
- (NSArray *)getCachedQuery:(NSString *)cacheQuery;
- (void)addToCache:(NSString *)cacheQuery item:(NSData *)item write:(bool)write;
- (void)removeFromCache:(NSString *)cacheQuery;


@end
