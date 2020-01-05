//
//  GeoLocator.m
//  PDX Bus
//
//  Created by Andrew Wallace on 8/30/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "GeoLocator.h"
#import "DebugLogging.h"
#import "ReverseGeoLocator.h"
#import "CLLocation+Helper.h"
#import "UserPrefs.h"
#import <MapKit/MapKit.h>
#import "NSString+Helper.h"


@implementation GeoLocator



+ (bool)supported
{
    if ([UserPrefs sharedInstance].useAppleGeoLocator)
    {
        // This API does not work well and so is always off for now.
        Class geocoderClass = (NSClassFromString(@"MKLocalSearchRequest"));
    
        return geocoderClass != nil;
    }
    
    return NO;
}

+ (bool)addressNeedsCoords:(NSString *)address
{
    unichar c = 0;
    for (NSUInteger i=0; i < address.length; i++)
    {
        c = [address characterAtIndex:i];
        
        if (c < '0' || c > '9')
        {
            return YES;
        }
    }
    
    return NO;
}


- (NSMutableArray<TripLegEndPoint*> *)fetchCoordinates:(NSString *)address
{
    NSMutableArray<TripLegEndPoint*> * results = [NSMutableArray array];
    
    self.waitingForGeocoder = true;
    
    static MKCoordinateRegion region;
    
    // TriMet area
    const CLLocationDegrees X0 = 45.255797;
    const CLLocationDegrees X1 = 45.657207;
    const CLLocationDegrees Y0 = -123.153522;
    const CLLocationDegrees Y1 = -122.249926;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        
        CLLocationCoordinate2D triMetCenter = { (X0 + X1) / 2.0, (Y0 + Y1) / 2.0  };
        
        region.center = triMetCenter;
        region.span.latitudeDelta  = X1-X0;
        region.span.longitudeDelta = Y1-Y0;
    });
    
    
    MKLocalSearchRequest* request = [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = address;
    
    // Set the region to an associated map view's region
    request.region = region;
    
    MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
    
    [search startWithCompletionHandler:^(MKLocalSearchResponse * _Nullable response, NSError * _Nullable error) {
        if (!error)
        {
            for (MKMapItem *mapItem in response.mapItems)
            {
                MKPlacemark *p = mapItem.placemark;
                
                if (p.coordinate.latitude >= X0 &&
                    p.coordinate.latitude <= X1 &&
                    p.coordinate.longitude >= Y0 &&
                    p.coordinate.longitude <= Y1)
                {
                    DEBUG_LOG(@"Placemark %@", mapItem.placemark.description);
                    
                    TripLegEndPoint *ep = [TripLegEndPoint data];
                    
                    NSArray *lines = p.addressDictionary[@"FormattedAddressLines"];
                    NSString *addressString = [lines componentsJoinedByString:@"\n"];
                    
                    if (addressString != nil)
                    {
                        if ([p.name isEqualToString:lines.firstObject])
                        {
                            ep.displayText = addressString;
                        }
                        else
                        {
                            ep.displayText = [NSString stringWithFormat:@"%@\n%@", p.name, addressString];
                        }
                    }
                    else if (p.name != nil)
                    {
                        ep.displayText = p.name;
                    }
                    else
                    {
                        ep.displayText = address;
                    }
                    
                    ep.loc = p.location;
                    ep.xdescription = ep.displayText;
                    ep.fromAppleMaps = YES;
                    
                    [results addObject:ep];
                    
                    // None of these are used.  I left them here as a reminder
                    //@property (nonatomic, copy) NSString *xnumber;
                    //@property (nonatomic) int index;
                    //@property (nonatomic) bool thruRoute;
                    //@property (nonatomic) bool deboard;
                    //@property (nonatomic, readonly, copy) NSString *stopId;
                    //@property (nonatomic) MapPinColorValue pinColor;
                    //@property (nonatomic, readonly, copy) NSString *mapStopId;
                }
                else
                {
                    DEBUG_LOG(@"Out of bounds %@", mapItem.placemark.description);
                }
            }
        }
        
        self.error = error;
        LOG_NSERROR(error);
        self.waitingForGeocoder = FALSE;
    }];
    
    while (self.waitingForGeocoder & ![NSThread currentThread].isCancelled)
    {
        [NSThread sleepForTimeInterval:0.2];
        DEBUG_LOG(@"Waiting for Geocoder\n");
    }
    
    
    if ([NSThread currentThread].isCancelled)
    {
        [search cancel];
    }
    
    return results;
}


@end
