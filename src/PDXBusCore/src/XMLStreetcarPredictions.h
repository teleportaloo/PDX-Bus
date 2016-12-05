//
//  XMLStreetcarPredictions.h
//  PDX Bus
//
//  Created by Andrew Wallace on 3/22/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "NextBusXML.h"
#import "DepartureData.h"


@interface XMLStreetcarPredictions : NextBusXML<DepartureData*> {
	DepartureData *_currentDepartureObject;
	NSString *_directionTitle;
    NSString *_stopTitle;
	NSString *_routeTitle;
	NSString *_blockFilter;
	NSString *_copyright;
    
    NSString *_nextBusRouteId;
}

@property (nonatomic, retain) DepartureData *currentDepartureObject;
@property (nonatomic, copy)   NSString *directionTitle;
@property (nonatomic, copy)   NSString *routeTitle;
@property (nonatomic, copy)   NSString *blockFilter;
@property (nonatomic, copy)   NSString *copyright;
@property (nonatomic, copy)   NSString *nextBusRouteId;
@property (nonatomic, copy)   NSString *stopTitle;


- (BOOL)getDeparturesForLocation:(NSString *)location;

@end
