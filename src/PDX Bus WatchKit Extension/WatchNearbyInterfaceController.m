//
//  WatchNearbyInterfaceController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/17/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchNearbyInterfaceController.h"
#import "StopLocations.h"
#import "DebugLogging.h"
#import "WatchStop.h"
#import "StopNameCacheManager.h"
#import "WatchMapHelper.h"
#import "WatchArrivalsContextNearby.h"
#import "UserFaves.h"
#import "StringHelper.h"
#import "FormatDistance.h"

#define MAX_AGE					-30.0

@interface WatchNearbyInterfaceController ()

@end

@implementation WatchNearbyInterfaceController

@synthesize locationManager = _locationManager;
@synthesize timeStamp       = _timeStamp;
@synthesize lastLocation    = _lastLocation;
@synthesize stops           = _stops;

- (void)dealloc
{
    self.locationManager.delegate	= nil;
    self.locationManager			= nil;
    self.timeStamp                  = nil;
    self.lastLocation               = nil;
    self.stops                      = nil;
    self.loadingGroup               = nil;
    self.loadingLabel               = nil;
    self.locationStatusLabel        = nil;
    self.map                        = nil;
    self.stopTable                  = nil;
    
    [super dealloc];
}

- (void)setUpLocationStatus
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    NSString *statusText = nil;
    
    switch (status)
    {
            
            // User has not yet made a choice with regards to this application
        case kCLAuthorizationStatusNotDetermined:
            statusText = @"not set up.";
            break;
            
            // This application is not authorized to use location services.  Due
            // to active restrictions on location services, the user cannot change
            // this status, and may not have personally denied authorization
        case kCLAuthorizationStatusRestricted:
            statusText = @"restricted.";
            break;
            
            // User has explicitly denied authorization for this application, or
            // location services are disabled in Settings.
        case kCLAuthorizationStatusDenied:
            statusText = @"denied";
            
            // User has granted authorization to use their location at any time,
            // including monitoring for regions, visits, or significant location changes.
        case kCLAuthorizationStatusAuthorizedAlways:
            break;
            
            // User has granted authorization to use their location only when your app
            // is visible to them (it will be made visible to them if you continue to
            // receive location updates while in the background).  Authorization to use
            // launch APIs has not been granted.
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            break;
            
    };
    
    if (statusText !=nil)
    {
        self.locationStatusLabel.text = [NSString stringWithFormat:@"Note: location services are %@. To set up location services on the iPhone, see the end of the help screen in the app.", statusText];
        self.locationStatusLabel.hidden = NO;
    }
    else
    {
        self.locationStatusLabel.hidden = YES;
    }
    
}

-(void)setLoadingText:(NSString *)text
{
    if (text == nil)
    {
        self.stopTable.hidden = NO;
        self.loadingGroup.hidden = YES;
    }
    else
    {
        self.loadingGroup.hidden = NO;
        self.stopTable.hidden = YES;
        [self.loadingLabel setText:text];
    }
}


- (void)startLocating
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    if (status != kCLAuthorizationStatusAuthorizedAlways && status != kCLAuthorizationStatusAuthorizedWhenInUse )
    {
        [self setLoadingText:@"Location Services Not Enabled"];
    }
    else
    {
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager requestLocation];
        
        _waitingForLocation = true;
        self.loadingText = @"Locating";
    }
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.map.hidden = YES;
    
    if (context != nil)
    {
        _waitingForLocation = false;
        
        self.lastLocation = context;
    
        [self processLocation];
    }
    else
    {
    
        // Configure interface objects here.
        self.locationManager = [[[CLLocationManager alloc] init] autorelease];
        self.locationManager.delegate = self;
        
        [self setUpLocationStatus];
    
        [self startLocating];
    }

}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    [self autoCommute];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)menuItemHome {
    [self popToRootController];
}

- (IBAction)menuItemCommute {
    [self forceCommute];
}

- (void)stopLocating
{
    _waitingForLocation = NO;
    
    if (self.locationManager !=nil)
    {
        [self.locationManager stopUpdatingLocation];
    }
    
}

