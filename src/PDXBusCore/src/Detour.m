//
//  Detour.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Detour.h"
#import "DebugLogging.h"
#import "TriMetXML.h"
#import "Route.h"
#import "StringHelper.h"


@implementation Detour

- (instancetype)init
{
    if (self = [super init])
    {
        self.locations = [NSMutableArray array];
    }
    
    return self;
}


- (BOOL)isEqual:(id)anObject
{
    return self.detourId.unsignedIntegerValue == ((Detour*)anObject).detourId.unsignedIntegerValue;
    // If it's an object. Otherwise use a simple comparison like self.personId == anObject.personId
}

- (NSUInteger)hash
{
    return self.detourId.unsignedIntegerValue;
}

- (NSMutableArray<NSString *> *)extractStops
{
    if (self.embeddedStops)
    {
        return self.embeddedStops;
    }
    
    self.embeddedStops = [NSMutableArray array];
    
    NSCharacterSet *numbersOrBrace = [NSCharacterSet characterSetWithCharactersInString:@"0123456789)"];
    
    NSArray<NSString*> *searchStrings = @[ @"(Stop ID",  @"( Stop ID" ];
    
    for (NSString *stopIds in searchStrings)
    {
        NSScanner *scanner      = [NSScanner scannerWithString:self.detourDesc];
        long long stop = 0;
        scanner.scanLocation = 0;
        
        while (!scanner.isAtEnd && [scanner scanUpToString:stopIds intoString:nil])
        {
            if (scanner.scanLocation + stopIds.length < self.detourDesc.length)
            {
                scanner.scanLocation += stopIds.length;
                
                while (!scanner.isAtEnd)
                {
                    [scanner scanUpToCharactersFromSet:numbersOrBrace intoString:nil];
                    
                    if (!scanner.isAtEnd)
                    {
                        if ([self.detourDesc characterAtIndex:scanner.scanLocation]==')')
                        {
                            break;
                        }
                        
                        stop = 0;
                        if ([scanner scanLongLong:&stop])
                        {
                            if (stop > 0)
                            {
                                [self.embeddedStops addObject:[NSString stringWithFormat:@"%lld", stop]];
                            }
                        }
                        else
                        {
                            break;
                        }
                    }
                }
            }
        }
    }
    
    return self.embeddedStops;
}

- (NSComparisonResult)compare:(Detour *)detour
{
    if (self.systemWideFlag && detour.systemWideFlag)
    {
        return [self.beginDate compare:detour.beginDate];
    }
    
    if (self.systemWideFlag)
    {
        return NSOrderedAscending;
    }
    
    if (detour.systemWideFlag)
    {
        return NSOrderedDescending;
    }
    
    return [self.beginDate compare:detour.beginDate];
}

+ (Detour*)fromAttributeDict:(NSDictionary *)attributeDict allRoutes:(NSMutableDictionary<NSString *, Route*> *)allRoutes
{
    Detour *result = [Detour data];
    
    NSNumber *detourId      = @(ATRINT(id));
    result.detourDesc       = [TriMetXML replaceXMLcodes:ATRSTR(desc)].stringWithTrailingSpacesRemoved.stringWithLeadingSpacesRemoved;
    result.headerText       = [TriMetXML replaceXMLcodes:ATRSTR(header_text)].stringWithTrailingSpacesRemoved.stringWithLeadingSpacesRemoved; ;
    result.infoLinkUrl      = NATRSTR(info_link_url);
    result.detourId         = detourId;
    result.systemWideFlag   = ATRBOOL(system_wide_flag);
    result.endDate          = ATRDAT(end);
    result.beginDate        = ATRDAT(begin);
    result.routes           = [NSMutableOrderedSet orderedSet];
    
    if (result.systemWideFlag)
    {
        if (result.headerText == nil || result.headerText.length == 0)
        {
            result.headerText = kSystemWideDetour;
        }
        
        Route *route  = [Route systemWide:detourId];
        route.desc = result.headerText;
        
        Route *cached = allRoutes[route.route];
        
        if (cached==nil)
        {
            allRoutes[route.route]=route;
            cached=route;
        }
        
        [result.routes addObject:cached];
    }
    else if (result.headerText.length > result.detourDesc.length /2)
    {
        result.headerText = @"";
    }
    
    return result;
}

@end
