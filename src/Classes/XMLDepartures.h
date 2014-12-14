//
//  XMLDepartures.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


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
	
	StopDistance *_distance;
    NSMutableData *_streetcarData;
    bool _firstOnly;
}

// MKAnnotation
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
- (NSString*) title; 
- (MKPinAnnotationColor) getPinColor;
- (NSString *)mapStopId;



@property (nonatomic, retain) StopDistance *distance;
@property (nonatomic, retain) NSString *locDesc;
@property (nonatomic, retain) NSString *locid;
@property (nonatomic, retain) NSString *locLat;
@property (nonatomic, retain) NSString *locDir;
@property (nonatomic, retain) NSString *locLng;
@property (nonatomic, retain) NSString *blockFilter;
@property (nonatomic, retain) NSString *sectionTitle;
@property (nonatomic)         TriMetTime queryTime;
@property (nonatomic, retain) Departure *currentDepartureObject;
@property (nonatomic, retain) Trip *currentTrip;
@property (nonatomic, retain) NSMutableData *streetcarData;
@property (nonatomic)         bool firstOnly;


- (BOOL)getDeparturesForLocation:(NSString *)location  parseError:(NSError **)error;
- (BOOL)getDeparturesForLocation:(NSString *)location  block:(NSString*)block parseError:(NSError **)error;
- (void)reload;
- (double)getLat;
- (double)getLng;
+ (void)clearCache;

@end
