//
//  GeoLocator.h
//  PDX Bus
//
//  Created by Andrew Wallace on 8/30/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface GeoLocator : NSObject

@property (atomic) bool waitingForGeocoder;
@property (atomic, strong) CLLocation *result;
@property (atomic, strong) NSError *error;

- (CLLocation *)fetchCoordinates:(NSString *)address;

+ (bool) supported;
+ (bool)addressNeedsCoords:(NSString *)address;

@end
