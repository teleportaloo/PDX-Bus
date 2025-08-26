//
//  TripEndPoint.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripEndPoint.h"
#import "CLLocation+Helper.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"

#define kDictEndPointUseCurrentLocation @"useCurrentLocation"
#define kDictEndPointLocationDec @"locationDesc"
#define kDictEndPointAddtionalInfo @"additionalInfo"
#define kDictEndPointLocationLat @"lat"
#define kDictEndPointLocationLng @"lng"
#define kDictEndPointFromApple @"apple"

@implementation TripEndPoint

- (NSString *)toQuery:(NSString *)toOrFrom {
    NSMutableString *ret = [NSMutableString string];

    NSString *desc = self.locationDesc;

    if (desc == nil || self.coordinates != nil) {
        desc = kAcquiredLocation;
    }

    NSMutableString *ms = [NSMutableString string];

    [ms appendString:desc.fullyPercentEncodeString];

    [ms replaceOccurrencesOfString:@"/"
                        withString:@"%2F"
                           options:NSLiteralSearch
                             range:NSMakeRange(0, ms.length)];

    [ms replaceOccurrencesOfString:@"&"
                        withString:@"%26"
                           options:NSLiteralSearch
                             range:NSMakeRange(0, ms.length)];

    [ret appendFormat:@"%@Place=%@", toOrFrom, ms];

    if (self.coordinates != nil) {
        [ret appendFormat:@"&%@Coord=%@", toOrFrom,
                          COORD_TO_LNG_LAT_STR(self.coordinates.coordinate)];
    }

    return ret;
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    dict[kDictEndPointUseCurrentLocation] = @(self.useCurrentLocation);

    if (self.locationDesc != nil) {
        dict[kDictEndPointLocationDec] = self.locationDesc;
    }

    if (self.additionalInfo != nil) {
        dict[kDictEndPointAddtionalInfo] = self.additionalInfo;
    }

    if (self.coordinates != nil) {
        dict[kDictEndPointLocationLat] =
            @(self.coordinates.coordinate.latitude);
        dict[kDictEndPointLocationLng] =
            @(self.coordinates.coordinate.longitude);
    }

    return dict;
}

- (void)resetCurrentLocation {
    if (self.useCurrentLocation) {
        self.locationDesc = nil;
        self.coordinates = nil;
    }
}

- (NSNumber *)forceNSNumber:(NSObject *)obj {
    if (obj && [obj isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)obj;
    }

    return nil;
}

- (NSString *)forceNSString:(NSObject *)obj {
    if (obj && [obj isKindOfClass:[NSString class]]) {
        return (NSString *)obj;
    }

    return nil;
}

- (bool)readDictionary:(NSDictionary *)dict {
    if (dict == nil) {
        return false;
    }

    NSNumber *useCurrentLocation =
        [self forceNSNumber:dict[kDictEndPointUseCurrentLocation]];

    if (useCurrentLocation) {
        self.useCurrentLocation = useCurrentLocation.boolValue;
    } else {
        self.useCurrentLocation = false;
    }

    self.locationDesc = [self forceNSString:dict[kDictEndPointLocationDec]];
    self.additionalInfo = [self forceNSString:dict[kDictEndPointAddtionalInfo]];

    NSNumber *lat = [self forceNSNumber:dict[kDictEndPointLocationLat]];
    NSNumber *lng = [self forceNSNumber:dict[kDictEndPointLocationLng]];

    if (lat != nil && lng != nil) {
        self.coordinates = [CLLocation withLat:lat.doubleValue
                                           lng:lng.doubleValue];
    }

    return YES;
}

- (bool)equalsTripEndPoint:(TripEndPoint *)endPoint {
    return self.useCurrentLocation == endPoint.useCurrentLocation &&
           (self.useCurrentLocation ||
            (self.locationDesc == nil && endPoint.locationDesc == nil) ||
            (self.locationDesc != nil &&
             [self.locationDesc isEqualToString:endPoint.locationDesc]));
}

+ (instancetype)fromDictionary:(NSDictionary *)dict {
    id item = [[[self class] alloc] init];

    if ([item readDictionary:dict]) {
        return item;
    }

    return nil;
}

- (NSString *)displayText {
    if (self.useCurrentLocation) {
        return kAcquiredLocation;
    }

    return self.locationDesc;
}

- (NSString *)markedUpUserInputDisplayText {
    if (self.useCurrentLocation) {
        return @"#iCurrent Location (GPS)#i";
    }

    if (self.locationDesc == nil) {
        return @"#i<touch to choose location>#i";
    }

    for (int i = 0; i < self.locationDesc.length; i++) {
        unichar c = [self.locationDesc characterAtIndex:i];

        if ((c > '9' || c < '0') && c != ' ') {
            return self.locationDesc.safeEscapeForMarkUp;
        }
    }

    if (self.additionalInfo) {
        return
            [NSString stringWithFormat:@"%@ - Stop ID %@",
                                       self.additionalInfo.safeEscapeForMarkUp,
                                       self.locationDesc.safeEscapeForMarkUp];
    }

    return [NSString
        stringWithFormat:NSLocalizedString(@"Stop ID %@",
                                           @"TriMet Stop identifer <number>"),
                         self.locationDesc.safeEscapeForMarkUp];
}

@end
