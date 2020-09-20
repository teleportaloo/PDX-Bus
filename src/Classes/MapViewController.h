//
//  MapViewController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/17/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "XMLDepartures.h"
#import "MapPinColor.h"
#import "UIToolbar+Auto.h"
#import "ViewControllerBase.h"
#import "ShapeRoutePath.h"
#import "RoutePolyline.h"


typedef enum _mapViewlineOptions {
    MapViewNoLines,
    MapViewFitLines,
    MapViewNoFitLines
} MapViewLineOptions;

@interface MapViewController : ViewControllerBase <MKMapViewDelegate, BackgroundTaskDone>

@property (nonatomic, copy)   NSString *msgText;
@property (nonatomic, strong) NSMutableArray<ShapeRoutePath *> *lineCoords;
@property (nonatomic)         MapViewLineOptions lineOptions;
@property (nonatomic)         bool nextPrevButtons;
@property (nonatomic, strong) NSMutableArray<id<MapPinColor> > *annotations;
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic)         bool backgroundRefresh;
@property (nonatomic, strong) MKCircle *circle;

- (void)addPin:(id<MapPinColor>)pin;

@end
