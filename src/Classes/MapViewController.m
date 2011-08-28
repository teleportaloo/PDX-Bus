//
//  MapViewController.m
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

#import "MapViewController.h"
#import <MapKit/MapKit.h>
#import <MapKit/MkAnnotation.h>
#import "Departure.h"
#import "XMLDepartures.h"
#import "MapPinColor.h"
#import "DepartureTimesView.h"
#import "DepartureDetailView.h"
#import "TriMetTimesAppDelegate.h"

#define kPrev @"Prev"
#define kStart @"Start"
#define kNext @"Next"
#define kEnd @"End"

@implementation LinesAnnotation

@synthesize middle = _middle;

- (CLLocationCoordinate2D) coordinate
{
	return self.middle;
}

@end


@implementation LinesAnnotationView
@synthesize linesView = _linesView;


- (void)dealloc
{
	self.linesView = nil;
	[super dealloc];
}


@end


@implementation MapViewController

@synthesize annotations = _annotations;
@synthesize lines = _lines;
@synthesize linesView = _linesView;
@synthesize tappedAnnot = _tappedAnnot;
@synthesize lineCoords = _lineCoords;
@synthesize routePolyLines = _routePolyLines;
@synthesize circle = _circle;

- (void)dealloc {
	self.annotations = nil;
	mapView.delegate = nil;
	mapView.showsUserLocation=FALSE;
	self.routePolyLines = nil;
	[mapView removeAnnotations:mapView.annotations];
	self.linesView = nil;
	self.tappedAnnot = nil;
	self.lineCoords = nil;
	self.circle = nil;
	[_segPrevNext release];
	// A bug in the SDK means that releasing a mapview can cause a crash as it may be animating
	// we delay 4 seconds for the release.
	[mapView performSelector:@selector(release) withObject:nil afterDelay:(NSTimeInterval)4.0];
	[super dealloc];
}

- (id)init {
	if ((self = [super init]))
	{
		self.title = @"Transit Map";
		self.annotations = [[[ NSMutableArray alloc ] init] autorelease];
	}
	return self;
}

#pragma mark Helper functions

- (void)addPin:(id<MapPinColor>) pin
{
	[self.annotations addObject:pin];
}

#pragma mark Prev/Next Segment controller

- (void)setSegText:(UISegmentedControl*)seg
{
	if (_selectedAnnotation > 1)
	{
		[seg setTitle:kPrev forSegmentAtIndex:0];
	}
	else {
		[seg setTitle:kStart forSegmentAtIndex:0];
	}

	if (_selectedAnnotation <  self.annotations.count-2)
	{
		[seg setTitle:kNext forSegmentAtIndex:1];
	}
	else {
		[seg setTitle:kEnd forSegmentAtIndex:1];
	}
}

- (void)prevNext:(id)sender
{
	UISegmentedControl *segControl = sender;
	switch (segControl.selectedSegmentIndex)
	{
		case 0:	// UIPickerView
		{
			// Prev
			if (_selectedAnnotation > 0)
			{
				_selectedAnnotation--;
				
			}
			break;
		}
		case 1:	// UIPickerView
		{
			if (_selectedAnnotation < (self.annotations.count-1) )
			{
				_selectedAnnotation++;
			}
			break;
		}
	}
	
	[self setSegText:segControl];
	
	[mapView deselectAnnotation:[self.annotations objectAtIndex:_selectedAnnotation] animated:NO];
	[mapView selectAnnotation:[self.annotations objectAtIndex:_selectedAnnotation] animated:YES];
}


#pragma mark UI Callbacks

