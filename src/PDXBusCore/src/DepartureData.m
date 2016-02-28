//
//  DepartureData.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DepartureData.h"

#import "TriMetRouteColors.h"
#import "DebugLogging.h"
#import "VehicleData.h"
#import "FormatDistance.h"

@implementation DepartureData

@synthesize hasBlock = _hasBlock;
@synthesize queryTime = _queryTime;
@synthesize blockPositionFeet = _blockPositionFeet;
@synthesize blockPositionAt = _blockPositionAt;
@synthesize blockPositionHeading = _blockPositionHeading;
@synthesize routeName = _routeName;
@synthesize errorMessage = _errorMessage;
@synthesize route = _route;
@synthesize fullSign = _fullSign;
@synthesize departureTime = _departureTime;
@synthesize status = _status;
@synthesize detour = _detour;
@synthesize locationDesc = _locationDesc;
@synthesize locationDir = _locationDir;
@synthesize trips = _trips;
@synthesize block = _block;
@synthesize dir = _dir;
@synthesize locid = _locid;
@synthesize streetcar = _streetcar;
@synthesize nextBus = _nextBus;
@synthesize copyright = _copyright;
@synthesize scheduledTime = _scheduledTime;
@synthesize cacheTime = _cacheTime;
@synthesize streetcarId = _streetcarId;
@synthesize nextBusFeedInTriMetData = _nextBusFeedInTriMetData;
@synthesize timeAdjustment = _timeAdjustment;
@synthesize blockPosition = _blockPosition;
@synthesize stopLocation  = _stopLocation;


- (void)dealloc
{
	self.route = nil;
	self.fullSign = nil;
	self.errorMessage = nil;
	self.routeName = nil;
	self.blockPosition = nil;
	self.locationDesc = nil;
	self.trips = nil;
	self.block = nil;
	self.dir = nil;
	self.locid = nil;
	self.locationDir = nil;
	self.stopLocation = nil;
	self.copyright = nil;
    self.cacheTime = nil;
    self.streetcarId = nil;
    self.blockPositionHeading = nil;
	
	[super dealloc];
	
}

- (id)init
{
	if ((self = [super init]))
	{

		self.trips = [[[NSMutableArray alloc] init] autorelease];
		
	}
	return self;
}


#pragma mark Formatting 

-(NSString *)formatLayoverTime:(TriMetTime)t
{
	NSMutableString * str = [[[NSMutableString alloc] init] autorelease];
	TriMetTime secs = TriMetToUnixTime(t) % 60;
	TriMetTime mins = t / 60000;
	
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


-(TriMetTime)secondsToArrival
{
	
	return TriMetToUnixTime(self.departureTime - self.queryTime);
}

- (int)minsToArrival
{
	return (int)(self.secondsToArrival / 60);
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
    NSTimeInterval i = -[self.cacheTime timeIntervalSinceNow];
    [self makeTimeAdjustment:i];
}

- (void)makeTimeAdjustment:(NSTimeInterval)interval
{
    self.queryTime = self.queryTime - self.timeAdjustment * 1000;
    self.timeAdjustment = interval;
    self.queryTime = self.queryTime + self.timeAdjustment * 1000;

}


-(NSComparisonResult)compareUsingTime:(DepartureData*)inData;
{
    if (self.departureTime < inData.departureTime)
    {
        return NSOrderedAscending;
    }
    else if (self.departureTime > inData.departureTime)
    {
        return NSOrderedDescending;
    }
    return NSOrderedSame;
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

- (void)makeInvalid:(TriMetTime)querytime
{
    self.queryTime          = querytime;
    [self extrapolateFromNow];
    self.blockPosition  = nil;
    self.blockPositionFeet = 0;
    self.trips = [[[NSMutableArray alloc] init] autorelease];
    self.invalidated = YES;
}


- (void)insertLocation:(VehicleData *)data
{
    self.blockPositionHeading = data.bearing;
    self.blockPosition = data.location;
    self.blockPositionAt  = data.locationTime;
   
    self.blockPositionFeet = [self.stopLocation distanceFromLocation:data.location] * kFeetInAMetre; // convert meters to feet

}





@end
