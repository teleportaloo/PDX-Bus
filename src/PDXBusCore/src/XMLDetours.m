//
//  XMLDetours.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLDetours.h"
#import "Detour.h"
#import "StringHelper.h"
#import "CLLocation+Helper.h"
#import "TriMetInfo.h"
#import "DebugLogging.h"

static NSString *detourURLStringV2 = @"alerts/route/%@/infolink/true/json/false";
static NSString *allDetoursURLStringV2 = @"alerts/infolink/true/json/false";

@implementation XMLDetours

- (instancetype)init
{
    if ((self = [super init]))
    {
        self.allRoutes = [NSMutableDictionary dictionary];
    }
    
    return self;
}


- (Route *)route:(NSString *)route desc:(NSString *)desc
{
    Route *result = self.allRoutes[route];
    
    if (result == nil)
    {
        result = [Route data];
        result.desc = desc;
        result.route = route;
        [self.allRoutes setObject:result forKey:route];
    }
    
    return result;
}


#pragma mark Initialize parsing

- (BOOL)getDetoursForRoute:(NSString *)route
{    
    self.route = route;
    BOOL ret = [self startParsing:[NSString stringWithFormat: detourURLStringV2, route]];
    self.route = nil;
    return ret;
}


- (BOOL)getDetoursForRoutes:(NSArray *)routes
{    
    NSMutableString *commaSeparated = [NSString commaSeparatedStringFromEnumerator:routes selector:@selector(self)];
    
    BOOL ret = [self startParsing:[NSString stringWithFormat:detourURLStringV2, commaSeparated]];
    self.route = nil;
    return ret;
}

- (BOOL)getDetours
{    
    return [self startParsing: allDetoursURLStringV2];
}

#pragma mark Parser callbacks

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    
}

XML_START_ELEMENT(resultset)
{
    [self initItems];
    _hasData = YES;
}

XML_START_ELEMENT(alert)
{
    self.currentDetour = [Detour fromAttributeDict:attributeDict allRoutes:self.allRoutes];
}

XML_START_ELEMENT(detour)
{
    CALL_XML_START_ELEMENT(alert);
}

XML_START_ELEMENT(route)
{
    NSString *rt = ATRSTR(route);
    
    if (self.route == nil || [self.route isEqualToString:rt])
    {
        [self.currentDetour.routes addObject:[self route:rt desc:ATRSTR(desc)]];
    }
}

XML_START_ELEMENT(location)
{
    DetourLocation *loc = [DetourLocation data];
    
    // <location id="12798" desc="SW Oak & 1st" dir="Westbound" lat="45.5204099477081" lng="-122.671968433183" passengerCode="E" no_service_flag="false"/>
    
    loc.desc = ATRSTR(desc);
    loc.locid = ATRSTR(id);
    loc.dir = ATRSTR(dir);
    
    [loc setPassengerCodeFromString:NATRSTR(passengerCode)];
    
    loc.noServiceFlag = ATRBOOL(no_service_flag);
    loc.location = ATRLOC(lat,lng);
    
    [self.currentDetour.locations addObject:loc];
}

XML_END_ELEMENT(alert)
{
    [self.items addObject:self.currentDetour];
}

XML_END_ELEMENT(detour)
{
     CALL_XML_END_ELEMENT(alert);
}


@end
