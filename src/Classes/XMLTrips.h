//
//  XMLTrips.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/27/09.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import <Foundation/Foundation.h>
#import "TriMetXML.h"
#import "MapPinColor.h"
#import "ReturnStopId.h"
#import "LegShapeParser.h"
#import "ScreenConstants.h"

#define kNearTo @"Near "
#define kModeWalk @"Walk"
#define kModeBus  @"Bus"
#define kModeMax  @"Light Rail"
#define kAcquiredLocation @"Acquired GPS Location"



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

@protocol ReturnTripLegEndPoint;

@interface TripLegEndPoint: NSObject <MapPinColor, NSCopying>
{
	NSString *_xlat;
	NSString *_xlon;
	NSString *_xdescription;
	NSString *_xstopId;
	NSString *_displayText;	
	NSString *_mapText;
	NSString *_displayModeText;
	NSString *_displayTimeText;
	NSString *_xnumber;
	UIColor *_leftColor;
	int _index;
	id<ReturnTripLegEndPoint> _callback;
}

@property (nonatomic, retain) id<ReturnTripLegEndPoint> callback;
@property (nonatomic, retain) NSString		*xlat;
@property (nonatomic, retain) NSString		*xlon;
@property (nonatomic, retain) NSString		*xdescription;
@property (nonatomic, retain) NSString		*xstopId;
@property (nonatomic, retain) NSString		*displayText;
@property (nonatomic, retain) NSString		*mapText;
@property (nonatomic, retain) NSString		*displayModeText;
@property (nonatomic, retain) NSString		*displayTimeText;
@property (nonatomic, retain) UIColor       *leftColor;
@property (nonatomic, retain) NSString      *xnumber;
@property (nonatomic) int index;

- (NSString*)stopId;
- (MKPinAnnotationColor) getPinColor;
- (NSString *)mapStopId;
- (bool)mapTapped:(id<BackgroundTaskProgress>) progress;
- (id)copyWithZone:(NSZone *)zone;


@end

@protocol ReturnTripLegEndPoint

- (void) chosenEndpoint:(TripLegEndPoint*)endpoint;
- (NSString *)actionText;

@end

@interface TripLeg: NSObject
{
	NSString *_mode;
	NSString *_xdate;
	NSString *_xstartTime;
	NSString *_xendTime;
	NSString *_xduration;
	NSString *_xdistance;

	TripLegEndPoint *_from;
	TripLegEndPoint *_to;
	
	NSString *_xnumber;
	NSString *_xinternalNumber;
	NSString *_xname;
	NSString *_xkey;
	NSString *_xdirection;
	NSString *_xblock;
	
	LegShapeParser *_legShape;
}

@property (nonatomic, retain) NSString		*mode;
@property (nonatomic, retain) NSString		*xdate;
@property (nonatomic, retain) NSString		*xstartTime;
@property (nonatomic, retain) NSString		*xendTime;
@property (nonatomic, retain) NSString		*xduration;
@property (nonatomic, retain) NSString		*xdistance;
@property (nonatomic, retain) NSString		*xnumber;
@property (nonatomic, retain) NSString		*xinternalNumber;
@property (nonatomic, retain) NSString		*xname;
@property (nonatomic, retain) NSString		*xkey;
@property (nonatomic, retain) NSString		*xdirection;
@property (nonatomic, retain) NSString		*xblock;
@property (nonatomic, retain) TripLegEndPoint *from;
@property (nonatomic, retain) TripLegEndPoint *to;
@property (nonatomic, retain) LegShapeParser *legShape;

typedef enum {
	TripTextTypeMap,
	TripTextTypeUI,
	TripTextTypeHTML,
	TripTextTypeClip
} TripTextType;

