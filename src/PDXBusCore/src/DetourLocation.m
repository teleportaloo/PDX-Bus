//
//  DetourLocation.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/7/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DetourLocation.h"
#import "NSDictionary+Types.h"
#import "NSString+Core.h"
#import "TriMetXML.h"
#import "TriMetXMLSelectors.h"
#import "CLLocation+Helper.h"

@implementation DetourLocation

- (void)setPassengerCodeFromString:(NSString *)string {
    if (string == nil || string.length == 0) {
        self.passengerCode = PassengerCodeUnknown;
    } else {
        self.passengerCode = string.firstUnichar;
    }
}

+ (DetourLocation *)fromAttributeDict:(NSDictionary *)XML_ATR_DICT {
    // <location id="12798" desc="SW Oak & 1st" dir="Westbound"
    // lat="45.5204099477081" lng="-122.671968433183" passengerCode="E"
    // no_service_flag="false"/>

    DetourLocation *loc = [DetourLocation new];

    loc.desc = XML_NON_NULL_ATR_STR(@"desc");
    loc.stopId = XML_NON_NULL_ATR_STR(@"id");
    loc.dir = XML_NON_NULL_ATR_STR(@"dir");

    [loc setPassengerCodeFromString:XML_NULLABLE_ATR_STR(@"passengerCode")];

    loc.noServiceFlag = XML_ATR_BOOL_DEFAULT_FALSE(@"no_service_flag");
    loc.location = XML_ATR_LOCATION(@"lat", @"lng");

    return loc;
}

@end
