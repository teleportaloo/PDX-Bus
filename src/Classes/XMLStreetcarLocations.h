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

@interface XMLStreetcarLocations : NextBusXML <ClearableCache> {
	NSMutableDictionary *_locations;
	TriMetTime _lastTime;
    NSString *_route;
}
 

@property (nonatomic, retain) NSMutableDictionary *locations;
@property (nonatomic, retain) NSString *route;


- (BOOL)getLocations:(NSError **)error;
- (void)insertLocation:(Departure *)dep;
- (id) initWithRoute:(NSString *)route;

+ (NSSet *)getStreetcarRoutesInDepartureArray:(NSArray *)deps;
+ (void)insertLocationsIntoDepartureArray:(NSArray *)deps forRoutes:(NSSet *)routes;

+ (XMLStreetcarLocations*) getSingletonForRoute:(NSString *)route;


@end
