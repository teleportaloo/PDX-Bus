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
#import "CustomToolbar.h"
#import "MapLinesView.h"
#import "ViewControllerBase.h"
#import "LegShapeParser.h"

@interface LinesAnnotation : NSObject <MKAnnotation>
{
	CLLocationCoordinate2D _middle;
}

@property (nonatomic) CLLocationCoordinate2D middle;


@end


@interface LinesAnnotationView : MKPinAnnotationView
{
	MapLinesView *_linesView;
}

@property (nonatomic, retain) MapLinesView *linesView;

@end

@interface MapViewController : ViewControllerBase <MKMapViewDelegate, UIActionSheetDelegate, BackgroundTaskDone> {
	MKMapView *_mapView;
	NSMutableArray *_annotations;
	NSMutableArray *_lineCoords;
	NSMutableArray *_routePolyLines;
	MKCircle *_circle;
	
	bool _lines;
	int _selectedAnnotation;
	MapLinesView *_linesView;
	id<MapPinColor> _tappedAnnot;
    NSInteger _actionMapButtonIndex;
    NSInteger _stopIdMapButtonIndex;
	NSInteger _appleMapButtonIndex;
    NSInteger _ios5MapButtonIndex;
	NSInteger _cancelButtonIndex;
    NSInteger _googleMapButtonIndex;
    NSInteger _motionxMapButtonIndex;
    NSInteger _motionxHdMapButtonIndex;
    NSInteger _wazeMapButtonIndex;
	bool _overlaysSupported;
	UISegmentedControl *_segPrevNext;
    UIBarButtonItem *_compassButton;
    CGRect _portraitMapRect;
    CLLocationDirection _previousHeading;
    CADisplayLink *_displayLink;
    
    bool _backgroundRefresh;
}

@property (nonatomic, retain) MKMapView *mapView;
@property (nonatomic, retain) NSMutableArray *routePolyLines;
@property (nonatomic, retain) id<MapPinColor> tappedAnnot;
@property (nonatomic, retain) NSMutableArray *annotations;
@property (nonatomic) bool lines;
@property (nonatomic, retain) MapLinesView *linesView;
@property (nonatomic, retain) NSMutableArray *lineCoords;
@property (nonatomic, retain) MKCircle *circle;
@property (nonatomic, retain) UIBarButtonItem *compassButton;
@property (atomic)            bool animating;
@property (nonatomic)         bool backgroundRefresh;
@property (readonly)          bool hasXML;
@property (nonatomic) CLLocationDirection previousHeading;
@property (nonatomic, strong) CADisplayLink *displayLink;

// - (void)setMapLocationLat:(NSString *)lat lng:(NSString *)lng title:(NSString *)title;
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation;
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control;
- (void)addPin:(id<MapPinColor>) pin;
- (BOOL)supportsOverlays;
- (void)removeAnnotations;

@end
