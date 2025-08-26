//
//  StopNameCacheManager.h
//  PDXBusCore
//
//  Created by Andrew Wallace on 5/16/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "QueryCacheManager.h"

@interface StopNameCacheManager : QueryCacheManager

- (NSDictionary *_Nonnull)getStopNames:(NSArray<NSString *> *_Nonnull)stopIds
                         fetchAndCache:(bool)fetchAndCache
                               updated:(bool *_Nullable)updated
                            completion:(void (^__nullable)(int item))completion;

+ (NSString *_Nullable)getShortName:(NSArray *_Nullable)data;
+ (NSString *_Nullable)getLongName:(NSArray *_Nullable)data;
+ (NSString *_Nullable)getStopId:(NSArray *_Nullable)data;
+ (NSString *_Nonnull)shortDirection:(NSString *_Nullable)dir;
+ (instancetype _Nonnull)cache;

@end
