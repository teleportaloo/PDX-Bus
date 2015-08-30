//
//  DepartureData.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "TriMetTypes.h"

@class XMLDepartures;

typedef enum {
	kStatusEstimated =0,
	kStatusScheduled,
	kStatusDelayed,
	kStatusCancelled
} kStatus;

@interface DepartureData : NSObject {
	NSString *			_route;
	NSString *			_fullSign;
	NSString *			_errorMessage;
	NSString *			_routeName;
	NSString *			_block;
	NSString *			_dir;
	NSString *			_locid;
	TriMetTime			_departureTime;
	TriMetTime			_scheduledTime;
	kStatus				_status;    
	bool				_detour;
	TriMetDistance		_blockPositionFeet;
	TriMetTime			_blockPositionAt;
	NSString *			_blockPositionLat;
	NSString *			_blockPositionLng;
	NSString *			_locationDesc;
	NSString *			_locationDir;
	bool				_hasBlock;
	TriMetTime			_queryTime;
	TriMetTime			_nextBus;
    NSDate              *_cacheTime;
	bool				_streetcar;
	NSMutableArray *	_trips;
	
	NSString *			_stopLat;
	NSString *			_stopLng;
	NSString *			_copyright;
    NSString *          _streetcarBlock;
    bool                _nextBusFeedInTriMetData;
    NSTimeInterval      _timeAdjustment;
}

-(id)init;
-(NSString *)formatDistance:(TriMetDistance)distance;
-(NSString *)formatLayoverTime:(TriMetTime)t;
-(TriMetTime)secondsToArrival;
-(int)minsToArrival;
-(NSString*)timeToArrival;
-(NSComparisonResult)compareUsingTime:(DepartureData*)inData;
- (bool)needToFetchStreetcarLocation;
- (void)makeTimeAdjustment:(NSTimeInterval)interval;
- (void)extrapolateFromNow;


@property (nonatomic, retain) NSString *locid;
@property (nonatomic, retain) NSString *block;
@property (nonatomic, retain) NSString *dir;
@property (nonatomic, retain) NSMutableArray *trips;
@property (nonatomic) bool hasBlock;
@property (nonatomic) TriMetTime queryTime;
@property (nonatomic) TriMetDistance blockPositionFeet;
@property (nonatomic) TriMetTime blockPositionAt;
@property (nonatomic, retain) NSString *blockPositionLat;
@property (nonatomic, retain) NSString *blockPositionLng;
@property (nonatomic, retain) NSString *errorMessage;
@property (nonatomic, retain) NSString *routeName;
@property (nonatomic, retain) NSString *route;
@property (nonatomic, retain) NSString *fullSign;
@property (nonatomic, retain) NSString *locationDesc;
@property (nonatomic, retain) NSString *locationDir;
@property (nonatomic) TriMetTime  departureTime;
@property (nonatomic) TriMetTime  scheduledTime;
@property (nonatomic) kStatus status;
@property (nonatomic) bool detour;
@property (nonatomic) bool streetcar;
@property (nonatomic) TriMetTime nextBus;
@property (nonatomic, retain) NSString *stopLat;
@property (nonatomic, retain) NSString *stopLng;
@property (nonatomic, retain) NSString *copyright;
@property (nonatomic, retain) NSDate *cacheTime;
@property (nonatomic, retain) NSString *streetcarId;
@property (nonatomic) bool nextBusFeedInTriMetData;
@property (nonatomic) NSTimeInterval timeAdjustment;

@end
