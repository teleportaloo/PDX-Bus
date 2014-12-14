//
//  AlarmAccurateStopProximity.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/11/11.
//  Copyright 2011 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */




#import "AlarmAccurateStopProximity.h"
#import "AlarmTaskList.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"
#import "MapViewController.h"
#import "SimpleAnnotation.h"
#import "DebugLogging.h"
#import "MapViewController.h"

#ifdef DEBUG_ALARMS
#define kDataDictLoc        @"loc"
#define kDataDictState      @"state"
#define kDataDictAppState   @"appstate"
#endif

@implementation AlarmAccurateStopProximity

@synthesize destination		= _destination;
@synthesize locationManager = _locationManager;

- (void)dealloc
{
	if (self.locationManager !=nil)
	{
		[self stopUpdatingLocation];
		[self stopMonitoringSignificantLocationChanges];
	
		self.locationManager.delegate = nil;
		self.locationManager = nil;
	}
    
#ifdef DEBUG_ALARMS
    self.dataReceived = nil;
#endif
	
	self.destination = nil;
	[super dealloc];
}

- (id)initWithAccuracy:(bool)accurate
{
	if ((self = [super init]))
	{
		self.locationManager = [[[CLLocationManager alloc] init] autorelease];
        
        
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        {
            [self.locationManager requestAlwaysAuthorization];
        }
        
        
        // Temporary cleanup - regions last forever!
        /*
        NSSet *regions = self.locationManager.monitoredRegions;
        
        for (CLRegion *region in regions)
        {
            [self.locationManager stopMonitoringForRegion:region];
        }
        */
        // self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        // self.locationManager.distanceFilter  = 100.0;
		_accurate = accurate;
		if (_accurate)
		{
			self.alarmState = AlarmStateAccurateLocationNeeded;
		}
		else 
		{
			self.alarmState = AlarmStateAccurateInitiallyThenInaccurate;
		}
		self.locationManager.delegate = self;
        _updating       = NO;
        _significant    = NO;
		[self startUpdatingLocation];
		// self.locationManager.distanceFilter = 250.0;
		
#ifdef DEBUG_ALARMS
        self.dataReceived = [[NSMutableArray alloc] init];
#endif
	}
	return self;
}

- (void)startUpdatingLocation
{
    if (!_updating)
    {
        _updating = YES;
        [self.locationManager startUpdatingLocation];
    }

}
- (void)stopUpdatingLocation
{
    if (_updating)
    {
        _updating = NO;
        [self.locationManager stopUpdatingLocation];
    } 
}
- (void)startMonitoringSignificantLocationChanges
{
    if (!_significant)
    {
        _significant = YES;
        [self.locationManager startMonitoringSignificantLocationChanges];
    }
}
- (void)stopMonitoringSignificantLocationChanges
{
    if (_significant)
    {
        _significant = NO;
        [self.locationManager stopMonitoringSignificantLocationChanges];
    }
}

- (void)setStop:(NSString *)stopId lat:(NSString *)lat lng:(NSString *)lng desc:(NSString *)desc
{
	self.desc = desc;
	self.stopId = stopId;
	
	self.destination = [[[CLLocation alloc] initWithLatitude:[lat doubleValue] 
												   longitude:[lng doubleValue]] autorelease];
}


- (CLLocationDistance)distanceFromLocation:(CLLocation *)location
{
    CLLocationDistance dist = [self.destination distanceFromLocation:location]
                                    - location.horizontalAccuracy /2 ;
    
    if (dist < 0)
    {
        return -dist;
    }
	return 	dist;
}

-(void)delayedDelete:(id)arg
{		
	[self release];
}

