//
//  StopNameCacheManager.h
//  PDXBusCore
//
//  Created by Andrew Wallace on 5/16/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "QueryCacheManager.h"






@interface StopNameCacheManager : QueryCacheManager

- (NSDictionary *)getStopNames:(NSArray<NSString*> *)stopIds fetchAndCache:(bool)fetchAndCache updated:(bool*)updated completion:(void (^ __nullable)(int item))completion;


+ (NSString *)getShortName:(NSArray *)data;
+ (NSString *)getLongName:(NSArray *)data;
+ (NSString *)getStopId:(NSArray *)data;

+ (NSString *)shortDirection:(NSString *)dir;
+ (instancetype)cache;

@end
