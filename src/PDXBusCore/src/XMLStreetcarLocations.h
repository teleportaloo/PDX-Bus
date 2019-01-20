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
#import "DepartureData.h"
#import "MemoryCaches.h"

@class VehicleData;

@interface XMLStreetcarLocations : NextBusXML <ClearableCache> {
    TriMetTime _lastTime;
}
 

@property (nonatomic, strong) NSMutableDictionary<NSString*, VehicleData*> *locations;
@property (nonatomic, copy)   NSString *route;

- (instancetype) initWithRoute:(NSString *)route;
- (void)insertLocation:(DepartureData *)dep;
- (BOOL)getLocations;

+ (void)insertLocationsIntoDepartureArray:(NSArray *)deps forRoutes:(NSSet<NSString*> *)routes;
+ (NSSet<NSString*> *)getStreetcarRoutesInDepartureArray:(NSArray *)deps;
+ (XMLStreetcarLocations*) sharedInstanceForRoute:(NSString *)route;

@end
