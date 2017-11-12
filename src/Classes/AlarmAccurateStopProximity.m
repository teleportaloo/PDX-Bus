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
#import "FormatDistance.h"
#import "LocationAuthorization.h"
#include "iOSCompat.h"
#include "RootViewController.h"

#ifdef DEBUG_ALARMS
#define kDataDictLoc        @"loc"
#define kDataDictState      @"state"
#define kDataDictAppState   @"appstate"
#endif


@implementation AlarmAccurateStopProximity

@synthesize destination		= _destination;
@synthesize locationManager = _locationManager;

- (void)deleteLocationManager
{
    if (self.locationManager!=nil)
    {
        compatSetIfExists(self.locationManager, setAllowsBackgroundLocationUpdates:, NO);  //  iOS9
        
        [self stopUpdatingLocation];
        [self stopMonitoringSignificantLocationChanges];
        
        self.locationManager.delegate = nil;
        self.locationManager = nil;
    }
}

- (void)dealloc
{
    [self deleteLocationManager];
    
#ifdef DEBUG_ALARMS
    self.dataReceived = nil;
#endif
	
	self.destination = nil;
	[super dealloc];
}



- (instancetype)initWithAccuracy:(bool)accurate
{
	if ((self = [super init]))
	{
		self.locationManager = [CLLocationManager alloc].init.autorelease;
        
        self.locationManager.delegate = self;
        [self.locationManager requestAlwaysAuthorization];
        
        compatSetIfExists(self.locationManager, setAllowsBackgroundLocationUpdates:, YES); // iOS9
        
        
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
		
        _updating       = NO;
        _significant    = NO;
        
        if ([LocationAuthorization locationAuthorizedOrNotDeterminedShowMsg:NO backgroundRequired:YES])
        {
            [self startUpdatingLocation];
        }
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

- (void)setStop:(NSString *)stopId loc:(CLLocation *)loc desc:(NSString *)desc
{
	self.desc = desc;
	self.stopId = stopId;
	
    self.destination = loc;
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

-(void)delayedDelete:(id)unused
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
        

    NSDictionary *dict = @{
                           kDataDictLoc      : newLocation,
                           kDataDictState    : @(self.alarmState),
                           kDataDictAppState : self.appState };
    
    AlarmLocationNeeded previousState = self.alarmState;
	
	[self.dataReceived addObject:dict];
#endif	
    
    DEBUG_LOGO(newLocation);
	
	double becomeAccurate = [UserPrefs sharedInstance].useGpsWithin;
	
	
	
	if (newLocation.timestamp.timeIntervalSinceNow < -5*60 || self.alarmState == AlarmFired)
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
		[self alert:[NSString stringWithFormat:NSLocalizedString(@"You are within %@ of %@", @"gives a distance to a stop"), kUserDistanceProximity, self.desc]
		   fireDate:nil
			 button:NSLocalizedString(@"Show map", @"map alert button text")
           userInfo:@{
                      kStopIdNotification       : self.stopId,
                      kStopMapDescription       : self.desc,
                      kStopMapLat               : @(self.destination.coordinate.latitude),
                      kStopMapLng               : @(self.destination.coordinate.longitude),
                      kCurrLocLat               : @(newLocation.coordinate.latitude),
                      kCurrLocLng               : @(newLocation.coordinate.longitude),
                      kCurrTimestamp            : [NSDateFormatter localizedStringFromDate:newLocation.timestamp
                                                                                 dateStyle:NSDateFormatterMediumStyle
                                                                                 timeStyle:NSDateFormatterLongStyle]
                }
         

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
            
            compatSetIfExists(self.locationManager, setAllowsBackgroundLocationUpdates:, NO);  // iOS9
            
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
        NSDictionary *dict2 = @{kDataDictState : @(self.alarmState)};
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
            [self alert:[NSString stringWithFormat:NSLocalizedString(@"Unable to acquire location - proximity alarm cancelled %@", @"location error with alarm name"), error.localizedDescription]
               fireDate:nil 
                 button:nil 
               userInfo:nil
           defaultSound:YES];
            
            [self deleteLocationManager];
            [self cancelTask];
            break;
        default:
            break;
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
	return (int)self.dataReceived.count;
#else
	return 0;
#endif
}

- (NSString *)internalData:(int)item
{
#ifdef DEBUG_ALARMS
	NSMutableString *str = [NSMutableString string];
    
    NSDictionary *dict = self.dataReceived[item];
    
	CLLocation *loc = dict[kDataDictLoc];
    
    if (loc!=nil)
    {
        [str appendFormat:@"%f %f\n", loc.coordinate.latitude, loc.coordinate.longitude];
        [str appendFormat:@"dist: %f\n", [self distanceFromLocation:loc]];
        [str appendFormat:@"accuracy: %f\n", loc.horizontalAccuracy];
		
		
        [str appendFormat:@"%@\n", [NSDateFormatter localizedStringFromDate:loc.timestamp
                                    dateStyle:NSDateFormatterMediumStyle
                                    timeStyle:NSDateFormatterMediumStyle]];
    }
    
    [str appendFormat:@"%@\n", dict[kDataDictAppState]];
#define CASE_ENUM_TO_STR(X)  case X: [str appendFormat:@"%s\n", #X]; break
    NSNumber *taskState = dict[kDataDictState];
    
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
        TriMetTimesAppDelegate *app = [TriMetTimesAppDelegate sharedInstance];
        MapViewController *mapPage = [MapViewController viewController];
        
        mapPage.title = NSLocalizedString(@"Stop Proximity", @"map title");
        [mapPage addPin:self];
        
        SimpleAnnotation *currentLocation = [SimpleAnnotation annotation];
        currentLocation.pinColor		= MKPinAnnotationColorPurple;
        currentLocation.pinTitle		= NSLocalizedString(@"Current Location", @"map pin text");
        currentLocation.coordinate		= self.locationManager.location.coordinate;
        currentLocation.pinSubtitle		= [NSString stringWithFormat:NSLocalizedString(@"as of %@", @"shows the date"),
                                           [NSDateFormatter localizedStringFromDate:self.locationManager.location.timestamp
                                                                          dateStyle:NSDateFormatterMediumStyle
                                                                          timeStyle:NSDateFormatterLongStyle]];
        [mapPage addPin:currentLocation];
        
        [app.rootViewController.navigationController pushViewController:mapPage animated:YES];
    }
}

- (MKPinAnnotationColor) pinColor
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
        str = NSLocalizedString(@"Near by", @"final stop is very close");
	}
	else
	{
        str = [NSString stringWithFormat:@"%@ %@", accuracy, [FormatDistance formatMetres:distance]];
    }
	
	return str;
}

