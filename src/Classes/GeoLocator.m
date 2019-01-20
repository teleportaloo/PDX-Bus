//
//  GeoLocator.m
//  PDX Bus
//
//  Created by Andrew Wallace on 8/30/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

#import "GeoLocator.h"
#import "DebugLogging.h"
#import "ReverseGeoLocator.h"
#import "CLLocation+Helper.h"

@implementation GeoLocator



+ (bool)supported
{
    // This API does not work well and so is always off for now.
   return NO;
#if 0
    Class geocoderClass = (NSClassFromString(@"CLGeocoder"));
    
    return geocoderClass != nil;
#endif
    
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


- (CLLocation *)fetchCoordinates:(NSString *)address;
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    self.waitingForGeocoder = true;
    
    
    // TriMet area
    
    CLLocationDegrees X0 = 45.255797;
    CLLocationDegrees X1 = 45.657207;
    CLLocationDegrees Y0 = -122.249926;
    CLLocationDegrees Y1 = -123.153522;


    CLLocationCoordinate2D triMetCenter = { (X0 + X1) / 2.0, (Y0 + Y1) /2.0  };
    
#if 0
    ReverseGeoLocator *locator = [[ReverseGeoLocator alloc] init];
    CLLocation *loc = [CLLocation withLat:triMetCenter.latitude lng:triMetCenter.longitude];
    [locator fetchAddress:loc];
    DEBUG_LOG(@"Middle is %@\n", locator.result);
#endif
    
    CLLocation *topLeft     = [CLLocation withLat:X0 lng:Y0];
    CLLocation *bottomRight = [CLLocation withLat:X1 lng:Y1];
    
    CLLocationDistance radius = [topLeft distanceFromLocation:bottomRight] / 2;
    
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:triMetCenter radius:radius identifier:@"TriMet Service Area"];
    
    [geocoder geocodeAddressString:address inRegion:region completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (!error)
        {
            
            for (CLPlacemark *p in placemarks)
            {
                DEBUG_LOG(@"Placemark %@", p.description);
                
                if ([region containsCoordinate:p.location.coordinate] && self.result == nil)
                {
                    self.result = p.location;
                    
                    DEBUG_LOG(@"hit %@", p.name);
                }
                
                
            }
        }
        
        self.error = error;
        
        DEBUG_LOG(@"GeoCode:  %@\n", error.description);
        self.waitingForGeocoder = FALSE;
        
    }];
    
    while (self.waitingForGeocoder & ![NSThread currentThread].isCancelled)
    {
        [NSThread sleepForTimeInterval:0.5];
        DEBUG_LOG(@"Waiting for Geocoder\n");
    }
    
    
    if ([NSThread currentThread].isCancelled)
    {
        [geocoder cancelGeocode];
    }
    
    return self.result;
}


@end
