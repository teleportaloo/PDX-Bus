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


#import <Foundation/Foundation.h>
#import "HotSpot.h"
#import "ScreenConstants.h"
#import "SearchFilter.h"


@interface RailStation : NSObject <SearchFilter>

@property (nonatomic, strong) NSMutableArray<NSString *> *stopIdArray;
@property (nonatomic, strong) NSMutableArray<NSString *> *dirArray;

@property (nonatomic, strong) NSMutableArray<NSString *> *transferStopIdArray;
@property (nonatomic, strong) NSMutableArray<NSString *> *transferDirArray;
@property (nonatomic, strong) NSMutableArray<NSString *> *transferNameArray;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *transferHotSpotIndexArray;


@property (nonatomic, copy)   NSString *station;
@property (nonatomic, copy)   NSString *wikiLink;
@property (nonatomic) int index;
@property (readonly) RailLines line;
@property (readonly) RailLines line0;
@property (readonly) RailLines line1;
@property (nonatomic, readonly, copy) NSString *stringToFilter;

- (instancetype)initFromHotSpot:(HotSpot *)hotspot index:(int)index;
- (NSComparisonResult)compareUsingStation:(RailStation *)inStation;
- (void)findTransfers;

- (BOOL)isEqual:(id)other;
- (NSUInteger)hash;


+ (NSString *)nameFromHotspot:(HotSpot *)hotspot;
+ (UITableViewCell *)tableView:(UITableView *)tableView cellWithReuseIdentifier:(NSString *)identifier rowHeight:(CGFloat)height;
+ (void)populateCell:(UITableViewCell *)cell station:(NSString *)station lines:(RailLines)lines;
+ (instancetype)fromHotSpot:(HotSpot *)hotspot index:(int)index;

@end
