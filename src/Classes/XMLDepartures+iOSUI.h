//
//  XMLDepartures+iOSUI.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLDepartures.h"

#import "DepartureTimesDataProvider.h"
#import "MapPin.h"

// #import <MapKit/MkAnnotation.h>

@class DepartureTimes;
@class Departure;

@interface XMLDepartures (iOSUI) <MapPin, DepartureTimesDataProvider>

@property(nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property(nonatomic, readonly, copy) NSString *title;

@end
