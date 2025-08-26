//
//  XMLDetours.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLDetours.h"
#import "CLLocation+Helper.h"
#import "DebugLogging.h"
#import "Detour.h"
#import "NSDictionary+Types.h"
#import "NSString+Core.h"
#import "TriMetInfo.h"
#import "TriMetXMLSelectors.h"
#import "XMLRoutes.h"

static NSString *detourURLStringV2 = @"alerts/route/%@/infolink/true";
static NSString *detourURLLocIdStringV2 = @"alerts/locIDs/%@/infolink/true";
static NSString *allDetoursURLStringV2 = @"alerts/infolink/true";
static NSString *systemWideDetoursOnlyV2 =
    @"alerts/infolink/true/systemWideOnly/true";

@interface XMLDetours ()

@property(nonatomic, strong) Detour *currentDetour;
@property(nonatomic, copy) NSString *route;

@end

@implementation XMLDetours

- (instancetype)init {
    if ((self = [super init])) {
        self.allRoutes = [NSMutableDictionary dictionary];
    }

    return self;
}

- (bool)cacheSelectors {
    return YES;
}

#pragma mark Initialize parsing

- (BOOL)getDetoursForRoute:(NSString *)route {
    self.route = route;
    BOOL ret = [self
        startParsing:[NSString stringWithFormat:detourURLStringV2, route]];

    self.route = nil;
    return ret;
}

- (BOOL)getDetoursForRoutes:(NSArray<NSString *> *)routeIdArray {
    NSMutableString *routeIds =
        [NSString commaSeparatedStringFromStringEnumerator:routeIdArray];

    BOOL ret = [self
        startParsing:[NSString stringWithFormat:detourURLStringV2, routeIds]];

    self.route = nil;
    return ret;
}

- (BOOL)getDetoursForLocIds:(NSArray<NSString *> *)locIdArray {

    NSMutableString *locIDs =
        [NSString commaSeparatedStringFromStringEnumerator:locIdArray];

    BOOL ret =
        [self startParsing:[NSString stringWithFormat:detourURLLocIdStringV2,
                                                      locIDs]];

    self.route = nil;
    return ret;
}

- (BOOL)getDetours {
    return [self startParsing:allDetoursURLStringV2];
}

- (BOOL)getSystemWideDetours {
    return [self startParsing:systemWideDetoursOnlyV2];
}

#pragma mark Parser callbacks

XML_START_ELEMENT(resultSet) {
    [self initItems];
    _hasData = YES;
}

XML_START_ELEMENT(alert) {
    self.currentDetour = [Detour fromAttributeDict:XML_ATR_DICT
                                         allRoutes:self.allRoutes
                                          addEmoji:!self.noEmojis];
}

XML_START_ELEMENT(detour) { CALL_XML_START_ELEMENT(alert); }

XML_START_ELEMENT(route) {
    NSString *rt = XML_NON_NULL_ATR_STR(@"route");

    if (self.route == nil || [self.route isEqualToString:rt]) {

        Route *result = self.allRoutes[rt];

        if (result == nil) {
            result = [Route fromAttributeDict:XML_ATR_DICT];
            [self.allRoutes setObject:result forKey:rt];
        }

        [self.currentDetour.routes addObject:result];
    }
}

XML_START_ELEMENT(location) {
    DetourLocation *loc = [DetourLocation fromAttributeDict:XML_ATR_DICT];
    [self.currentDetour.locations addObject:loc];
}

XML_END_ELEMENT(alert) { [self.items addObject:self.currentDetour]; }

XML_END_ELEMENT(detour) { CALL_XML_END_ELEMENT(alert); }

@end
