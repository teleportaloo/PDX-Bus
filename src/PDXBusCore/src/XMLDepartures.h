//
//  XMLDepartures.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetXMLv2.h"
#import "DepartureTrip.h"
#import "StopDistanceData.h"
// #import <MapKit/MkAnnotation.h>
// #import "MapPinColor.h"
// #import "DepartureTimesDataProvider.h"
#import "XMLStreetcarPredictions.h"

@class DepartureTimes;
@class DepartureData;


#define DepOptionsFirstOnly    0x01
#define DepOptionsNoDetours    0x02
#define DepOptionsOneMin       0x04

#define DepOption(X) ((self.options & (X)) == (X))

@interface XMLDepartures : TriMetXMLv2<DepartureData*> 

@property (nonatomic, strong) StopDistanceData *distance;
@property (nonatomic, copy)   NSString *locDesc;
@property (nonatomic, copy)   NSString *locid;
@property (nonatomic, strong) CLLocation *loc;
@property (nonatomic, copy)   NSString *locDir;
@property (nonatomic, copy)   NSString *blockFilter;
@property (nonatomic, copy)   NSString *sectionTitle;
@property (nonatomic, strong) NSDate *queryTime;
@property (nonatomic, strong) DepartureData *currentDepartureObject;
@property (nonatomic, strong) DepartureTrip *currentTrip;
@property (nonatomic, strong) NSMutableData *streetcarData;
@property (nonatomic)         unsigned int options;
@property (nonatomic, strong) Detour *currentDetour;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, Detour*> *allDetours;
@property (nonatomic, strong) NSMutableSet<NSNumber*> *usedDetours;
@property (nonatomic, strong) NSMutableDictionary<NSString *, Route*> *allRoutes;
@property (nonatomic, strong) NSMutableOrderedSet<NSNumber *> *locDetours;
@property (nonatomic)         bool nextBusFeedInTriMetData;


- (BOOL)getDeparturesForLocation:(NSString *)location block:(NSString*)block;
- (BOOL)getDeparturesForLocation:(NSString *)location;
- (DepartureData*)departureForBlock:(NSString *)block;
- (void)startFromMultiple;
- (bool)hasError;
- (void)reload;
- (void)reparse:(NSMutableData *)data;

+ (instancetype)xmlWithOptions:(unsigned int)options;
+ (void)clearCache;

XML_START_ELEMENT(resultset);
XML_START_ELEMENT(location);
XML_START_ELEMENT(arrival);
XML_START_ELEMENT(blockposition);
XML_START_ELEMENT(trip);
XML_START_ELEMENT(layover);
XML_START_ELEMENT(trackingerror);
XML_START_ELEMENT(detour);
XML_START_ELEMENT(error);

XML_END_ELEMENT(detour);
XML_END_ELEMENT(arrival);
XML_END_ELEMENT(error);
XML_END_ELEMENT(resultset);

@end
