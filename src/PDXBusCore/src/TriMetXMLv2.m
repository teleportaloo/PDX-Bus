//
//  TriMetXMLv2.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/17/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//

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
