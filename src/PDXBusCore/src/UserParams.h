//
//  UserParams.h
//  PDX Bus
//
//  Created by Andy Wallace on 2/22/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "PlistParams.h"

NS_ASSUME_NONNULL_BEGIN

#define kDayNever 0
#define kDaySun (0x1 << 1)
#define kDayMon (0x1 << 2)
#define kDayTue (0x1 << 3)
#define kDayWed (0x1 << 4)
#define kDayThu (0x1 << 5)
#define kDayFri (0x1 << 6)
#define kDaySat (0x1 << 7)
#define kDayWeekend (kDaySat | kDaySun)
#define kDayWeekday (kDayMon | kDayTue | kDayWed | kDayThu | kDayFri)
#define kDayAllWeek (kDayWeekend | kDayWeekday)

@interface UserParams : PlistParams

@property(readonly, nonatomic, copy) NSString *valChosenName;
@property(readonly, nonatomic, copy) NSString *valOriginalName;
@property(readonly, nonatomic, copy) NSString *valLocation;
@property(readonly, nonatomic, retain) NSMutableDictionary *valTrip;
@property(readonly, nonatomic, retain) NSDictionary *immutableTrip;
@property(readonly, nonatomic) bool mutableTrip;
@property(readonly, nonatomic, retain) NSData *valTripResults;
@property(readonly, nonatomic) int valDayOfWeek;
@property(readonly, nonatomic) bool valMorning;
@property(readonly, nonatomic, copy) NSString *valBlock;
@property(readonly, nonatomic, copy) NSString *valDir;
@property(readonly, nonatomic, copy) NSString *valVehicleId;

@property(readonly, nonatomic) int valLocateMode;
@property(readonly, nonatomic) int valLocateShow;
@property(readonly, nonatomic) int valLocateDist;

@property(readonly, nonatomic, retain) NSDictionary *valRecent;

@end

@interface MutableUserParams : UserParams

@property(nonatomic, copy) NSString *valChosenName;
@property(nonatomic, copy) NSString *valOriginalName;
@property(nonatomic, copy) NSString *valLocation;
@property(nonatomic, retain) NSMutableDictionary *valTrip;
@property(nonatomic, retain) NSData *valTripResults;
@property(nonatomic) int valDayOfWeek;
@property(nonatomic) bool valMorning;
@property(nonatomic, copy) NSString *valBlock;
@property(nonatomic, copy) NSString *valDir;
@property(nonatomic, copy) NSString *valVehicleId;

@property(nonatomic) int valLocateMode;
@property(nonatomic) int valLocateShow;
@property(nonatomic) int valLocateDist;

@property(nonatomic, retain) NSDictionary *valRecent;

- (NSMutableDictionary *)mutableDictionary;

+ (MutableUserParams *)withChosenName:(NSString *)chosenName
                             location:(NSString *)location;

+ (MutableUserParams *)withChosenName:(NSString *)chosenName
                                 trip:(NSMutableDictionary *)trip
                          tripResults:(NSData *)tripResults;

@end

@interface NSDictionary (UserParams)
- (UserParams *)userParams;
@end

@interface NSMutableDictionary (UserParams)
- (MutableUserParams *)mutableUserParams;
@end

NS_ASSUME_NONNULL_END
