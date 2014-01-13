//
//  TripUserRequest.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TripEndPoint.h"
#import "TriMetTypes.h"

typedef enum {
	TripMinQuickestTrip,
    TripMinFewestTransfers,
    TripMinShortestWalk
} TripMin;

typedef enum {
	TripAskForTime,
	TripDepartAfterTime,
	TripArriveBeforeTime
} TripTimeChoice;


@interface TripUserRequest : NSObject
{
	TripEndPoint	*_fromPoint;
	TripEndPoint	*_toPoint;
	TripMode		_tripMode;
	TripMin			_tripMin;
	int				_maxItineraries;
	float			_walk;
	NSDate			*_dateAndTime;
	bool			_arrivalTime;
	TripTimeChoice  _timeChoice;
    bool            _takeMeHome;
}

@property (nonatomic, retain) TripEndPoint	*fromPoint;
@property (nonatomic, retain) TripEndPoint	*toPoint;
@property (nonatomic)	      TripMode		tripMode;
@property (nonatomic)		  TripMin		tripMin;
@property (nonatomic)		  int			maxItineraries;
@property (nonatomic)		  float			walk;
@property (nonatomic)		  bool			arrivalTime;
@property (nonatomic, retain) NSDate		*dateAndTime;
@property (nonatomic)		  TripTimeChoice timeChoice;
@property (nonatomic)         bool          takeMeHome;

- (NSString *)getMode;
- (NSString *)getMin;
- (NSString *)minToString;
- (NSString *)modeToString;

- (id)initFromDict:(NSDictionary *)dict;
- (id)init;

- (NSMutableDictionary *)toDictionary;
- (bool)fromDictionary:(NSDictionary *)dict;
- (bool)equalsTripUserRequest:(TripUserRequest*)userRequest;

- (NSString *)getTimeType;

- (NSString*)getDateAndTime;
- (NSString*)tripName;
- (NSString*)shortName;
- (NSString*)optionsAccessability;
- (NSString*)optionsDisplayText;
- (void)clearGpsNames;


@end

