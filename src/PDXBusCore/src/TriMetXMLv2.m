//
//  TriMetXMLv2.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/17/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetXMLv2.h"

@implementation TriMetXMLv2


- (NSString*)fullAddressForQuery:(NSString *)query
{
    NSString *str = nil;
    if ([query characterAtIndex:query.length-1] == '&')
    {
        str = [NSString stringWithFormat:@"https://developer.trimet.org/ws/V2/%@appID=%@&json=false",
               query, [TriMetXML appId]];
    }
    else
    {
        str = [NSString stringWithFormat:@"https://developer.trimet.org/ws/V2/%@/appID/%@/json/false",
               query, [TriMetXML appId]];
    }
    return str;
}

@end
