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

#define DAY_BIT_SHIFT(B) (unsigned int)(0x1 << (unsigned int)(B))

enum {
    kDayNoBit = 0,
    kDaySunBit = 1,
    kDayMonBit = 2,
    kDayTueBit = 3,
    kDayWedBit = 4,
    kDayThuBit = 5,
    kDayFriBit = 6,
    kDaySatBit = 7,
    kDayInfo = 8,

    kDayNever = 0,
    kDayUnused = 1,
    kDaySun = DAY_BIT_SHIFT(kDaySunBit),
    kDayMon = DAY_BIT_SHIFT(kDayMonBit),
    kDayTue = DAY_BIT_SHIFT(kDayTueBit),
    kDayWed = DAY_BIT_SHIFT(kDayWedBit),
    kDayThu = DAY_BIT_SHIFT(kDayThuBit),
    kDayFri = DAY_BIT_SHIFT(kDayFriBit),
    kDaySat = DAY_BIT_SHIFT(kDaySatBit),
    kDayWeekend = (kDaySat | kDaySun),
    kDayWeekday = (kDayMon | kDayTue | kDayWed | kDayThu | kDayFri),
    kDayAllWeek = (kDayWeekend | kDayWeekday),
};

@interface UserParams : PlistParams

@property (readonly, nonatomic, copy) NSString *valChosenName;
@property (readonly, nonatomic, copy) NSString *valOriginalName;
@property (readonly, nonatomic, copy) NSString *valLocation;
@property (readonly, nonatomic, retain, nullable) NSMutableDictionary *valTrip;
@property (readonly, nonatomic, retain) NSDictionary *immutableTrip;
@property (readonly, nonatomic) bool mutableTrip;
@property (readonly, nonatomic, retain) NSData *valTripResults;
@property (readonly, nonatomic) int valDayOfWeek;
@property (readonly, nonatomic) bool valMorning;
@property (readonly, nonatomic, copy) NSString *valBlock;
@property (readonly, nonatomic, copy) NSString *valDir;
@property (readonly, nonatomic, copy) NSString *valVehicleId;

@property (readonly, nonatomic) int valLocateMode;
@property (readonly, nonatomic) int valLocateShow;
@property (readonly, nonatomic) int valLocateDist;

@property (readonly, nonatomic, retain) NSDictionary *valRecent;

@end

@interface MutableUserParams : UserParams

@property (nonatomic, copy) NSString *valChosenName;
@property (nonatomic, copy) NSString *valOriginalName;
@property (nonatomic, copy) NSString *valLocation;
@property (nonatomic, retain) NSMutableDictionary *valTrip;
@property (nonatomic, retain) NSData *valTripResults;
@property (nonatomic) int valDayOfWeek;
@property (nonatomic) bool valMorning;
@property (nonatomic, copy) NSString *valBlock;
@property (nonatomic, copy) NSString *valDir;
@property (nonatomic, copy) NSString *valVehicleId;

@property (nonatomic) int valLocateMode;
@property (nonatomic) int valLocateShow;
@property (nonatomic) int valLocateDist;

@property (nonatomic, retain) NSDictionary *valRecent;

- (NSMutableDictionary *)mutableDictionary;

+ (MutableUserParams *)withChosenName:(NSString *)chosenName location:(NSString *)location;

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
