//
//  UserInfo.m
//  PDX Bus
//
//  Created by Andy Wallace on 2/23/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "UserInfo.h"
#import "DebugLogging.h"
#import "PlistMacros.h"

#define DEBUG_LEVEL_FOR_FILE LogUI

#define kStopIdNotification @"stopId"
#define kAlarmBlock @"alarmBlock"
#define kAlarmDir @"alarmDir"
#define kStopMapDescription @"stopDesc"
#define kStopMapLat @"mapLat"
#define kStopMapLng @"mapLng"
#define kCurrLocLat @"curLat"
#define kCurrLocLng @"curLng"
#define kCurrTimestamp @"curTimestamp"
#define kActionLocationDistance @"distance"
#define kActionLocationMode @"mode"
#define kActionLocationShow @"show"

@interface UserInfo ()

// Tell compiler to generate setter and getter, but setter is protected
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

// Redeclared from parent so we can access
@property(nonatomic, retain) NSMutableDictionary *mDict;

@end

@implementation UserInfo

// Tell compiler to use the existing parent's accessor
@dynamic mDict;

// Implementations of the setters and getters and helpers
PROP_NSData(Xml, @"xml", nil);
PROP_NSString(Locs, @"locs", @"");

PROP_NSString(StopId, kStopIdNotification, nil);
PROP_NSString(AlarmBlock, kAlarmBlock, @"");
PROP_NSString(AlarmDir, kAlarmDir, @"");
PROP_NSString(StopMapDesc, kStopMapDescription, nil);
PROP_double(MapLat, kStopMapLat, 0);
PROP_double(MapLng, kStopMapLng, 0);
PROP_double(CurLat, kCurrLocLat, 0);
PROP_double(CurLng, kCurrLocLng, 0);
PROP_NSString(CurTimestamp, kCurrTimestamp, @"");
PROP_NSString(Dist, kActionLocationDistance, @"");
PROP_NSString(Mode, kActionLocationMode, @"");
PROP_NSString(Show, kActionLocationShow, @"");

+ (UserInfo *)withXml:(NSData *)data locs:(NSString *)locs {
    MutableUserInfo *info = MutableUserInfo.new;
    info.valXml = data;
    info.valLocs = locs;
    return info;
}
@end

@implementation MutableUserInfo

// Tells the compiler to use the protected setters above
@dynamic valXml;
@dynamic valLocs;

@dynamic valStopId;
@dynamic valAlarmBlock;
@dynamic valAlarmDir;
@dynamic valStopMapDesc;
@dynamic valMapLat;
@dynamic valMapLng;
@dynamic valCurLat;
@dynamic valCurLng;
@dynamic valCurTimestamp;
@dynamic valDist;
@dynamic valMode;
@dynamic valShow;

- (NSMutableDictionary *)mutableDictionary {
    return self.mDict;
}

- (instancetype)init {
    return [super initMutable];
}

@end

@implementation NSDictionary (UserInfo)

- (UserInfo *)userInfo {
    return [UserInfo make:self];
}

@end

@implementation NSMutableDictionary (UserInfo)

- (MutableUserInfo *)mutableUserInfo {
    return [MutableUserInfo makeMutable:self];
}

@end
