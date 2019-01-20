//
//  DepartureData.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DepartureData.h"

#import "TriMetInfo.h"
#import "DebugLogging.h"
#import "VehicleData.h"
#import "FormatDistance.h"

@implementation DepartureData


- (instancetype)init
{
    if ((self = [super init]))
    {
        self.trips = [NSMutableArray array];
        self.detours = [NSMutableOrderedSet orderedSet];
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    DepartureData *new = [[[self class] allocWithZone:zone] init];
    
#define COPY(X) new.X = self.X;
    
    COPY(route);
    COPY(fullSign);
    COPY(errorMessage);
    COPY(shortSign);
    COPY(block);
    COPY(dir);
    COPY(locid);
    COPY(departureTime);
    COPY(scheduledTime);
    COPY(status);
    COPY(detours);
    COPY(allDetours);
    COPY(dropOffOnly);
    COPY(reason);
    COPY(vehicleIDs);
    COPY(fetchedAdditionalVehicles);
    COPY(loadPercentage);
    COPY(blockPositionFeet);
    COPY(blockPositionRouteNumber);
    COPY(blockPositionDir);
    COPY(blockPositionAt);
    COPY(blockPosition);
    COPY(stopLocation);
    COPY(blockPositionHeading);
    COPY(locationDesc);
    COPY(locationDir);
    COPY(hasBlock);
    COPY(queryTime);
    COPY(nextBusMins);
    COPY(cacheTime);
    COPY(streetcar);
    new.trips           = [self.trips copyWithZone:zone];
    COPY(copyright);
    COPY(nextBusFeedInTriMetData);
    COPY(timeAdjustment);
    COPY(invalidated);
    COPY(nextLocid);
    COPY(offRoute);
    COPY(detour);
    
    return new;
}

    
    

#pragma mark Formatting 

-(NSString *)formatLayoverTime:(NSTimeInterval)t
{
    NSMutableString * str = [NSMutableString string];
    TriMetTime secs = ((NSInteger)t) % 60;
    TriMetTime mins = SecsToMins(t);
    
    if (mins == 1)
    {
        [str appendString:NSLocalizedString(@" 1 min", @"how long a bus layover will be")];
    }
    
    if (mins > 1)
    {
        [str appendFormat:NSLocalizedString(@" %lld mins", @"how long a bus layover will be"), mins ];
    }
    
    if (secs > 0)
    {
        [str appendFormat:NSLocalizedString(@" %02lld secs", @"how long a bus layover will be"), secs ];
    }
    
    return str;
    
}

- (const VEHICLE_INFO *)vehicleInfo
{
    if (_vehicleInfo == nil && self.vehicleIDs!=nil && self.vehicleIDs.count > 0)
    {
        _vehicleInfo = [TriMetInfo vehicleInfo:self.vehicleIDs[0].integerValue];
    }
    
    if (_vehicleInfo == nil && self.status == kStatusScheduled)
    {
        static VEHICLE_INFO unknown;
        unknown.first_used = @"";
        unknown.manufacturer = @"Unknown";
        unknown.max = 0;
        unknown.min = 0;
        unknown.check_for_multiple = NO;
        unknown.model = @"";
        unknown.type = @"";
        _vehicleInfo = &unknown;
    }
    else if (_vehicleInfo == nil)
    {
        static VEHICLE_INFO unknown;
        unknown.first_used = @"";
        unknown.manufacturer = @"Unknown";
        unknown.max = 0;
        unknown.min = 0;
        unknown.check_for_multiple = YES;
        unknown.model = @"";
        unknown.type = @"";
        _vehicleInfo = &unknown;
    }
    
    return _vehicleInfo;
}

-(NSTimeInterval)secondsToArrival
{
    return [self.departureTime timeIntervalSinceDate:self.queryTime];
}

- (int)minsToArrival
{
    return (int)SecsToMins(self.secondsToArrival);
}

-(NSString*)timeToArrival
{
    int mins = [self minsToArrival];
    
    if (mins < 0 || self.invalidated)
    {
        return @"-";
    }
    else if (mins == 0)
    {
        return @"Due";
    }
    // else if (mins < 60)
    {
        return [NSString stringWithFormat:@"%d", mins];
    }
    
    // return [NSString stringWithFormat:@"%d:%02d", mins / 60, mins % 60];
}

- (void)extrapolateFromNow
{
    NSTimeInterval i = -self.cacheTime.timeIntervalSinceNow;
    DEBUG_LOGLU(i);
    [self makeTimeAdjustment:i];
    
    DEBUG_LOGL(self.secondsToArrival);
    
}

- (void)makeTimeAdjustment:(NSTimeInterval)interval
{
    self.queryTime = [self.queryTime dateByAddingTimeInterval:-self.timeAdjustment];
    self.timeAdjustment = interval;
    self.queryTime = [self.queryTime dateByAddingTimeInterval:self.timeAdjustment];
}


-(NSComparisonResult)compareUsingTime:(DepartureData*)inData;
{
    return [self.departureTime compare:inData.departureTime];
}

- (bool)notToSchedule
{
    return (self.status != kStatusScheduled && self.scheduledTime != nil &&  SecsToMins([self.scheduledTime timeIntervalSince1970]) !=  SecsToMins([self.departureTime timeIntervalSince1970]));
}

- (bool)actuallyLate
{
    return (self.status != kStatusScheduled
            && self.scheduledTime != nil
            && SecsToMins([self.scheduledTime timeIntervalSince1970]) !=  SecsToMins([self.departureTime timeIntervalSince1970])
            && [self.scheduledTime timeIntervalSinceDate:self.queryTime] < 0);
}

- (NSString *)descAndDir
{
    if (self.locationDir != nil && self.locationDir.length != 0)
    {
        return [NSString stringWithFormat:@"%@ (%@)", self.locationDesc, self.locationDir];
    }
    
    return  self.locationDesc;
}


- (bool)needToFetchStreetcarLocation
{
    return (self.streetcar && self.nextBusFeedInTriMetData &&  self.status == kStatusEstimated && self.blockPosition == nil);
}

- (void)makeInvalid:(NSDate *)querytime
{
    self.queryTime = querytime;
    [self extrapolateFromNow];
    self.blockPosition  = nil;
    self.blockPositionFeet = 0;
    self.trips = [NSMutableArray array];
    self.invalidated = YES;
}


- (void)insertLocation:(VehicleData *)data
{
    self.blockPositionHeading = data.bearing;
    self.blockPosition = data.location;
    self.blockPositionAt  = data.locationTime;
    self.blockPositionRouteNumber = data.routeNumber;
    self.blockPositionDir = data.direction;
   
    self.blockPositionFeet = [self.stopLocation distanceFromLocation:data.location] * kFeetInAMetre; // convert meters to feet

}


- (NSArray *)vehicleIdsForStreetcar
{
    if (self.streetcarId)
    {
        NSString *vehicleId = [TriMetInfo vehicleIdFromStreetcarId:self.streetcarId];
        
        if (vehicleId)
        {
            return @[vehicleId];
        }
    }
    return nil;
}


- (NSDateFormatter *)dateAndTimeFormatterWithPossibleLongDateStyle:(NSString *)longDateFormat arrivalWindow:(ArrivalWindow*)arrivalWindow
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = kCFDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    
    // If date is tomorrow and more than 12 hours away then put the full date
    
    NSTimeInterval timeToArrival = [self.departureTime timeIntervalSinceDate:[NSDate date]];

    if (([[dateFormatter stringFromDate:self.departureTime] isEqualToString:[dateFormatter stringFromDate:[NSDate date]]])
        || (timeToArrival < 11 * 60 * 60)
        || self.status == kStatusEstimated)
    {
        dateFormatter.dateStyle = NSDateFormatterNoStyle;
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        
        if (arrivalWindow)
        {
            *arrivalWindow = ArrivalSoon;
        }
    }
    else if (timeToArrival < 6 * 24 * 60 * 60)
    {
        dateFormatter.dateFormat = longDateFormat;
        
        if (arrivalWindow)
        {
            *arrivalWindow = ArrivalThisWeek;
        }
    }
    else
    {
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        
        if (arrivalWindow)
        {
            *arrivalWindow = ArrivalNextWeek;
        }
    }
                                
    return dateFormatter;
    
}


@end
