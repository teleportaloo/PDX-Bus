//
//  MapViewController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/17/09.
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
	MKMapView *mapView;
	NSMutableArray *_annotations;
	NSMutableArray *_lineCoords;
	NSMutableArray *_routePolyLines;
	MKCircle *_circle;
	
	bool _lines;
	int _selectedAnnotation;
	MapLinesView *_linesView;
	id<MapPinColor> _tappedAnnot;
	NSInteger mapButtonIndex;
	NSInteger cancelButtonIndex;
	bool _overlaysSupported;
	UISegmentedControl *_segPrevNext;
}

@property (nonatomic, retain) NSMutableArray *routePolyLines;
@property (nonatomic, retain) id<MapPinColor> tappedAnnot;
@property (nonatomic, retain) NSMutableArray *annotations;
@property (nonatomic) bool lines;
@property (nonatomic, retain) MapLinesView *linesView;
@property (nonatomic, retain) NSMutableArray *lineCoords;
@property (nonatomic, retain) MKCircle *circle;

// - (void)setMapLocationLat:(NSString *)lat lng:(NSString *)lng title:(NSString *)title;
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation;
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control;
- (void)addPin:(id<MapPinColor>) pin;
- (BOOL)supportsOverlays;

@end
