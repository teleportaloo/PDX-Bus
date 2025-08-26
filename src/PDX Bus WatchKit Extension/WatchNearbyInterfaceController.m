//
//  WatchNearbyInterfaceController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/17/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "WatchNearbyInterfaceController.h"
#import "DebugLogging.h"
#import "FormatDistance.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"
#import "StopNameCacheManager.h"
#import "UIFont+Utility.h"
#import "UserParams.h"
#import "UserState.h"
#import "WatchArrivalsContextNearby.h"
#import "WatchMapHelper.h"
#import "WatchNearbyNamedLocationContext.h"
#import "WatchStop.h"

#define MAX_AGE -60.0

@interface WatchNearbyInterfaceController () {
    bool _waitingForLocation;
    bool _usingGps;
}

@property(nonatomic, strong) CLLocationManager *locationManager;
@property(nonatomic, strong) CLLocationManager *inaccurateLocationManager;
@property(nonatomic, strong) NSDate *timeStamp;
@property(nonatomic, strong) CLLocation *lastLocation;
@property(nonatomic, strong) XMLLocateStops *stops;
@property(nonatomic, copy) NSString *locationName;

@end

@implementation WatchNearbyInterfaceController

- (void)dealloc {
    _locationManager.delegate = nil;
    _inaccurateLocationManager.delegate = nil;
}

- (void)setUpLocationStatus {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];

    NSString *statusText = nil;

    switch (status) {
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
        // including monitoring for regions, visits, or significant location
        // changes.
    case kCLAuthorizationStatusAuthorizedAlways:
        break;

        // User has granted authorization to use their location only when your
        // app is visible to them (it will be made visible to them if you
        // continue to receive location updates while in the background).
        // Authorization to use launch APIs has not been granted.
    case kCLAuthorizationStatusAuthorizedWhenInUse:
        break;
    }

    if (statusText != nil) {
        self.locationStatusLabel.text = [NSString
            stringWithFormat:
                @"Note: location services are %@. To set up location services "
                @"on the iPhone, see the end of the help screen in the app.",
                statusText];
        self.locationStatusLabel.hidden = NO;
    } else {
        self.locationStatusLabel.hidden = YES;
    }
}

- (void)setLoadingText:(NSString *)text {
    if (text == nil) {
        self.stopTable.hidden = NO;
        self.loadingGroup.hidden = YES;
        self.menuGroup.hidden = NO;
    } else {
        self.loadingGroup.hidden = NO;

        if (_usingGps) {
            if (@available(watchOS 6.1, *)) {
                self.locatingMap.showsUserLocation = YES;
                self.locatingMap.showsUserHeading = YES;
                self.locatingMap.hidden = NO;
            } else {
                self.locatingMap.hidden = YES;
            }
        } else {
            self.locatingMap.hidden = YES;
        }

        self.stopTable.hidden = YES;
        self.menuGroup.hidden = YES;
        [self.loadingLabel setText:text];
    }
}

- (void)startLocating {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];

    if (status != kCLAuthorizationStatusAuthorizedAlways &&
        status != kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self setLoadingText:@"Location Services Not Enabled"];
    } else {
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager requestLocation];

        self.inaccurateLocationManager.desiredAccuracy =
            kCLLocationAccuracyThreeKilometers;
        [self.inaccurateLocationManager requestWhenInUseAuthorization];
        [self.inaccurateLocationManager requestLocation];

        _waitingForLocation = true;
        self.loadingText = @"Locating";
    }
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    self.map.hidden = YES;

    if ([context isKindOfClass:[WatchNearbyNamedLocationContext class]]) {
        WatchNearbyNamedLocationContext *actualContext =
            (WatchNearbyNamedLocationContext *)context;
        _waitingForLocation = false;
        _usingGps = false;

        self.lastLocation = actualContext.loc;
        self.locationName = actualContext.name;

        [self processLocation];
    } else {
        _usingGps = true;
        // Configure interface objects here.
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;

        self.inaccurateLocationManager = [[CLLocationManager alloc] init];
        self.inaccurateLocationManager.delegate = self;

        [self setUpLocationStatus];

        [self startLocating];
    }
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible
    // to user
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

- (void)stopLocating {
    _waitingForLocation = NO;

    if (self.locationManager != nil) {
        [self.locationManager stopUpdatingLocation];
    }

    if (self.inaccurateLocationManager != nil) {
        [self.inaccurateLocationManager stopUpdatingLocation];
    }
}

- (NSAttributedString *)stopName:(StopDistance *)item {
    NSString *dir = @"";

    if (item.dir != nil) {
        NSString *shortDir = [StopNameCacheManager shortDirection:item.dir];

        if (shortDir != nil) {
            dir = [NSString stringWithFormat:@"%@: ", shortDir];
        }
    }

    NSMutableString *name = [NSMutableString
        stringWithFormat:@"#G%@#Y%@#W", dir, item.desc.safeEscapeForMarkUp];

    for (Route *route in item.routes) {
        [name appendFormat:@"\n#b%@#b", route.desc];

        [route.directions enumerateKeysAndObjectsUsingBlock:^(
                              NSString *_Nonnull key, Direction *_Nonnull obj,
                              BOOL *_Nonnull stop) {
          [name appendFormat:@"\n#i%@#i", obj.desc];
        }];
    }

    return [name attributedStringFromMarkUpWithFont:
                     [UIFont monospacedDigitSystemFontOfSize:13.0]];
}

