//
//  UserParams.m
//  PDX Bus
//
//  Created by Andy Wallace on 2/22/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "UserParams.h"
#import "DebugLogging.h"
#import "PlistMacros.h"
#define DEBUG_LEVEL_FOR_FILE LogData

#define kUserFavesChosenName @"ChosenName"
#define kUserFavesOriginalName @"OriginalName"
#define kUserFavesLocation @"Location"
#define kUserFavesTrip @"Trip"
#define kUserFavesTripResults @"TripResults"
#define kUserFavesDayOfWeek @"DayOfWeek"
#define kUserFavesMorning @"AM"
#define kUserFavesBlock @"Block"
#define kUserFavesDir @"Dir"
#define kVehicleId @"vehicleId"

#define kLocateMode @"mode"
#define kLocateDist @"dist"
#define kLocateShow @"show"

@interface UserParams ()

// Tell compiler to generate setter and getter, but setter is protected
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

// Redeclared from parent so we can access
@property(nonatomic, retain) NSMutableDictionary *mDict;

@end

@implementation UserParams

// Tell compiler to use the existing parent's accessor
@dynamic mDict;

// Implementations of the setters and getters
PROP_NSString(ChosenName, kUserFavesChosenName, @"");
PROP_NSString(OriginalName, kUserFavesOriginalName, @"");
PROP_NSString(Location, kUserFavesLocation, nil);
PROP_NSMutableDictionary(Trip, kUserFavesTrip, nil);
PROP_NSData(TripResults, kUserFavesTripResults, nil);
PROP_int(DayOfWeek, kUserFavesDayOfWeek, kDayNever);
PROP_bool(Morning, kUserFavesMorning, true);
PROP_NSString(Block, kUserFavesBlock, nil);
PROP_NSString(Dir, kUserFavesDir, @"");
PROP_NSString(VehicleId, kVehicleId, @"");
PROP_int(LocateMode, kLocateMode, 0);
PROP_int(LocateShow, kLocateShow, 0);
PROP_int(LocateDist, kLocateDist, 0);
PROP_NSDictionary(Recent, @"recent", nil);

@end

@implementation MutableUserParams

// Tells the compiler to use the protected setters above
@dynamic valChosenName;
@dynamic valOriginalName;
@dynamic valLocation;
@dynamic valTrip;
@dynamic valTripResults;
@dynamic valDayOfWeek;
@dynamic valMorning;
@dynamic valBlock;
@dynamic valDir;
@dynamic valVehicleId;
@dynamic valLocateMode;
@dynamic valLocateShow;
@dynamic valLocateDist;
@dynamic valRecent;

+ (MutableUserParams *)withChosenName:(NSString *)chosenName
                             location:(NSString *)location {
    MutableUserParams *params = MutableUserParams.new;
    params.valChosenName = chosenName;
    params.valLocation = location;
    return params;
    ;
}

+ (MutableUserParams *)withChosenName:(NSString *)chosenName
                                 trip:(NSMutableDictionary *)trip
                          tripResults:(NSData *)tripResults {

    MutableUserParams *params = MutableUserParams.new;
    params.valChosenName = chosenName;
    params.valTrip = trip;
    params.valTripResults = tripResults;
    return params;
    ;
}

- (NSMutableDictionary *)mutableDictionary {
    return self.mDict;
}

- (instancetype)init {
    return [super initMutable];
}

@end

@implementation NSDictionary (UserParams)

- (UserParams *)userParams {
    return [UserParams make:self];
}

@end

@implementation NSMutableDictionary (UserParams)

- (MutableUserParams *)mutableUserParams {
    return [MutableUserParams makeMutable:self];
}

@end
