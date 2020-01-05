//
//  DepartureData.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "TriMetTypes.h"
#import <CoreLocation/CoreLocation.h>
#import "DataFactory.h"
#import "TriMetInfo.h"
#import "Detour.h"

#define kLongDateFormat          @"E, h:mm a"
#define kLongDateFormatWeekday   @"EEEE, h:mm a"

typedef enum
{
    ArrivalSoon,
    ArrivalThisWeek,
    ArrivalNextWeek
} ArrivalWindow;

@class XMLDepartures;
@class Vehicle;
@class DepartureTrip;

typedef enum {
    kStatusEstimated =0,
    kStatusScheduled,
    kStatusDelayed,
    kStatusCancelled
} kStatus;

@interface Departure : DataFactory {
    PC_VEHICLE_INFO _vehicleInfo;
}

@property (nonatomic, readonly) bool needToFetchStreetcarLocation;
@property (nonatomic, readonly) NSTimeInterval secondsToArrival;
@property (nonatomic, readonly) int minsToArrival;
@property (nonatomic, readonly, copy) NSString *timeToArrival;
@property (nonatomic, readonly, copy) NSString *descAndDir;
@property (nonatomic, readonly) const VEHICLE_INFO *vehicleInfo;
@property (nonatomic, copy)   NSString *locid;
@property (nonatomic, copy)   NSString *block;
@property (nonatomic, copy)   NSString *reason;
@property (nonatomic, strong) NSArray<NSString *> *vehicleIDs;
@property (nonatomic)         bool  fetchedAdditionalVehicles;
@property (nonatomic)         NSInteger loadPercentage;
@property (nonatomic)         bool      trackingErrorOffRoute;
@property (nonatomic)         bool      trackingError;
@property (nonatomic, copy)   NSString *dir;
@property (nonatomic, strong) NSMutableArray<DepartureTrip*> *trips;
@property (nonatomic)         bool hasBlock;
@property (nonatomic, strong) NSDate *queryTime;
@property (nonatomic) TriMetDistance blockPositionFeet;
@property (nonatomic, strong) NSDate *blockPositionAt;
@property (nonatomic, strong) CLLocation *blockPosition;
@property (nonatomic, copy)   NSString *blockPositionRouteNumber;
@property (nonatomic, copy)   NSString *blockPositionDir;
@property (nonatomic, copy)   NSString *blockPositionHeading;
@property (nonatomic, copy)   NSString *errorMessage;
@property (nonatomic, copy)   NSString *shortSign;
@property (nonatomic, copy)   NSString *route;
@property (nonatomic, copy)   NSString *fullSign;
@property (nonatomic, copy)   NSString *nextLocid;
@property (nonatomic, copy)   NSString *locationDesc;
@property (nonatomic, copy)   NSString *locationDir;
@property (nonatomic, strong) NSDate *departureTime;
@property (nonatomic, strong) NSDate *scheduledTime;
@property (nonatomic)         kStatus status;
@property (nonatomic, strong) NSMutableOrderedSet<NSNumber*> *detours;
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, Detour*> *allDetours;
@property (nonatomic)         bool dropOffOnly;
@property (nonatomic)         bool streetcar;
@property (nonatomic)         NSInteger nextBusMins;
@property (nonatomic, strong) CLLocation *stopLocation;
@property (nonatomic, copy)   NSString *copyright;
@property (nonatomic, strong) NSDate *cacheTime;
@property (nonatomic, copy)   NSString *streetcarId;
@property (nonatomic)         bool nextBusFeedInTriMetData;
@property (nonatomic) NSTimeInterval timeAdjustment;
@property (nonatomic) bool    invalidated;
@property (nonatomic) bool    detour;
@property (nonatomic) NSInteger systemWideDetours;


- (instancetype)init;
- (NSString *)formatLayoverTime:(NSTimeInterval)t;
- (NSComparisonResult)compareUsingTime:(Departure*)inData;
- (void)makeTimeAdjustment:(NSTimeInterval)interval;
- (void)extrapolateFromNow;
- (void)makeInvalid:(NSDate *)querytime;
- (void)insertLocation:(Vehicle *)data;
- (bool)notToSchedule;
- (bool)actuallyLate;
- (NSArray *)vehicleIdsForStreetcar;
- (NSDateFormatter *)dateAndTimeFormatterWithPossibleLongDateStyle:(NSString *)longDateFormat arrivalWindow:(ArrivalWindow*)arrivalWindow;

@end

