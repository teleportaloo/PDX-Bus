//
//  XMLTrips.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/27/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "TriMetXML.h"
#import "MapPinColor.h"
#import "ReturnStopId.h"

#import "ScreenConstants.h"
#import "TripLegEndPoint.h"
#import "TripLeg.h"
#import "TripEndPoint.h"
#import "TripUserRequest.h"
#import "TripItinerary.h"



@interface XMLTrips : TriMetXML {
	TripUserRequest *   _userRequest;
	NSArray	*           _userFaves;
	bool                _reversed;
	TripItinerary *     _currentItinerary;
	TripLeg	*           _currentLeg;
	id                  _currentObject;
	NSString *          _currentTagData;
	NSMutableArray *    _toList;
	NSMutableArray *    _fromList;
	NSMutableArray *    _currentList;
	TripLegEndPoint *   _resultFrom;
	TripLegEndPoint *   _resultTo;
	NSString *          _xdate;
	NSString *          _xtime;
    NSDictionary <NSString *, NSValue *> *_selsForProps;
}

@property (nonatomic, retain) TripUserRequest *userRequest;
@property (nonatomic)		  bool reversed;
@property (nonatomic, retain) NSArray *userFaves;
@property (nonatomic, retain) TripLegEndPoint *resultFrom;
@property (nonatomic, retain) TripLegEndPoint *resultTo;

// @property (nonatomic, retain) NSString      **currentProperty;
@property (nonatomic, retain) TripItinerary *currentItinerary;
@property (nonatomic, retain) TripLeg		*currentLeg;
// @property (nonatomic, retain) NSMutableArray *itineraries;
@property (nonatomic, retain) id			currentObject;
@property (nonatomic, retain) NSString		*currentTagData;
@property (nonatomic, retain) NSMutableArray *toList;
@property (nonatomic, retain) NSMutableArray *fromList;
@property (nonatomic, retain) NSMutableArray *currentList;
@property (nonatomic, retain) NSString       *xdate;
@property (nonatomic, retain) NSString		 *xtime;
@property (nonatomic, retain) NSDictionary <NSString *, NSValue *> *selsForProps;


- (SEL)selForProp:(NSString *)element;
- (void)fetchItineraries:(NSData*)rawData;
- (XMLTrips *)createReverse;
- (XMLTrips *)createAuto;
- (void)saveTrip;
- (void)resetCurrentLocation;
@property (nonatomic, readonly, copy) NSString *shortName;
@property (nonatomic, readonly, copy) NSString *longName;
@property (nonatomic, readonly, copy) NSString *mediumName;
- (void)addStopsFromUserFaves:(NSArray *)userFaves;
- (instancetype)init;
+(NSArray *)distanceMapSingleton;
+(int)distanceToIndex:(float)distance;
+(float)indexToDistance:(int)index;

@end
