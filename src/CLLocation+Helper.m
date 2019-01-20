//
//  LatLng.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/25/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//

#import "CLLocation+Helper.h"

@implementation CLLocation(PDXBus)


+ (instancetype)fromStringsLat:(NSString*) lat lng:(NSString*)lng
{
    return [[[self class] alloc] initWithLatitude:lat.doubleValue longitude:lng.doubleValue];
}

+ (instancetype)withLat:(CLLocationDegrees)lat lng:(CLLocationDegrees)lng
{
    return [[[self class] alloc] initWithLatitude:lat longitude:lng];
}

@end
