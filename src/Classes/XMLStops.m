//
//  XMLStops.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLStops.h"
#import "CLLocation+Helper.h"
#import "NSDictionary+Types.h"
#import "TriMetXMLSelectors.h"
#import "XMLRoutes.h"
#import <TriMetInfo.h>

static NSString *stopsURLString = @"routeConfig/route/%@/dir/%@/stops/true";

@interface XMLStops ()

@property(nonatomic, strong) Stop *currentStopObject;

@end

@implementation XMLStops

#pragma mark Data fetchers

- (BOOL)getStopsAfterStopId:(NSString *)stopId
                      route:(NSString *)route
                  direction:(NSString *)dir
                description:(NSString *)desc
                cacheAction:(CacheAction)cacheAction {
    self.routeId = route;
    self.direction = dir;
    self.routeDescription = desc;
    self.afterStopId = stopId;

    return [self
        startParsing:[NSString stringWithFormat:stopsURLString, route, dir]
         cacheAction:cacheAction];
}

- (BOOL)getStopsForRoute:(NSString *)route
               direction:(NSString *)dir
             description:(NSString *)desc
             cacheAction:(CacheAction)cacheAction {
    self.routeId = route;
    self.direction = dir;
    self.routeDescription = desc;
    self.afterStopId = nil;

    return [self
        startParsing:[NSString stringWithFormat:stopsURLString, route, dir]
         cacheAction:cacheAction];
}

#pragma mark Parser callbacks

- (NSString *)fullAddressForQuery:(NSString *)query {
    NSString *str = nil;

    if (self.staticQuery != nil) {
        str = self.staticQuery;
    } else {
        str = [super fullAddressForQuery:query];
    }

    return str;
}

XML_START_ELEMENT(resultSet) {
    [self initItems];
    _hasData = YES;
}

XML_START_ELEMENT(stop) {
    NSString *stopId = XML_NON_NULL_ATR_STR(@"locid");

    if (self.afterStopId != nil && [stopId isEqualToString:self.afterStopId]) {
        self.afterStopId = nil;
        self.currentStopObject = nil;
    } else if (self.afterStopId == nil) {
        self.currentStopObject = [Stop fromAttributeDict:XML_ATR_DICT];
    }
}

XML_END_ELEMENT(stop) {
    if (self.currentStopObject != nil) {
        [self addItem:self.currentStopObject];
        self.currentStopObject.index = self.items.count;
        self.currentStopObject = nil;
    }
}

@end
