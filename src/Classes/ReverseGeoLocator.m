//
//  ReverseGeoLocator.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/2/14.
//  Copyright (c) 2014 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ReverseGeoLocator.h"

#import "DebugLogging.h"
#import "CLPlacemark+SimpleAddress.h"


@implementation ReverseGeoLocator


+ (bool)supported {
    Class geocoderClass = (NSClassFromString(@"CLGeocoder"));
    
    return geocoderClass != nil;
}

- (NSString *)addressFromPlacemark:(CLPlacemark *)placemark {
    return placemark.simpleAddress;
}

- (NSString *)fetchAddress:(CLLocation *)loc {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    self.waitingForGeocoder = true;
    
    [geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
        if (!error) {
            CLPlacemark *placemark = placemarks.lastObject;
            
            NSString *address = [self addressFromPlacemark:placemark];
            DEBUG_LOG(@"%@\n", address);
            
            if (address != nil) {
                NSMutableString *addressWithNoNewLines = [NSMutableString string];
                
                [addressWithNoNewLines appendString:address];
                
                [addressWithNoNewLines replaceOccurrencesOfString:@"\n" withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(0, addressWithNoNewLines.length)];
                
                self.result = addressWithNoNewLines;
            }
        }
        
        self.error = error;
        self.waitingForGeocoder = FALSE;
    }];
    
    while (self.waitingForGeocoder & ![NSThread currentThread].isCancelled) {
        [NSThread sleepForTimeInterval:0.25];
        DEBUG_LOG(@"Waiting for Geocoder\n");
    }
    
    if ([NSThread currentThread].isCancelled) {
        [geocoder cancelGeocode];
    }
    
    return self.result;
}

@end
