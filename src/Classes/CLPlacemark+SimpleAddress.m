//
//  CLPlacemark+SimpleAddress.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/13/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogParsing

#import "CLPlacemark+SimpleAddress.h"

#import <Contacts/Contacts.h>
#import <ContactsUI/ContactsUI.h>

@implementation CLPlacemark (SimpleAddress)

#if !TARGET_OS_MACCATALYST
#define Compat_AddressType              CLPlacemark * 
#define Compat_AddressFromPlaceMark(P)  ((CLPlacemark *)(P))
#define Compat_StreetFromAddress(A)     ((NSString *)A.thoroughfare)
#define Compat_CityFromAddress(A)       ((NSString *)A.locality)
#define Compat_StateFromAddress(A)      ((NSString *)A.administrativeArea)
#else
#define Compat_AddressType              CNPostalAddress *
#define Compat_AddressFromPlaceMark(P)  ((P).postalAddress)
#define Compat_StreetFromAddress(A)     ((NSString *)A.street)
#define Compat_CityFromAddress(A)       ((NSString *)A.city)
#define Compat_StateFromAddress(A)      ((NSString *)A.state)
#endif


- (NSString *)simpleAddress {
    NSMutableString *address = [NSMutableString string];
    
    // Rework for mac cat
    Compat_AddressType pmAddress = Compat_AddressFromPlaceMark(self);
    
    if (pmAddress != nil) {
        // NSDictionary *dict = mapItem.placemark.addressDictionary;
        
        
        NSString *item = Compat_StreetFromAddress(pmAddress);
        
        if (item && item.length > 0) {
            DEBUG_LOG(@"%@\n", item);
            [address appendString:item];
        }
        
        item = Compat_CityFromAddress(pmAddress);
        
        if (item && item.length > 0) {
            if (address.length > 0) {
                [address appendString:@", "];
            }
            
            DEBUG_LOG(@"%@\n", item);
            [address appendString:item];
        }
        
        
        item = Compat_StateFromAddress(pmAddress);
        
        if (item && item.length > 0) {
            if (address.length > 0) {
                [address appendString:@", "];
            }
            
            DEBUG_LOG(@"%@\n", item);
            [address appendString:item];
        }
        
        return address;
    }
    
    
    return @"No address found";
}

- (NSArray *)simpleAddressLines {
    NSString *address = [CNPostalAddressFormatter stringFromPostalAddress:self.postalAddress style:CNPostalAddressFormatterStyleMailingAddress];
    return [address componentsSeparatedByString:@"/n"];
}

@end
