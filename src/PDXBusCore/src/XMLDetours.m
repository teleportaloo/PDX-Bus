//
//  XMLDetours.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLDetours.h"
#import "Detour.h"
#import "NSString+Helper.h"
#import "CLLocation+Helper.h"
#import "TriMetInfo.h"
#import "DebugLogging.h"
#import "NSDictionary+TriMetCaseInsensitive.h"
#import "TriMetXMLSelectors.h"

static NSString *detourURLStringV2 = @"alerts/route/%@/infolink/true/json/false";
static NSString *allDetoursURLStringV2 = @"alerts/infolink/true/json/false";

@interface XMLDetours ()

@property (nonatomic, strong) Detour *currentDetour;
@property (nonatomic, copy) NSString *route;

@end

@implementation XMLDetours

- (instancetype)init {
    if ((self = [super init])) {
        self.allRoutes = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (Route *)route:(NSString *)route desc:(NSString *)desc {
    Route *result = self.allRoutes[route];
    
    if (result == nil) {
        result = [Route data];
        result.desc = desc;
        result.route = route;
        [self.allRoutes setObject:result forKey:route];
    }
    
    return result;
}

#pragma mark Initialize parsing

- (BOOL)getDetoursForRoute:(NSString *)route {
    self.route = route;
    BOOL ret = [self startParsing:[NSString stringWithFormat:detourURLStringV2, route]];
    
    self.route = nil;
    return ret;
}

- (BOOL)getDetoursForRoutes:(NSArray<NSString *> *)routeIdArray {
    NSMutableString *routeIds = [NSString commaSeparatedStringFromStringEnumerator:routeIdArray];
    
    BOOL ret = [self startParsing:[NSString stringWithFormat:detourURLStringV2, routeIds]];
    
    self.route = nil;
    return ret;
}

- (BOOL)getDetours {
    return [self startParsing:allDetoursURLStringV2];
}

#pragma mark Parser callbacks

XML_START_ELEMENT(resultset) {
    [self initItems];
    _hasData = YES;
}

XML_START_ELEMENT(alert) {
    self.currentDetour = [Detour fromAttributeDict:XML_ATR_DICT allRoutes:self.allRoutes];
}

XML_START_ELEMENT(detour) {
    CALL_XML_START_ELEMENT(alert);
}

XML_START_ELEMENT(route) {
    NSString *rt = XML_NON_NULL_ATR_STR(@"route");
    
    if (self.route == nil || [self.route isEqualToString:rt]) {
        [self.currentDetour.routes addObject:[self route:rt desc:XML_NON_NULL_ATR_STR(@"desc")]];
    }
}

XML_START_ELEMENT(location) {
    DetourLocation *loc = [DetourLocation data];
    
    // <location id="12798" desc="SW Oak & 1st" dir="Westbound" lat="45.5204099477081" lng="-122.671968433183" passengerCode="E" no_service_flag="false"/>
    
    loc.desc = XML_NON_NULL_ATR_STR(@"desc");
    loc.stopId = XML_NON_NULL_ATR_STR(@"id");
    loc.dir = XML_NON_NULL_ATR_STR(@"dir");
    
    [loc setPassengerCodeFromString:XML_NULLABLE_ATR_STR(@"passengerCode")];
    
    loc.noServiceFlag = XML_ATR_BOOL(@"no_service_flag");
    loc.location = XML_ATR_LOCATION(@"lat", @"lng");
    
    [self.currentDetour.locations addObject:loc];
}

XML_END_ELEMENT(alert) {
    [self.items addObject:self.currentDetour];
}

XML_END_ELEMENT(detour) {
    CALL_XML_END_ELEMENT(alert);
}


@end