- (void)toggleMap:(id)sender
{
	UISegmentedControl *segControl = sender;
	switch (segControl.selectedSegmentIndex)
	{
		case 0:	// UIPickerView
		{
			mapView.mapType = MKMapTypeStandard;
			break;
		}
		case 1:	// UIPickerView
		{
			mapView.mapType = MKMapTypeHybrid;
			break;
		}
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == mapButtonIndex)
	{
		
		
		NSString *url = [NSString stringWithFormat:@"maps:q=PDXBus@%f,%f",  
						 // [self.tappedAnnot.title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
						 self.tappedAnnot.coordinate.latitude, self.tappedAnnot.coordinate.longitude];
		
		if (![[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]])
		{
			NSString *url2 = [NSString stringWithFormat:@"http://map.google.com/?q=PDXBus@%f,%f",  
							  // [self.tappedAnnot.title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
							  self.tappedAnnot.coordinate.latitude, self.tappedAnnot.coordinate.longitude];
			
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url2]];
			
		}
		
	}
	else if (buttonIndex == cancelButtonIndex)
	{
		// do nothing
	}
	else
	{
		if ([self.tappedAnnot respondsToSelector: @selector(mapTapped:)] && [self.tappedAnnot mapTapped:self.backgroundTask])
		{
			return;
		}
		else if ([self.tappedAnnot respondsToSelector: @selector(mapStopId)])
		{
			DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
			
			departureViewController.callback = self.callback;
			
			[departureViewController fetchTimesForLocationInBackground:self.backgroundTask loc:[self.tappedAnnot mapStopId]];
			[departureViewController release];
		}
		else if ([self.tappedAnnot respondsToSelector: @selector(mapDeparture)])
		{
			Departure *departure = [self.tappedAnnot mapDeparture];
			DepartureDetailView *departureDetailView = [[DepartureDetailView alloc] init];
			departureDetailView.callback = self.callback;
			
			[departureDetailView fetchDepartureInBackground:self.backgroundTask dep:departure allDepartures:nil   allowDestination:NO];
			[departureDetailView release];	
		}
	}
}



#pragma mark ViewControllerBase methods

-(void)infoAction:(id)sender
{
	UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Info"
													   message:@"The route path does not reflect future service changes until they come into effect.\n"
																"Route and arrival data provided by permission of TriMet."
													  delegate:nil
											 cancelButtonTitle:@"OK"
											 otherButtonTitles:nil ] autorelease];
	[alert show];
	
	
}

- (void)createToolbarItems
{
	// add a segmented control to the button bar
	UISegmentedControl	*buttonBarSegmentedControl;
	buttonBarSegmentedControl = [[UISegmentedControl alloc] initWithItems:
								 [NSArray arrayWithObjects:@"Map", @"Hybrid", nil]];
	[buttonBarSegmentedControl addTarget:self action:@selector(toggleMap:) forControlEvents:UIControlEventValueChanged];
	buttonBarSegmentedControl.selectedSegmentIndex = 0.0;	// start by showing the normal picker
	buttonBarSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	
	int color = _prefs.toolbarColors;
	
	if (color == 0xFFFFFF)
	{
		
		buttonBarSegmentedControl.tintColor = [UIColor darkGrayColor];
	}
	else {
		buttonBarSegmentedControl.tintColor = [self htmlColor:color];
	}

	buttonBarSegmentedControl.backgroundColor = [UIColor clearColor];
	
	UIBarButtonItem *segItem = [[UIBarButtonItem alloc] initWithCustomView:buttonBarSegmentedControl];	
	
	NSArray *items = nil;
	
	if (self.lines)
	{
		// create the system-defined "OK or Done" button
		UIBarButtonItem *info = [[[UIBarButtonItem alloc]
								  initWithTitle:@"info"
								  style:UIBarButtonItemStyleBordered
								  target:self action:@selector(infoAction:)] autorelease];
		
		
		// info.style = UIBarButtonItemStylePlain;
		// info.title = @"Info";
		
		
		items = [NSArray arrayWithObjects: [self autoDoneButton], [CustomToolbar autoFlexSpace], 
				 segItem, [CustomToolbar autoFlexSpace], 
				 info,
				 [CustomToolbar autoFlexSpace],
				 [CustomToolbar autoFlashButtonWithTarget:self action:@selector(flashButton:)], nil];
		
	}
	else {
		items = [NSArray arrayWithObjects: [self autoDoneButton], [CustomToolbar autoFlexSpace], 
		   segItem, [CustomToolbar autoFlexSpace], [CustomToolbar autoFlashButtonWithTarget:self action:@selector(flashButton:)], nil];
	}

	[self setToolbarItems:items animated:NO];
	
	[segItem release];
	[buttonBarSegmentedControl release];
}

