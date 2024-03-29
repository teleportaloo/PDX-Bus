//
//  XMLStreetcarLocations.h
//  PDX Bus
//
//  Created by Andrew Wallace on 3/23/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "NextBusXML.h"
#import "Departure.h"
#import "MemoryCaches.h"

@class Vehicle;

@interface XMLStreetcarLocations : NextBusXML <ClearableCache>

@property (nonatomic, strong) NSMutableDictionary<NSString *, Vehicle *> *locations;

- (instancetype)initWithRoute:(NSString *)route;
- (void)insertLocation:(Departure *)dep;
- (BOOL)getLocations;

+ (void)insertLocationsIntoXmlDeparturesArray:(NSArray *)xmlDeps forRoutes:(NSSet<NSString *> *)routes;
+ (NSSet<NSString *> *)getStreetcarRoutesInXMLDeparturesArray:(NSArray *)xmlDeps;
+ (XMLStreetcarLocations *)sharedInstanceForRoute:(NSString *)route;

@end
