//
//  XMLDepartures.h
//  TriMetTimes
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

#import "TriMetXML.h"
#import "Trip.h"
#import "StopDistance.h"
#import <MapKit/MkAnnotation.h>
#import "MapPinColor.h"
#import "DepartureTimesDataProvider.h"
#import "XMLStreetcarPredictions.h"

@class DepartureTimes;
@class Departure;


@interface XMLDepartures : TriMetXML <MapPinColor, DepartureTimesDataProvider> {
	Departure *_currentDepartureObject;
	Trip *_currentTrip;
    
	TriMetTime	_queryTime;

	NSString *_locDesc;
	NSString *_locLat;
	NSString *_locLng;
	NSString *_locid;
	NSString *_locDir;
	NSString *_blockFilter;
	NSString *_sectionTitle;
	
	NSDictionary *_streetcarPlatformMap;
	
	NSString *_streetcarRoute;
	StopDistance *_distance;
    NSData   *_streetcarData;
}

// MKAnnotation
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
- (NSString*) title; 
- (MKPinAnnotationColor) getPinColor;
- (NSString *)mapStopId;



@property (nonatomic, retain) StopDistance *distance;
@property (nonatomic, retain) NSDictionary *streetcarPlatformMap;
@property (nonatomic, retain) NSString *locDesc;
@property (nonatomic, retain) NSString *locid;
@property (nonatomic, retain) NSString *locLat;
@property (nonatomic, retain) NSString *locDir;
@property (nonatomic, retain) NSString *locLng;
@property (nonatomic, retain) NSString *streetcarRoute;
@property (nonatomic, retain) NSString *blockFilter;
@property (nonatomic, retain) NSString *sectionTitle;
@property (nonatomic) TriMetTime queryTime;
@property (nonatomic, retain) Departure *currentDepartureObject;
@property (nonatomic, retain) Trip *currentTrip;
@property (nonatomic, retain) NSData *streetcarData;


- (BOOL)getDeparturesForLocation:(NSString *)location  parseError:(NSError **)error;
- (BOOL)getDeparturesForLocation:(NSString *)location  block:(NSString*)block parseError:(NSError **)error;
- (void)addStreetcarArrivalsForLocation:(NSString *)location;
- (void)mergeStreetcarArrivals:(NSString *)platform departures:(XMLStreetcarPredictions*)streetcars;
- (void)reload;
- (double)getLat;
- (double)getLng;
+ (void)clearCache;

@end