- (void)locationManager:(CLLocationManager *)manager 
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation
{
	CLLocationDistance minPossibleDist = [self distanceFromLocation:newLocation];
	
#ifdef DEBUG_ALARMS
	if (_done)
	{
		return;
	}
        

    NSDictionary *dict = [ NSDictionary dictionaryWithObjectsAndKeys:  
                                    newLocation,                              kDataDictLoc,
                                    [NSNumber numberWithInt:self.alarmState], kDataDictState,
                                    [self appState],        kDataDictAppState, 
                                     nil];
                          
    AlarmLocationNeeded previousState = self.alarmState;
	
	[self.dataReceived addObject:dict];
#endif	
	
	double becomeAccurate = [UserPrefs getSingleton].useGpsWithin;
	
	
	
	if ([newLocation.timestamp timeIntervalSinceNow] < -5*60 || self.alarmState == AlarmFired)
	{
		// too old
		return;
	}
	
	[[self retain] autorelease];
	
	if (newLocation.horizontalAccuracy < kBadAccuracy && self.alarmState == AlarmStateAccurateInitiallyThenInaccurate)
	{
		self.alarmState = AlarmStateInaccurateLocationNeeded;
	}
	else if ((newLocation.horizontalAccuracy > kBadAccuracy) &&  (self.alarmState == AlarmStateInaccurateLocationNeeded))
	{
		// Not accurate enough.  Ensure we are using the best we can
		self.alarmState = AlarmStateAccurateInitiallyThenInaccurate;
	}

    
	
	// We may switch from low power to GPS at this point
	
	
	if (minPossibleDist < (double)kProximity && (newLocation.horizontalAccuracy > kBadAccuracy))
	{
		// Not accurate enough.  Ensure we are using the best we can
		self.alarmState = AlarmStateAccurateLocationNeeded;
	}
	else if (minPossibleDist < (double)kProximity)
	{
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterLongStyle];
		
		[self alert:[NSString stringWithFormat:NSLocalizedString(@"You are within %@ of %@", @"gives a distance to a stop"), kUserDistanceProximity, self.desc]
		   fireDate:nil
			 button:NSLocalizedString(@"Show map", @"map alert button text")
		   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
									self.stopId,														kStopIdNotification,
									self.desc,															kStopMapDescription,
									[NSNumber numberWithDouble:self.destination.coordinate.latitude],	kStopMapLat,
									[NSNumber numberWithDouble:self.destination.coordinate.longitude],	kStopMapLng,
									[NSNumber numberWithDouble:newLocation.coordinate.latitude],		kCurrLocLat,
									[NSNumber numberWithDouble:newLocation.coordinate.longitude],		kCurrLocLng,
									[dateFormatter stringFromDate:newLocation.timestamp],				kCurrTimestamp,
									nil
									]
	   defaultSound:NO];
		
#ifdef DEBUG_ALARMS
		_done = true;
#endif
		self.alarmState = AlarmFired;
		
	}
	else if (minPossibleDist <= becomeAccurate)
	{
		self.alarmState = AlarmStateAccurateLocationNeeded;
	}
	else if (minPossibleDist > becomeAccurate && !_accurate && self.alarmState!=AlarmStateAccurateInitiallyThenInaccurate)
	{
		self.alarmState = AlarmStateInaccurateLocationNeeded;
	}
	
	switch (self.alarmState)
	{
		case AlarmStateAccurateInitiallyThenInaccurate:
		case AlarmStateAccurateLocationNeeded:
			[self startUpdatingLocation];
			[self stopMonitoringSignificantLocationChanges];
			break;
		case AlarmStateInaccurateLocationNeeded:
			[self stopUpdatingLocation];
			[self startMonitoringSignificantLocationChanges];
			break;
		case AlarmFired:
			[self stopUpdatingLocation];
			[self stopMonitoringSignificantLocationChanges];
			NSTimer *timer = [[[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:0.5]
													   interval:0.1 
														 target:[self retain]
													   selector:@selector(delayedDelete:) 
													   userInfo:nil 
														repeats:NO] autorelease];
			[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode]; 
			break;
        default:
            break;
	}
	
	[self.observer taskUpdate:self];	
#ifdef DEBUG_ALARMS
    if (previousState != self.alarmState)
    {
        NSDictionary *dict2 = [NSDictionary dictionaryWithObjectsAndKeys:  
                               [NSNumber numberWithInt:self.alarmState], kDataDictState,
                                nil];
        [self.dataReceived addObject:dict2];
    }
#endif
}