- (void)showMap:(UINavigationController *)navController
{
#ifdef DEBUG_ALARMS
    MapViewController *mapPage = [MapViewController viewController];
    
    mapPage.lines = YES;
    
    mapPage.lineCoords = [NSMutableArray array];
    
    for (NSDictionary *dict in self.dataReceived)
    {
        CLLocation *loc = dict[kDataDictLoc];
        ShapeCoord *shape = [[ShapeCoord alloc] init];
        
        [shape setLatitude: loc.coordinate.latitude];
        [shape setLongitude:loc.coordinate.longitude];
        
        [mapPage.lineCoords addObject:shape];
        
        [shape release];
    }
    
    [mapPage.lineCoords addObject:[ShapeCoordEnd data]];
    
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterLongStyle];
    
    [mapPage addPin:self];
    
    SimpleAnnotation *currentLocation = [SimpleAnnotation annotation];
    currentLocation.pinColor		= MKPinAnnotationColorPurple;
    currentLocation.pinTitle		= NSLocalizedString(@"Current Location", @"map pin text");
    currentLocation.coordinate      = self.locationManager.location.coordinate;
    currentLocation.pinSubtitle		= [NSString stringWithFormat:NSLocalizedString(@"as of %@", @"shows the date"), [dateFormatter stringFromDate:self.locationManager.location.timestamp]];
    [mapPage addPin:currentLocation];
    
    [navController pushViewController:mapPage animated:YES];	
#endif
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [LocationAuthorization locationAuthorizedOrNotDeterminedShowMsg:YES backgroundRequired:YES];
}

- (UIColor *)pinTint
{
    return nil;
}

- (bool)hasBearing
{
    return NO;
}

@end


