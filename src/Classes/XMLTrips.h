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

#import "ScreenConstants.h"
#import "TripLegEndPoint.h"
#import "Tripleg.h"
#import "TripEndPoint.h"
#import "TripUserRequest.h"
#import "TripItinerary.h"



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
+(NSArray *)distanceMapSingleton;
+(int)distanceToIndex:(float)distance;
+(float)indexToDistance:(int)index;

@end
