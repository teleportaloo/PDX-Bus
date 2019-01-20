//
//  XMLDepartures+iOSUI.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLDepartures.h"

#import "MapPinColor.h"
#import "DepartureTimesDataProvider.h"

// #import <MapKit/MkAnnotation.h>

@class DepartureTimes;
@class DepartureData;

@interface XMLDepartures (iOSUI)  <MapPinColor, DepartureTimesDataProvider>

// MapPinColor
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title; 
@property (nonatomic, readonly) MapPinColorValue pinColor;
@property (nonatomic, readonly, copy) NSString *mapStopId;

@end
