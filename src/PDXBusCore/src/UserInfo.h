//
//  UserInfo.h
//  PDX Bus
//
//  Created by Andy Wallace on 2/23/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "PlistParams.h"
#import "TriMetTypes.h"

NS_ASSUME_NONNULL_BEGIN

@interface UserInfo : PlistParams

@property(readonly, nonatomic, copy) NSData *valXml;
@property(readonly, nonatomic, copy) NSString *valLocs;

@property(readonly, nonatomic, copy) NSString *valStopId;
@property(readonly, nonatomic, copy) NSString *valAlarmBlock;
@property(readonly, nonatomic, copy) NSString *valAlarmDir;
@property(readonly, nonatomic, copy) NSString *valStopMapDesc;
@property(readonly, nonatomic) double valMapLat;
@property(readonly, nonatomic) double valMapLng;
@property(readonly, nonatomic) double valCurLat;
@property(readonly, nonatomic) double valCurLng;
@property(readonly, nonatomic, copy) NSString *valCurTimestamp;
@property(readonly, nonatomic, copy) NSString *valDist;
@property(readonly, nonatomic, copy) NSString *valMode;
@property(readonly, nonatomic, copy) NSString *valShow;

- (bool)existsCurLat;
- (bool)existsCurLng;

+ (UserInfo *)withXml:(NSData *)data locs:(NSString *)locs;

@end

@interface MutableUserInfo : UserInfo

@property(nonatomic, copy) NSData *valXml;
@property(nonatomic, copy) NSString *valLocs;

@property(nonatomic, copy) NSString *valStopId;
@property(nonatomic, copy) NSString *valAlarmBlock;
@property(nonatomic, copy) NSString *valAlarmDir;
@property(nonatomic, copy) NSString *valStopMapDesc;
@property(nonatomic) double valMapLat;
@property(nonatomic) double valMapLng;
@property(nonatomic) double valCurLat;
@property(nonatomic) double valCurLng;
@property(nonatomic, copy) NSString *valCurTimestamp;
@property(nonatomic, copy) NSString *valDist;
@property(nonatomic, copy) NSString *valMode;
@property(nonatomic, copy) NSString *valShow;

- (NSMutableDictionary *)mutableDictionary;

@end

@interface NSDictionary (UserInfo)
- (UserInfo *)userInfo;
@end

@interface NSMutableDictionary (UserInfo)
- (MutableUserInfo *)mutableUserInfo;
@end

NS_ASSUME_NONNULL_END
