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


@interface XMLStreetcarPredictions : NextBusXML {
	DepartureData *_currentDepartureObject;
	NSString *_directionTitle;
    NSString *_stopTitle;
	NSString *_routeTitle;
	NSString *_blockFilter;
	NSString *_copyright;
    
    NSString *_nextBusRouteId;
}

@property (nonatomic, retain) DepartureData *currentDepartureObject;
@property (nonatomic, retain) NSString *directionTitle;
@property (nonatomic, retain) NSString *routeTitle;
@property (nonatomic, retain) NSString *blockFilter;
@property (nonatomic, retain) NSString *copyright;
@property (nonatomic, retain) NSString *nextBusRouteId;
@property (nonatomic, retain) NSString *stopTitle;


- (BOOL)getDeparturesForLocation:(NSString *)location;

@end