- (void)locationManager:(CLLocationManager *)manager
	   didFailWithError:(NSError *)error
{
	DEBUG_LOG(@"location error %@\n", [error localizedDescription]);
	
    switch (error.code)
    {
        case kCLErrorLocationUnknown:
            break;
        case kCLErrorDenied:
            [self alert:[NSString stringWithFormat:NSLocalizedString(@"Unable to acquire location - proximity alarm cancelled %@", @"location error with alarm name"), [error localizedDescription]]
               fireDate:nil 
                 button:nil 
               userInfo:nil
           defaultSound:YES];
            
            [self stopUpdatingLocation];
            [self stopMonitoringSignificantLocationChanges];
            self.locationManager.delegate = nil;
            self.locationManager = nil;
            
            [self cancelTask];
            break;
        default:
            break;
    }
}

- (void)cancelAlert
{
	
	UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Proximity Alarm", @"alarm title")
													   message:NSLocalizedString(@"Cancel proximity alarm?", @"alarm button text")
													  delegate:self
											 cancelButtonTitle:NSLocalizedString(@"Cancel", @"button text")
											 otherButtonTitles:NSLocalizedString(@"Keep", @"button text to not cancel alarm"), nil] autorelease];
	[alert show];
}


// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0)
	{
#ifdef DEBUG_ALARMS
		_done = true;
#endif
		[self.observer taskDone:self];
	}
}

- (NSString *)key
{
	return self.stopId;
}

- (void)cancelTask
{
#ifdef DEBUG_ALARMS
	_done = true;
#endif
	[self.observer taskDone:self];
	
}

- (int)internalDataItems
{
#ifdef DEBUG_ALARMS
	return self.dataReceived.count;
#else
	return 0;
#endif
}

- (NSString *)internalData:(int)item
{
#ifdef DEBUG_ALARMS
	NSMutableString *str = [[[NSMutableString alloc] init] autorelease];
    
    NSDictionary *dict = [self.dataReceived objectAtIndex:item];
    
	CLLocation *loc = [dict objectForKey:kDataDictLoc];
    
    if (loc!=nil)
    {
        [str appendFormat:@"%f %f\n", loc.coordinate.latitude, loc.coordinate.longitude];
        [str appendFormat:@"dist: %f\n", [self distanceFromLocation:loc]];
        [str appendFormat:@"accuracy: %f\n", loc.horizontalAccuracy];
		
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterLongStyle];
		
        [str appendFormat:@"%@\n", [dateFormatter stringFromDate:loc.timestamp]];
    }
    
    [str appendFormat:@"%@\n", [dict objectForKey:kDataDictAppState]];     
#define CASE_ENUM_TO_STR(X)  case X: [str appendFormat:@"%s\n", #X]; break
    NSNumber *taskState = [ dict objectForKey:kDataDictState];
    
    if (taskState!=nil)
    {
        switch ((AlarmLocationNeeded)[taskState intValue])
        {
                CASE_ENUM_TO_STR(AlarmStateFetchArrivals);
                CASE_ENUM_TO_STR(AlarmStateNearlyArrived);
                CASE_ENUM_TO_STR(AlarmStateAccurateLocationNeeded);
                CASE_ENUM_TO_STR(AlarmStateAccurateInitiallyThenInaccurate);
                CASE_ENUM_TO_STR(AlarmStateInaccurateLocationNeeded);
                CASE_ENUM_TO_STR(AlarmFired);
                
            default:
                [str appendFormat:@"%d\n", [taskState intValue]];
        }
    }
    
    
	return str;
#else
	return nil;
#endif
}


