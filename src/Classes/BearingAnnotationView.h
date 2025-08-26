//
//  BearingAnnotationView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/19/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapPin.h"
#import <MapKit/MapKit.h>

@interface BearingAnnotationView : MKAnnotationView

- (void)updateDirectionalAnnotationView:(MKMapView *)mapView;
- (void)updateDirectionInPlace:(MKMapView *)mapView;

+ (MKAnnotationView *)viewForPin:(id<MapPin>)pin
                         mapView:(MKMapView *)mapView
                       urlAction:(bool (^__nullable)(id<MapPin>, NSURL *url,
                                                     UIView *source))urlAction;

@end
