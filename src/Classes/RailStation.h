//
//  RailStation.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/4/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "HotSpot.h"
#import "ScreenConstants.h"
#import "SearchFilter.h"
#import <Foundation/Foundation.h>

@interface NSValue (RouteInfo)

@property(nonatomic, readonly) PtrConstRouteInfo PtrConstRouteInfoValue;

@end

@interface RailStation : NSObject <SearchFilter>

@property(nonatomic, strong, readonly) NSArray<NSString *> *stopIdArray;
@property(nonatomic, strong, readonly) NSArray<NSString *> *dirArray;

@property(nonatomic, strong, readonly) NSArray<NSString *> *transferStopIdArray;
@property(nonatomic, strong, readonly) NSArray<NSString *> *transferDirArray;
@property(nonatomic, strong, readonly) NSArray<NSString *> *transferNameArray;
@property(nonatomic, strong, readonly)
    NSArray<NSNumber *> *transferHotSpotIndexArray;

@property(nonatomic, copy, readonly) NSString *name;
@property(nonatomic, copy, readonly) NSString *wikiLink;
@property(nonatomic, readonly) int index;
@property(nonatomic, readonly, copy) NSString *stringToFilter;

- (void)findTransfers;

- (BOOL)isEqual:(id)other;
- (NSUInteger)hash;

- (NSArray<NSValue *> *)routeInfoWithTransfers;

+ (instancetype)fromHotSpotIndex:(int)index;


@end