- (void)showToUser:(BackgroundTaskContainer *)backgroundTask
{
	if (self.locationManager.location!=nil)
	{
		TriMetTimesAppDelegate *app = [TriMetTimesAppDelegate getSingleton];
		MapViewController *mapPage = [[MapViewController alloc] init];
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterLongStyle];
        
        
		mapPage.title = NSLocalizedString(@"Stop Proximity", @"map title");
		[mapPage addPin:self];
		
		SimpleAnnotation *currentLocation = [[[SimpleAnnotation alloc] init] autorelease];
		currentLocation.pinColor		= MKPinAnnotationColorPurple;
		currentLocation.pinTitle		= NSLocalizedString(@"Current Location", @"map pin text");
		[currentLocation setCoord:		self.locationManager.location.coordinate];
		currentLocation.pinSubtitle		= [NSString stringWithFormat:NSLocalizedString(@"as of %@", @"shows the date"), [dateFormatter stringFromDate:self.locationManager.location.timestamp]];
		[mapPage addPin:currentLocation];
		
		[[app.rootViewController navigationController] pushViewController:mapPage animated:YES];
		[mapPage release];
	}
}

- (MKPinAnnotationColor) getPinColor
{
	return MKPinAnnotationColorGreen;
}

- (bool) showActionMenu
{
	return YES;
}

- (CLLocationCoordinate2D)coordinate
{
	return self.destination.coordinate;	
}

- (NSString *)title
{
	return self.desc;
}

- (NSString *)subtitle
{
	return [NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), self.stopId];
}

- (NSString *) mapStopId
{
	return self.stopId;
}


- (NSString *)cellToGo
{
	if (self.locationManager.location==nil)
	{
		return @"";
	}
	
	double distance = [self distanceFromLocation:self.locationManager.location];
	
	NSString *str = nil;
	NSString *accuracy = nil;
	
    if (self.alarmState == AlarmFired)
    {
        accuracy = NSLocalizedString(@"Final distance:", @"final distance that triggered alarm");
        
    }
    else if (self.locationManager.location.horizontalAccuracy > 200 || self.alarmState != AlarmStateAccurateLocationNeeded)
	{
		accuracy = NSLocalizedString(@"Approx distance:", @"distance to alarm");
	}
	else {
		accuracy = NSLocalizedString(@"Distance:", @"distance to alarm");
	}

	if (distance <=0)
	{
		str = [NSString stringWithFormat:NSLocalizedString(@"Near by", @"final stop is very close")];
	}
	else if (distance < 500)
	{
		str = [NSString stringWithFormat:NSLocalizedString(@"%@ %d ft (%d meters)", @"distance in feet then metres"), accuracy, (int)(distance * 3.2808398950131235),
			   (int)(distance) ];
	}
	else
	{
		str = [NSString stringWithFormat:NSLocalizedString(@"%@ %.2f miles (%.2f km)", @"distance in miles then kms"), accuracy, (float)(distance / 1609.344),
			   (float)(distance / 1000) ];
	}	
	
	return str;
}

- (void)showMap:(UINavigationController *)navController
{
#ifdef DEBUG_ALARMS
    MapViewController *mapPage = [[MapViewController alloc] init];
    
    mapPage.lines = YES;
    
    mapPage.lineCoords = [[[NSMutableArray alloc] init] autorelease];
    
    for (NSDictionary *dict in self.dataReceived)
    {
        CLLocation *loc = [dict objectForKey:kDataDictLoc];
        ShapeCoord *shape = [[ShapeCoord alloc] init];
        
        [shape setLatitude: loc.coordinate.latitude];
        [shape setLongitude:loc.coordinate.longitude];
        
        [mapPage.lineCoords addObject:shape];
        
        [shape release];
    }
    
    [mapPage.lineCoords addObject:[ShapeCoord makeEnd]];
    
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterLongStyle];
    
    [mapPage addPin:self];
    
    SimpleAnnotation *currentLocation = [[[SimpleAnnotation alloc] init] autorelease];
    currentLocation.pinColor		= MKPinAnnotationColorPurple;
    currentLocation.pinTitle		= NSLocalizedString(@"Current Location", @"map pin text");
    [currentLocation setCoord:		self.locationManager.location.coordinate];
    currentLocation.pinSubtitle		= [NSString stringWithFormat:NSLocalizedString(@"as of %@", @"shows the date"), [dateFormatter stringFromDate:self.locationManager.location.timestamp]];
    [mapPage addPin:currentLocation];
    
    [navController pushViewController:mapPage animated:YES];
	[mapPage release];	
#endif
}

@end


