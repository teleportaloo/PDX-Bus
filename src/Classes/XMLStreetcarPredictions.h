//
//  XMLStreetcarPredictions.h
//  PDX Bus
//
//  Created by Andrew Wallace on 3/22/10.
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
#import "NextBusXML.h"
#import "Departure.h"


@interface XMLStreetcarPredictions : NextBusXML {
	Departure *_currentDepartureObject;
	NSString *_directionTitle;
    NSString *_stopTitle;
	NSString *_routeTitle;
	NSString *_blockFilter;
	NSString *_copyright;
	NSString *_dirFromQuery;
	
	NSDictionary *_streetcarDirections;
	NSDictionary *_streetcarShortNames;
    
    NSString *_nextBusRouteId;
}

@property (nonatomic, retain) Departure *currentDepartureObject;
@property (nonatomic, retain) NSString *directionTitle;
@property (nonatomic, retain) NSString *routeTitle;
@property (nonatomic, retain) NSString *blockFilter;
@property (nonatomic, retain) NSString *copyright;
@property (nonatomic, retain) NSString *dirFromQuery;
@property (nonatomic, retain) NSString *nextBusRouteId;
@property (nonatomic, retain) NSString *stopTitle;


@property (nonatomic, retain) NSDictionary *streetcarDirections;
@property (nonatomic, retain) NSDictionary *streetcarShortNames;

- (BOOL)getDeparturesForLocation:(NSString *)location parseError:(NSError **)error;

@end
