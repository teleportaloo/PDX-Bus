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
{
    bool            _waitingForGeocoder;
    CLLocation *    _result;
    NSError *       _error;
}

+ (bool) supported;
- (CLLocation *)fetchCoordinates:(NSString *)address;
+ (bool)addressNeedsCoords:(NSString *)address;


@property (atomic) bool waitingForGeocoder;
@property (atomic, retain) CLLocation *result;
@property (atomic, retain) NSError *error;

@end
