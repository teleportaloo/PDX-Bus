//
//  LatLng.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/25/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface  CLLocation(Helper)

@property (readonly) CLLocationDegrees lat;
@property (readonly) CLLocationDegrees lng;

+ (instancetype)withLat:(CLLocationDegrees)lat lng:(CLLocationDegrees)lng;
+ (instancetype)fromStringsLat:(NSString*) lat lng:(NSString*)lng;

@end



