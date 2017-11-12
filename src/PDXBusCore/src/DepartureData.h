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

@class XMLDepartures;
@class VehicleData;

typedef enum {
	kStatusEstimated =0,
	kStatusScheduled,
	kStatusDelayed,
	kStatusCancelled
} kStatus;

@interface DepartureData : DataFactory {
	NSString *			_route;
	NSString *			_fullSign;
	NSString *			_errorMessage;
	NSString *			_shortSign;
	NSString *			_block;
	NSString *			_dir;
	NSString *			_locid;
	TriMetTime			_departureTime;
	TriMetTime			_scheduledTime;
	kStatus				_status;    
	bool				_detour;
	TriMetDistance		_blockPositionFeet;
	TriMetTime			_blockPositionAt;
    CLLocation          *_blockPosition;
    CLLocation          *_stopLocation;
    NSString *			_blockPositionHeading;
	NSString *			_locationDesc;
	NSString *			_locationDir;
	bool				_hasBlock;
	TriMetTime			_queryTime;
	TriMetTime			_nextBus;
    NSDate              *_cacheTime;
	bool				_streetcar;
	NSMutableArray *	_trips;
	

	NSString *			_copyright;
    bool                _nextBusFeedInTriMetData;
    NSTimeInterval      _timeAdjustment;
    bool                _invalidated;
}

-(instancetype)init;
-(NSString *)formatLayoverTime:(TriMetTime)t;
@property (nonatomic, readonly) TriMetTime secondsToArrival;
@property (nonatomic, readonly) int minsToArrival;
@property (nonatomic, readonly, copy) NSString *timeToArrival;
-(NSComparisonResult)compareUsingTime:(DepartureData*)inData;
@property (nonatomic, readonly) bool needToFetchStreetcarLocation;
- (void)makeTimeAdjustment:(NSTimeInterval)interval;
- (void)extrapolateFromNow;
- (void)makeInvalid:(TriMetTime)querytime;
- (void)insertLocation:(VehicleData *)data;
@property (nonatomic, readonly, copy) NSString *descAndDir;

@property (nonatomic, copy)   NSString *locid;
@property (nonatomic, copy)   NSString *block;
@property (nonatomic, copy)   NSString *dir;
@property (nonatomic, retain) NSMutableArray *trips;
@property (nonatomic) bool hasBlock;
@property (nonatomic) TriMetTime queryTime;
@property (nonatomic) TriMetDistance blockPositionFeet;
@property (nonatomic) TriMetTime blockPositionAt;
@property (nonatomic, retain) CLLocation *blockPosition;
@property (nonatomic, copy)   NSString *blockPositionHeading;
@property (nonatomic, copy)   NSString *errorMessage;
@property (nonatomic, copy)   NSString *shortSign;
@property (nonatomic, copy)   NSString *route;
@property (nonatomic, copy)   NSString *fullSign;
@property (nonatomic, copy)   NSString *locationDesc;
@property (nonatomic, copy)   NSString *locationDir;
@property (nonatomic) TriMetTime  departureTime;
@property (nonatomic) TriMetTime  scheduledTime;
@property (nonatomic) kStatus status;
@property (nonatomic) bool detour;
@property (nonatomic) bool streetcar;
@property (nonatomic) TriMetTime nextBus;
@property (nonatomic, retain) CLLocation *stopLocation;
@property (nonatomic, copy)   NSString *copyright;
@property (nonatomic, retain) NSDate *cacheTime;
@property (nonatomic, copy)   NSString *streetcarId;
@property (nonatomic) bool nextBusFeedInTriMetData;
@property (nonatomic) NSTimeInterval timeAdjustment;
@property (nonatomic) bool invalidated;

@end