- (NSString *)stopName:(StopDistanceData*)item
{
    NSString *dir = @"";
    
    if (item.dir !=nil)
    {
        NSString *shortDir = [StopNameCacheManager shortDirection:item.dir];
        
        if (shortDir!=nil)
        {
            
            dir = [NSString stringWithFormat:@"%@: ",shortDir];
        }
    }
    
    return [NSString stringWithFormat:@"%@%@",dir, item.desc];
}


- (void)displayStops
{
    
    [self.stopTable setNumberOfRows:self.stops.count withRowType:@"Stop"];
    
    NSMutableString *locs = [NSString commaSeparatedStringFromEnumerator:self.stops.itemArray selector:@selector(locid)];
    
    for (NSInteger i = 0; i < self.stopTable.numberOfRows; i++) {
        
        WatchStop *row = [self.stopTable rowControllerAtIndex:i];
        
        StopDistanceData *item = (StopDistanceData*)self.stops[i];
    
        row.stopName.text = [self stopName:item];
    }
    
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    info[kUserFavesChosenName] = @"Nearby";
    info[kUserFavesLocation]   = locs;
    
    [self updateUserActivity:kHandoffUserActivityBookmark userInfo:info webpageURL:nil];
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex
{
    if ([[self.stopTable rowControllerAtIndex:rowIndex] isKindOfClass: [WatchStop class]])
    {
        [[WatchArrivalsContextNearby contextFromNearbyStops:self.stops index:rowIndex] pushFrom:self];
    }
}

- (void)displayMap
{
    NSMutableArray *redPins = [NSMutableArray array];
    
    for(int i = 0; i < self.stops.count && i < 6; i++)
    {
        StopDistanceData *sd = (StopDistanceData*)self.stops[i];
        
        SimpleWatchPin *pin = [[SimpleWatchPin alloc] init];
        
        pin.simplePinColor = WKInterfaceMapPinColorRed;
        pin.simpleCoord    = sd.location.coordinate;
        
        [redPins addObject:pin];
        
        [pin release];
        
    }
    
    [WatchMapHelper displayMap:self.map purplePin:self.lastLocation otherPins:redPins];
}

-(id)backgroundTask
{
    XMLLocateStops *stops = [XMLLocateStops xml];
    
    stops.maxToFind   = 4;
    stops.minDistance = kDistMile;
    stops.mode        = TripModeAll;
    stops.location    = self.lastLocation;
    
    [stops findNearestStops];
    
    return stops;
}

- (void)taskFinishedMainThread:(id)result
{
    self.stops = (XMLLocateStops *)result;
    self.loadingText = nil;
    
    [self.map addAnnotation:self.lastLocation.coordinate withPinColor:WKInterfaceMapPinColorPurple];
    
    while (self.stops.count > 10)
    {
        [self.stops.itemArray removeLastObject];
    }
    
    [self displayMap];
    
    if (self.stops.count > 0)
    {
        [self displayStops];
    }
    else if(self.stops.gotData)
    {
        self.loadingText = @"No stops found";
    }
    else
    {
        self.loadingText = @"Network timeout";
    }
}

- (void)processLocation
{
    [self stopLocating];
    
    self.loadingText = @"Getting\nstops";
    
    
    [self startBackgroundTask];    
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations
{

    CLLocation *newLocation = locations.lastObject;
    
    if (newLocation.timestamp.timeIntervalSinceNow < MAX_AGE)
    {
        // too old!
        return;
    }
    
    DEBUG_LOG(@"Accuracy %f\n", newLocation.horizontalAccuracy);
    
    /*
    if (newLocation.horizontalAccuracy > 300)
    {
        // Not acurrate enough!
        self.buttonText = [NSString stringWithFormat:@"Getting closer %.2f ft", newLocation.horizontalAccuracy * kFeetInAMetre];
        
        [self.locationManager stopUpdatingLocation];
        [self.locationManager requestLocation];
        return;
    }
    */
    
    if (!_waitingForLocation)
    {
        return;
    }
    
    self.lastLocation = newLocation;
    self.timeStamp    = newLocation.timestamp;

    
    [self processLocation];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    if (!_waitingForLocation)
    {
        return;
    }
    switch (error.code)
    {
        default:
        case kCLErrorLocationUnknown:
            self.loadingText = @"Failed to locate. :-(";
            break;
        case kCLErrorDenied:
            
            [self stopLocating];
            self.loadingText = @"Denied Access";
            break;
    }
}




@end



