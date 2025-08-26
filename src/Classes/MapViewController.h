//
//  MapViewController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/17/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "MapPin.h"
#import "RouteMultiPolyline.h"
#import "ShapeRoutePath.h"
#import "UIToolbar+Auto.h"
#import "ViewControllerBase.h"
#import "XMLDepartures.h"
#import <MapKit/MapKit.h>
#import <UIKit/UIKit.h>

typedef enum MapViewLineOptionsEnum {
    MapViewNoLines,
    MapViewFitLines,
    MapViewNoFitLines
} MapViewLineOptions;

@interface MapViewController
    : ViewControllerBase <MKMapViewDelegate, BackgroundTaskDone>

@property(nonatomic, copy) NSString *msgText;
@property(nonatomic, strong) NSMutableArray<ShapeRoutePath *> *shapes;
@property(nonatomic) MapViewLineOptions lineOptions;
@property(nonatomic) bool nextPrevButtons;
@property(nonatomic, strong) NSMutableArray<id<MapPin>> *annotations;
@property(nonatomic, strong) NSMutableArray<id<MapPin>> *staticAnnotations;
@property(nonatomic, strong) MKMapView *mapView;
@property(nonatomic) bool backgroundRefresh;
@property(nonatomic) bool staticOverlays;

- (void)addPin:(id<MapPin>)pin;
- (void)addDataToMap:(bool)zoom animate:(bool)animate;
- (void)updateOverlays;
- (void)removeOverlays;
- (void)didEnterBackground;
- (void)didBecomeActive;

@end
