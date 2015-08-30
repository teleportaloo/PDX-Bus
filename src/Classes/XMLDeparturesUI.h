//
//  XMLDeparturesUI.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLDepartures.h"
#import <MapKit/MkAnnotation.h>
#import "MapPinColor.h"
#import "DepartureTimesDataProvider.h"

@class DepartureTimes;
@class DepartureData;


@interface XMLDeparturesUI : NSObject <MapPinColor, DepartureTimesDataProvider> {

    XMLDepartures *_data;
}

+ (XMLDeparturesUI *)createFromData:(XMLDepartures *)data;
- (id)initWithData:(XMLDepartures *)data;

// MKAnnotation
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
- (NSString*) title; 
- (MKPinAnnotationColor) getPinColor;
- (NSString *)mapStopId;


@property (nonatomic, retain) XMLDepartures *data;

@end
