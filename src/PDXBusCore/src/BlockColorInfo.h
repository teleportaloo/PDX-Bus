//
//  BlockColorInfo.h
//  PDX Bus
//
//  Created by Andy Wallace on 2/24/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "PDXBusCore.h"
#import "PlistParams.h"

NS_ASSUME_NONNULL_BEGIN

@interface BlockColorInfo : PlistParams

@property(readonly, nonatomic) CGFloat valR;
@property(readonly, nonatomic) CGFloat valG;
@property(readonly, nonatomic) CGFloat valB;
@property(readonly, nonatomic) CGFloat valA;
@property(readonly, nonatomic) NSTimeInterval valTime;
@property(readonly, nonatomic, copy) NSString *valDesc;

@property(readonly, nonatomic, copy) UIColor *color;

@end

@interface MutableBlockColorInfo : BlockColorInfo

@property(nonatomic) CGFloat valR;
@property(nonatomic) CGFloat valG;
@property(nonatomic) CGFloat valB;
@property(nonatomic) CGFloat valA;
@property(nonatomic) NSTimeInterval valTime;
@property(nonatomic, copy) NSString *valDesc;

@property(nonatomic, copy) UIColor *color;

- (NSMutableDictionary *)mutableDictionary;

@end

@interface NSDictionary (BlockColorInfo)
- (BlockColorInfo *)blockColorInfo;
@end

@interface NSMutableDictionary (MutableBlockColorInfo)
- (MutableBlockColorInfo *)mutableBlockColorInfo;
@end

NS_ASSUME_NONNULL_END
