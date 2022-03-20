//
//  XMLDepartures.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetXMLv2.h"
#import "DepartureTrip.h"
#import "StopDistance.h"
#import "XMLStreetcarPredictions.h"
#import "TriMetXMLSelectors.h"
#import "DetourSorter.h"

@class DepartureTimes;
@class Departure;

#define DepOptionsFirstOnly    0x01
#define DepOptionsNoDetours    0x02
#define DepOptionsOneMin       0x04

#define DepOption(X) ((self.options & (X)) == (X))



@interface XMLDepartures : TriMetXMLv2<Departure*> 

@property (nonatomic, strong) StopDistance *distance;
@property (nonatomic, copy)   NSString *locDesc;
@property (nonatomic, copy)   NSString *stopId;
@property (nonatomic, strong) CLLocation *loc;
@property (nonatomic, copy)   NSString *locDir;
@property (nonatomic, copy)   NSString *blockFilter;
@property (nonatomic, copy)   NSString *sectionTitle;
@property (nonatomic, strong) NSDate *queryTime;
@property (nonatomic, strong) Detour *currentDetour;
@property (nonatomic, strong) DetourSorter *detourSorter;
@property (atomic, strong)    AllTriMetRoutes *allRoutes;
@property (nonatomic)         bool nextBusFeedInTriMetData;

- (BOOL)getDeparturesForStopId:(NSString *)stopId block:(NSString*)block;
- (Departure * _Nullable)getFirstDepartureForDirection:(NSString * _Nullable)dir;
- (BOOL)getDeparturesForStopId:(NSString *)StopId;
- (Departure*)departureForBlock:(NSString *)block dir:(NSString *)dir;
- (void)startFromMultiple;
- (bool)hasError;
- (void)reload;
- (void)reparse:(NSMutableData *)data;

+ (instancetype)xmlWithOptions:(unsigned int)options;
+ (void)clearCache;
+ (NSString *)fixLocationForSpeaking:(NSString *)loc;
+ (instancetype)xmlWithOneTimeDelegate:(id<TriMetXMLDelegate> _Nonnull)delegate sharedDetours:(AllTriMetDetours *) allDetours sharedRoutes:(AllTriMetRoutes *) allRoutes;

XML_START_ELEMENT(resultSet);
XML_START_ELEMENT(location);
XML_START_ELEMENT(arrival);
XML_START_ELEMENT(blockPosition);
XML_START_ELEMENT(trip);
XML_START_ELEMENT(layover);
XML_START_ELEMENT(trackingError);
XML_START_ELEMENT(detour);
XML_START_ELEMENT(error);

XML_END_ELEMENT(detour);
XML_END_ELEMENT(arrival);
XML_END_ELEMENT(error);
XML_END_ELEMENT(resultSet);

@end