- (BOOL)supportsOverlays
{
	return [MKMapView instancesRespondToSelector:@selector(addOverlays:)];
}


#pragma mark View functions

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// Set the size for the table view
	CGRect mapViewRect;
	mapViewRect.size.width = [[UIScreen mainScreen] applicationFrame].size.width;
	mapViewRect.size.height = [[UIScreen mainScreen] applicationFrame].size.height;
	mapViewRect.origin.x = 0;
	mapViewRect.origin.y = 0;
	
	mapView=[[MKMapView alloc] initWithFrame:mapViewRect];
	mapView.showsUserLocation=TRUE;
	mapView.mapType=MKMapTypeStandard;
	mapView.delegate=self;
	mapView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
	
	_overlaysSupported = [self supportsOverlays];
	

    if (self.lineCoords != nil)
	{
		[_segPrevNext release];
		_segPrevNext = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects: 
																			 kPrev,
																			 kNext, nil] ];
		_segPrevNext.frame = CGRectMake(0, 0, 80, 30.0);
		_segPrevNext.segmentedControlStyle = UISegmentedControlStyleBar;
		_segPrevNext.momentary = YES;
		[_segPrevNext addTarget:self action:@selector(prevNext:) forControlEvents:UIControlEventValueChanged];
		
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView: _segPrevNext];
		
		_selectedAnnotation = 0;
		
		[self setSegText:_segPrevNext];
		
	}
	
	if (self.annotations != nil)
	{
		int i;
		for (i=0; i< [self.annotations count]; i++)
		{
			[mapView addAnnotation:[self.annotations objectAtIndex:i]];
		}
	}
	
	if (self.annotations !=nil && [self.annotations count] < 2)
	{
		
		/*Region and Zoom*/
		MKCoordinateRegion region;
		region.center.latitude = 0.0;
		region.center.longitude = 0.0;
		MKCoordinateSpan span;
		span.latitudeDelta=0.005;
		span.longitudeDelta=0.005;
		
		region.span=span;
		
		if (self.annotations != nil && [self.annotations count] > 0)
		{
			region.center = ((id<MKAnnotation>)[self.annotations objectAtIndex:0]).coordinate;
		}
		
		
		
		// MKPinAnnotationView * pin = [[[MKPinAnnotationView alloc] initWithAnnotation:pinPos reuseIdentifier:@"mainPin"] autorelease];
		
		// pin.pinColor = MKPinAnnotationColorRed;
		// pin.animatesDrop = YES;
		
		
		[mapView regionThatFits:region];
		[mapView setRegion:region animated:TRUE];
	}
	else if (self.annotations !=nil && [self.annotations count] >= 2 && _overlaysSupported)
	{
		// Walk the list of overlays and annotations and create a MKMapRect that
		// bounds all of them and store it into flyTo.
		MKMapRect flyTo = MKMapRectNull;
		
		for(int i = 0; i < self.annotations.count; i++)
		{
			id<MapPinColor> pin = [self.annotations objectAtIndex:i];
			
			MKMapPoint annotationPoint = MKMapPointForCoordinate(pin.coordinate);
			MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
			
			
			if (MKMapRectIsNull(flyTo)) {
				flyTo = pointRect;
			} else {
				flyTo = MKMapRectUnion(flyTo, pointRect);
			}
		}
		
		if (self.lines && self.lineCoords != nil)
		{
			for(int i = 0; i < self.lineCoords.count; i++)
			{
				ShapeCoord * coord = [self.lineCoords objectAtIndex:i];
				
				if (coord.end)
				{
					continue;
				}
				
				
				MKMapPoint annotationPoint = MKMapPointForCoordinate(coord.coord);
				MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
				
				
				if (MKMapRectIsNull(flyTo)) {
					flyTo = pointRect;
				} else {
					flyTo = MKMapRectUnion(flyTo, pointRect);
				}
				
			}
			
		}
		
		UIEdgeInsets insets = { 20, 20, 20, 20 };
		mapView.visibleMapRect=[mapView mapRectThatFits:flyTo edgePadding:insets];
	} 
	else if (self.annotations !=nil && [self.annotations count] >= 2)
	{
		CLLocationDegrees maxLat = -90;
		CLLocationDegrees maxLon = -180;
		CLLocationDegrees minLat = 90;
		CLLocationDegrees minLon = 180;
		
		for(int i = 0; i < self.annotations.count; i++)
		{
			id<MapPinColor> pin = [self.annotations objectAtIndex:i];
			CLLocationCoordinate2D coord = pin.coordinate;
			if(coord.latitude > maxLat)
			{
				maxLat = coord.latitude;
			}
			if(coord.latitude < minLat)
			{
				minLat = coord.latitude;
			}
			if(coord.longitude > maxLon)
			{
				maxLon = coord.longitude;
			}
			if(coord.longitude < minLon)
			{
				minLon = coord.longitude;
			}
		}
		
		if (self.lines && self.lineCoords != nil)
		{
			for(int i = 0; i < self.lineCoords.count; i++)
			{
				ShapeCoord * coord = [self.lineCoords objectAtIndex:i];
				
				if (coord.end)
				{
					continue;
				}
				if(coord.latitude > maxLat)
				{
					maxLat = coord.latitude;
				}
				if(coord.latitude < minLat)
				{
					minLat = coord.latitude;
				}
				if(coord.longitude > maxLon)
				{
					maxLon = coord.longitude;
				}
				if(coord.longitude < minLon)
				{
					minLon = coord.longitude;
				}
			}
			
		} 
		
		MKCoordinateRegion region;
		region.center.latitude     = (maxLat + minLat) / 2;
		region.center.longitude    = (maxLon + minLon) / 2;
		region.span.latitudeDelta  = maxLat - minLat + 0.001;
		region.span.longitudeDelta = maxLon - minLon + 0.001;
		
		[mapView regionThatFits:region];
		[mapView setRegion:region animated:TRUE];
	} 
	
	
	if (self.lines && !_overlaysSupported)
	{
		self.linesView = [[[MapLinesView alloc] initWithAnnotations:self.lineCoords mapView:mapView] autorelease];
		self.title = @"Trip Map";
		
		LinesAnnotation *annot = [[LinesAnnotation alloc] init];
		annot.middle = mapView.region.center;
		
		[mapView addAnnotation:annot];
		
		[annot release];
	}
	else if (self.lines) { // overlays!
		
		CLLocationCoordinate2D *coords = malloc(sizeof(CLLocationCoordinate2D) * self.lineCoords.count); 
		self.routePolyLines = [[[NSMutableArray alloc] init] autorelease];
		
		int j = 0;
		for (int i=0; i < self.lineCoords.count; i++)
		{
			ShapeCoord *coord = [self.lineCoords objectAtIndex:i];
			
			if (coord.end)
			{
				[self.routePolyLines addObject:
					 [MKPolyline polylineWithCoordinates:coords count:j]];
				 j=0;
				
			}
			else {
				
				coords[j] = [coord coord];
				j++;
			}

		}
				 
		free(coords);
	
		[mapView addOverlays:self.routePolyLines];
	}
	
	if (self.circle && _overlaysSupported)
	{
		[mapView addOverlay:self.circle];
		
	}
	
	[self.view insertSubview:mapView atIndex:0];
}


- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
	for (MKPolyline *poly in self.routePolyLines)
	{
		if (poly == overlay)
		{
			MKPolylineView *lineView = [[MKPolylineView alloc] initWithPolyline:poly];
	
			lineView.strokeColor = [UIColor blueColor];
			// lineView.fillColor = fillColor;
			lineView.lineWidth = 3.0;
	
	
			return [lineView autorelease];
		}
	}
	
	if (overlay == self.circle)
	{
		MKCircleView *circleView = [[MKCircleView alloc] initWithCircle:overlay];
		circleView.strokeColor = [UIColor greenColor];
		circleView.lineWidth = 3.0;
		return [circleView autorelease];
		
	}
	
	return nil;
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if (self.linesView !=nil)
	{
		[mapView setNeedsDisplay];
		// [self.linesView regionChanged];
	}
}


- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}



#pragma mark MapView functions

- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id <MKAnnotation>)annotation
{
	MKAnnotationView *retView = nil;
	
	if (annotation == mapView.userLocation)
	{
		return nil;
	}
	else if ([annotation isKindOfClass:[LinesAnnotation class]])
	{
		retView = self.linesView;
		retView.annotation = annotation;
		retView.canShowCallout = NO;
		// [self.linesView regionChanged];
	}
	else
	{
		MKPinAnnotationView *view = (MKPinAnnotationView*)[mv dequeueReusableAnnotationViewWithIdentifier: @"bus"];
		
		if (view == nil)
		{
			view=[[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"bus"] autorelease];
		}
		
		if ([annotation conformsToProtocol:@protocol(MapPinColor)]) 
		{
			id<MapPinColor> pin = (id<MapPinColor>)annotation;
			view.pinColor = [pin getPinColor];
			
			if ( [ DepartureTimesView canGoDeeper ] ) // && [pin mapDisclosure])
			{
				view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
			} 
			else
			{
				view.rightCalloutAccessoryView = nil;
			}
		}
		
		view.annotation = annotation;
		view.canShowCallout = YES;
		retView = view;
	}
	return retView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
	if (_segPrevNext && ([view.annotation conformsToProtocol:@protocol(MapPinColor)]))
	{
		for (int i=0; i<self.annotations.count; i++)
		{
			if (view.annotation == [self.annotations objectAtIndex:i])
			{
				_selectedAnnotation = i;
				[self setSegText:_segPrevNext];
				break;
			}
		}
	}
}


- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
	self.tappedAnnot = (id<MapPinColor>)view.annotation;
	
	
	if ([self.tappedAnnot mapDisclosure])
	{
		NSString *action = @"Show details";
		if ([self.tappedAnnot respondsToSelector: @selector(mapTapped:)]) //  && [self.tappedAnnot mapTapped])
		{
			action = nil;
			
			if ([self.tappedAnnot respondsToSelector:@selector(tapActionText)])
			{
				action = [self.tappedAnnot tapActionText];
			}
			if (action == nil)
			{
				action = @"Choose this stop";
			}
		}
		else if ([self.tappedAnnot respondsToSelector: @selector(mapStopId)])
		{
			action = @"Show arrivals";
		}
		else if ([self.tappedAnnot respondsToSelector: @selector(mapDeparture)])
		{
			action = @"Show details";
		}
		
		
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Map Action"
																 delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
														otherButtonTitles:action,@"Show in map app", nil];
		mapButtonIndex = 1;
		cancelButtonIndex = 2;
		actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
		[actionSheet showFromToolbar:self.navigationController.toolbar]; // show from our table view (pops up in the middle of the table)
		[actionSheet release];
	}
	else {
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Map Action"
																 delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
														otherButtonTitles:@"Show in map app", nil];
		mapButtonIndex = 0;
		cancelButtonIndex = 1;
		actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
		[actionSheet showFromToolbar:self.navigationController.toolbar]; // show from our table view (pops up in the middle of the table)
		[actionSheet release];
		
	}

}

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
	if (self.linesView !=nil)
	{
		[self.linesView hide:YES];
	}
	
}
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
	if (self.linesView !=nil)
	{
		[self.linesView hide:NO];
		[self.linesView regionChanged];
	}
}
			 			 
#pragma mark BackgroundTask callbacks

-(void)BackgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled
{
	if (!cancelled)
	{
		[self.navigationController pushViewController:viewController animated:YES];
	}
}

- (UIInterfaceOrientation)BackgroundTaskOrientation
{
	return self.interfaceOrientation;
}

@end

