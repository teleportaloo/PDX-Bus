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

#define kStopNameCacheLocation                      0
#define kStopNameCacheLongDescription               1
#define kStopNameCacheShortDescription              2
#define kStopNameCacheArraySizeWithShortDescription 3




@interface StopNameCacheManager : QueryCacheManager

- (NSArray *)getStopName:(NSString *)stopId fetchAndCache:(bool)fetchAndCache updated:(bool*)updated;
+ (NSString *)shortDirection:(NSString *)dir;

@end
