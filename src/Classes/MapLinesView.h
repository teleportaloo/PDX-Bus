//
//  MapLinesView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/3/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MapLinesDrawView : UIView
{
	NSArray* _annotations;
	MKMapView *_mapView;
}

@property (nonatomic, retain) NSArray* annotations;
@property (nonatomic, retain) MKMapView *mapView;

@end



@interface MapLinesView : MKAnnotationView {
	MKMapView* _mapView;
	NSArray* _annotations;
	MapLinesDrawView *_drawView;
}

@property (nonatomic, retain) NSArray* annotations;
@property (nonatomic, retain) MKMapView* mapView; 
@property (nonatomic, retain) MapLinesDrawView *drawView;


-(id) initWithAnnotations:(NSArray*)routePoints mapView:(MKMapView*)mapView;
- (void)hide:(bool)hide;
-(void) regionChanged;

@end
