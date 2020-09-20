//
//  KMLRoutes.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/4/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetXML.h"
#import "KMLPlacemark.h"

#define kKmlNoRouteNumber     @"None"

#define kKmlFirstDirection    @"0"
#define kKmlOptionalDirection @"1"

#define kKmlkey(R, D) [R stringByAppendingString:D]

@class ShapeRoutePath;

@interface KMLRoutes : TriMetXML<NSArray *>

@property (weak, nonatomic, readonly) NSEnumerator<NSString *> *keyEnumerator;


- (void)fetchForced:(bool)always;
- (void)fetchInBackground:(bool)always;
- (NSString *)downloadProgress;
- (void)cancelBackgroundFetch;
- (ShapeRoutePath *)lineCoordsForKey:(NSString *)key;
- (ShapeRoutePath *)lineCoordsForRoute:(NSString *)route direction:(NSString *)dir;
- (bool)cached;
- (int)cacheAgeInDays;
- (NSDate *)cacheDate;
- (int)daysToAutoload;
- (NSUInteger)sizeInBytes;

+ (void)initCaches;
+ (void)deleteCacheFile;

@end
