//
//  WatchNearbyInterfaceController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/17/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

/* INSERT_LICENSE */

#import "WatchNearbyInterfaceController.h"
#import "StopLocations.h"
#import "DebugLogging.h"
#import "WatchInfo.h"
#import "WatchStop.h"
#import "StopNameCacheManager.h"
#import "WatchMapHelper.h"
#import "WatchArrivalsContext.h"

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


- (void)setButtonText:(NSString *)text
{
    if (self.stopTable.numberOfRows != 1 || ![[self.stopTable rowControllerAtIndex:0] isKindOfClass: [WatchInfo class]])
    {
        [self.stopTable setRowTypes:[NSArray arrayWithObjects:@"Info", nil]];
    }
    
    WatchInfo *info = [self.stopTable rowControllerAtIndex:0];
    
    info.infoText.text = text;
}

- (void)startLocating
{
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    if (status != kCLAuthorizationStatusAuthorizedAlways && status != kCLAuthorizationStatusAuthorizedWhenInUse )
    {
        [self setButtonText:@"Location Services Not Enabled"];
    }
    else
    {
        [self.locationManager startUpdatingLocation];
    
        _waitingForLocation = true;
        self.buttonText = @"Locating";
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
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)menuItemHome {
    [self popToRootController];
}

- (IBAction)doShowListAction {

    if (!_waitingForLocation && self.stops!=nil && self.stops.safeItemCount > 0)
    {
        [self pushControllerWithName:@"Stop List" context:self.stops];
    }
}

- (void)stopLocating
{
    _waitingForLocation = NO;
    
    if (self.locationManager !=nil)
    {
        [self.locationManager stopUpdatingLocation];
    }
    
}

- (NSString *)stopName:(StopDistance*)item
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
    
    [self.stopTable setNumberOfRows:self.stops.safeItemCount withRowType:@"Stop"];
    
    for (NSInteger i = 0; i < self.stopTable.numberOfRows; i++) {
        
        WatchStop *row = [self.stopTable rowControllerAtIndex:i];
        
        StopDistance *item = [self.stops itemAtIndex:i];
    
        
        row.stopName.text = [self stopName:item];
    }
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex
{
    if ([[self.stopTable rowControllerAtIndex:rowIndex] isKindOfClass: [WatchStop class]])
    {
        StopDistance *item = [self.stops itemAtIndex:rowIndex];
        [self pushControllerWithName:@"Arrivals" context:[WatchArrivalsContext contextWithLocation:item.locid distance:item.distance stopDesc:[self stopName:item]]];
    }
}

- (void)displayMap
{
    NSMutableArray *redPins = [[[NSMutableArray alloc] init] autorelease];
    
    for(int i = 0; i < self.stops.safeItemCount && i < 6; i++)
    {
        StopDistance *sd = [self.stops itemAtIndex:i];
        
        [redPins addObject:sd.location];
        
    }
    
    [WatchMapHelper displayMap:self.map purplePin:self.lastLocation redPins:redPins];    
}

-(id)backgroundTask
{
    self.stops = [[[XMLLocateStops alloc] init] autorelease];
    
    self.stops.maxToFind   = 4;
    self.stops.minDistance = kDistMile;
    self.stops.mode        = TripModeAll;
    self.stops.location    = self.lastLocation;
    
    [self.stops findNearestStops];
    
    
    return nil;
}

- (void)taskFinishedMainThread:(id)arg
{
    [self.map addAnnotation:self.lastLocation.coordinate withPinColor:WKInterfaceMapPinColorPurple];
    
    while (self.stops.safeItemCount > 10)
    {
        [self.stops.itemArray removeLastObject];
    }
    
    [self displayMap];
    
    if (self.stops.safeItemCount > 0)
    {
        [self displayStops];
    }
    else if(self.stops.gotData)
    {
        self.buttonText = @"No stops found";
    }
    else
    {
        self.buttonText = @"Network timeout";
    }
}

- (void)processLocation
{
    [self stopLocating];
    
    self.buttonText = @"Getting Stops";
    
    
    [self startBackgroundTask];    
}


- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    
    
    if ([newLocation.timestamp timeIntervalSinceNow] < MAX_AGE)
    {
        // too old!
        return;
    }
    
    DEBUG_LOG(@"Accuracy %f\n", newLocation.horizontalAccuracy);
    
    if (newLocation.horizontalAccuracy > 300)
    {
        // Not acurrate enough!
        self.buttonText = [NSString stringWithFormat:@"Getting closer %.2f ft", newLocation.horizontalAccuracy * 3.2808398950131235];
        return;
    }
    
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
            self.buttonText = @"Still locating";
            break;
        case kCLErrorDenied:
            
            [self stopLocating];
            self.buttonText = @"Denied Access";
            break;
    }
}




@end