- (void)displayStops {
    [self.stopTable setNumberOfRows:self.stops.count withRowType:@"Stop"];

    NSMutableString *stopIds =
        [NSString commaSeparatedStringFromEnumerator:self.stops.items
                                            selector:@selector(stopId)];

    for (NSInteger i = 0; i < self.stopTable.numberOfRows; i++) {
        WatchStop *row = [self.stopTable rowControllerAtIndex:i];

        StopDistance *item = (StopDistance *)self.stops[i];

        row.stopName.attributedText = [self stopName:item];
    }

    MutableUserParams *info = [MutableUserParams withChosenName:@"Nearby"
                                                       location:stopIds];

    NSUserActivity *userActivity = [[NSUserActivity alloc]
        initWithActivityType:kHandoffUserActivityBookmark];
    userActivity.userInfo = info.dictionary;
    userActivity.webpageURL = nil;
    [self updateUserActivity:userActivity];
}

- (void)table:(WKInterfaceTable *)table
    didSelectRowAtIndex:(NSInteger)rowIndex {
    if ([[self.stopTable rowControllerAtIndex:rowIndex]
            isKindOfClass:[WatchStop class]]) {
        [[WatchArrivalsContextNearby contextFromNearbyStops:self.stops
                                                      index:rowIndex]
            pushFrom:self];
    }
}

- (void)displayMap {
    NSMutableArray *redPins = [NSMutableArray array];

    for (int i = 0; i < self.stops.count && i < 6; i++) {
        StopDistance *sd = (StopDistance *)self.stops[i];

        SimpleWatchPin *pin = [[SimpleWatchPin alloc] init];

        pin.simplePinColor = WKInterfaceMapPinColorRed;
        pin.simpleCoord = sd.location.coordinate;

        [redPins addObject:pin];
    }

    [WatchMapHelper displayMap:self.map
                     purplePin:nil
                     otherPins:redPins
               currentLocation:self.lastLocation];
}

- (id)backgroundTask {
    XMLLocateStops *stops = [XMLLocateStops xml];

    stops.maxToFind = 4;
    stops.minDistance = kMetresInAMile;
    stops.mode = TripModeAll;
    stops.location = self.lastLocation;
    stops.includeRoutesInStops = YES;

    [stops findNearestStops];

    return stops;
}

- (void)taskFinishedMainThread:(id)result {
    self.stops = (XMLLocateStops *)result;
    self.loadingText = nil;

    [self.map addAnnotation:self.lastLocation.coordinate
               withPinColor:WKInterfaceMapPinColorPurple];

    while (self.stops.count > 10) {
        [self.stops.items removeLastObject];
    }

    [self displayMap];

    if (self.stops.count > 0) {
        [self displayStops];
    } else if (self.stops.gotData) {
        self.loadingText = @"No stops found";
    } else {
        self.loadingText = @"Network timeout";
    }
}

- (void)processLocation {
    [self stopLocating];

    if (self.locationName) {
        self.loadingText = [NSString
            stringWithFormat:@"Getting stops near\n%@", self.locationName];
    } else {
        self.loadingText = @"Getting stops";
    }
    [self startBackgroundTask];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *newLocation = locations.lastObject;

    DEBUG_LOG(@"Accuracy %f age %f\n", newLocation.horizontalAccuracy,
              -newLocation.timestamp.timeIntervalSinceNow);

    if (@available(watchOS 6.1, *)) {
        [WatchMapHelper displayMap:self.locatingMap
                         purplePin:nil
                         otherPins:nil
                   currentLocation:newLocation];
        self.loadingText = [NSString
            stringWithFormat:@"Within %@",
                             [FormatDistance
                                 formatMetres:newLocation.horizontalAccuracy]];
    }

    if (newLocation.timestamp.timeIntervalSinceNow < MAX_AGE) {
        // too old!
        return;
    }

    /*
     if (newLocation.horizontalAccuracy > 300)
     {
     // Not acurrate enough!
     self.buttonText = [NSString stringWithFormat:@"Getting closer %.2f ft",
     newLocation.horizontalAccuracy * kFeetInAMetre];

     [self.locationManager stopUpdatingLocation];
     [self.locationManager requestLocation];
     return;
     }
     */

    if (!_waitingForLocation || newLocation.horizontalAccuracy > 65.0) {
        return;
    }

    self.lastLocation = newLocation;
    self.timeStamp = newLocation.timestamp;

    [self processLocation];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    if (!_waitingForLocation || manager != self.locationManager) {
        return;
    }

    switch (error.code) {
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

- (IBAction)swipeDown:(id)sender {
    [self popToRootController];
}

@end
