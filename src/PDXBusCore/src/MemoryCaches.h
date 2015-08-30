//
//  MemoryCaches.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/19/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>

@protocol ClearableCache <NSObject>

- (void)memoryWarning;

@end

@interface MemoryCaches : NSObject {
        NSMutableSet *_caches;
}

+ (MemoryCaches*)getSingleton;
+ (void)memoryWarning;
+ (void)addCache:(id<ClearableCache>)cache;
+ (void)removeCache:(id<ClearableCache>)cache;


@end
