//
//  ReverseGeoLocator.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/2/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ReverseGeoLocator.h"
#import "AddressBookUI/ABAddressFormatting.h"
#import "AddressBook/AddressBook.h"
#import <AddressBook/ABPerson.h>
#import "DebugLogging.h"


@implementation ReverseGeoLocator

@synthesize waitingForGeocoder = _waitingForGeocoder;
@synthesize result             = _result;

- (void)dealloc
{
    self.result = nil;
    self.error  = nil;
    
    [super dealloc];
}

+ (bool) supported
{
    Class geocoderClass = (NSClassFromString(@"CLGeocoder"));
    
    return geocoderClass != nil;
    
}

- (NSString *)addressFromPlacemark:(CLPlacemark *)placemark
{
    
    NSMutableString *address = [NSMutableString string];
    
    if (placemark.addressDictionary != nil)
    {
        // NSDictionary *dict = mapItem.placemark.addressDictionary;
        
        CFDictionaryRef dict =  (CFDictionaryRef)placemark.addressDictionary;
        
        NSString* item =  (NSString *)CFDictionaryGetValue(dict, kABPersonAddressStreetKey);
        
        if (item && item.length > 0)
        {
            DEBUG_LOG(@"%@\n", item);
            [address appendString:item];
        }
        
        item =  (NSString *)CFDictionaryGetValue(dict, kABPersonAddressCityKey);
        
        if (item && item.length > 0)
        {
            if (address.length > 0)
            {
                [address appendString:@", "];
            }
            
            DEBUG_LOG(@"%@\n", item);
            [address appendString:item];
        }
        
        item =  (NSString *)CFDictionaryGetValue(dict, kABPersonAddressStateKey);
        
        if (item && item.length > 0)
        {
            if (address.length > 0)
            {
                [address appendString:@", "];
            }
            DEBUG_LOG(@"%@\n", item);
            [address appendString:item];
        }
        return address;
    }
    
    return nil;
    
}

- (NSString *)fetchAddress:(CLLocation*)loc
{
    CLGeocoder *geocoder = [[[CLGeocoder alloc] init] autorelease];
    
    self.waitingForGeocoder = true;
    
    [geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (!error)
        {
            CLPlacemark *placemark = placemarks.lastObject;
            
            NSString *address = [self addressFromPlacemark:placemark];
            DEBUG_LOG(@"%@\n", address);
            
            if (address!=nil)
            {
                NSMutableString *addressWithNoNewLines = [NSMutableString string];
                
                [addressWithNoNewLines appendString:address];
                
                [addressWithNoNewLines replaceOccurrencesOfString:@"\n" withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(0, addressWithNoNewLines.length)];
                
                self.result = addressWithNoNewLines;
                
            }
        }
        
        self.error = error;
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