+ (CGFloat)getTextHeight:(NSString *)text width:(CGFloat)width;
+ (void)populateCell:(UITableViewCell*)cell body:(NSString *)body mode:(NSString *)mode time:(NSString *)time leftColor:(UIColor *)col route:(NSString *)route;
- (NSString*)createFromText:(bool)first textType:(TripTextType)type;
- (NSString*)createToText:(bool)last textType:(TripTextType)type;
- (NSString *)direction:(NSString *)dir;
+ (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier rowHeight:(CGFloat)height screenWidth:(ScreenType)screenWidth;
+ (CGFloat)bodyTextWidthForScreenWidth:(ScreenType)screenWidth;
@end

@interface TripEndPoint : NSObject {
	bool _useCurrentLocation;
	NSString *_locationDesc;
	NSString *_additionalInfo;
	CLLocation *_currentLocation;
}

@property (nonatomic, retain) NSString  *locationDesc;
@property (nonatomic, retain) NSString  *additionalInfo;
@property (nonatomic, retain) CLLocation  *currentLocation;
@property (nonatomic) bool useCurrentLocation;

- (NSString *)toQuery:(NSString *)toOrFrom;

- (NSDictionary *)toDictionary;
- (bool)fromDictionary:(NSDictionary *)dict;
- (bool) equalsTripEndPoint:(TripEndPoint*)endPoint;
- (id)initFromDict:(NSDictionary *)dict;
- (NSString *)displayText;
- (NSString *)userInputDisplayText;


@end

@interface TripItinerary : NSObject {
	NSString *_xdate;
	NSString *_xstartTime;
	NSString *_xendTime;
	NSString *_xduration;
	NSString *_xdistance;
	NSString *_xnumberOfTransfers;
	NSString *_xnumberofTripLegs;
	NSString *_xwalkingTime;
	NSString *_xtransitTime;
	NSString *_xwaitingTime;
	NSMutableString *_fare;	
	NSMutableArray *_legs;
	NSMutableArray *_displayEndPoints;
	TripLegEndPoint *_startPoint;
	NSString *_xmessage;
	NSString *_travelTime;;
}

@property (nonatomic, retain) NSString		*xwaitingTime;
@property (nonatomic, retain) NSString		*xdate;
@property (nonatomic, retain) NSString		*xstartTime;
@property (nonatomic, retain) NSString		*xendTime;
@property (nonatomic, retain) NSString		*xduration;
@property (nonatomic, retain) NSString		*xdistance;
@property (nonatomic, retain) NSString		*xmessage;
@property (nonatomic, retain) NSString		*xnumberOfTransfers;
@property (nonatomic, retain) NSString		*xnumberofTripLegs;
@property (nonatomic, retain) NSString		*xwalkingTime;
@property (nonatomic, retain) NSString		*xtransitTime;
@property (nonatomic, retain) NSMutableArray *legs;
@property (nonatomic, retain) NSMutableArray *displayEndPoints;
@property (nonatomic, retain) NSMutableString *fare;
@property (nonatomic, retain) NSString *travelTime;
@property (nonatomic, retain) TripLegEndPoint *startPoint;

- (TripLeg*)getLeg:(int)item;
- (int)legCount;
- (NSString *)getTravelTime;
- (NSString *)getShortTravelTime;
- (bool)hasFare;
- (NSString *)startPointText:(TripTextType)type;


@end

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


@end


@interface XMLTrips : TriMetXML {
	TripUserRequest *_userRequest;
	NSArray			*_userFaves;
	bool			_reversed;
	
	TripItinerary   *_currentItinerary;
	TripLeg			*_currentLeg;
	
	id				_currentObject;
	NSString		*_currentTagData;
	
	NSMutableArray *_toList;
	NSMutableArray *_fromList;
	NSMutableArray *_currentList;
	
	TripLegEndPoint *_resultFrom;
	TripLegEndPoint *_resultTo;
	
	
	NSString *_xdate;
	NSString *_xtime;
	
	
	
//	NSMutableArray *_itineraries;
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

- (bool)isProp:(NSString *)element;
- (void)fetchItineraries:(NSData*)rawData;
- (XMLTrips *)createReverse;
- (XMLTrips *) createAuto;
- (void)saveTrip;
- (NSString*)shortName;
- (NSString*)longName;
- (NSString*)mediumName;
- (void)addStopsFromUserFaves:(NSArray *)userFaves;
- (id)init;

@end
