//
//  XMLRoutes.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLRoutes.h"
#import "NSDictionary+TriMetCaseInsensitive.h"
#import "TriMetXMLSelectors.h"

static NSString *routesURLString = @"routeConfig";
static NSString *oneRouteURLString = @"routeConfig/route/%@/dir/true";

@interface XMLRoutes ()

@property (nonatomic, strong) Route *currentRouteObject;

@end

@implementation XMLRoutes

#pragma mark Data fetchers

- (BOOL)getRoutesCacheAction:(CacheAction)cacheAction {
    return [self startParsing:routesURLString cacheAction:cacheAction];
}

- (BOOL)getDirections:(NSString *)route cacheAction:(CacheAction)cacheAction {
    return [self startParsing:[NSString stringWithFormat:oneRouteURLString, route] cacheAction:cacheAction];
}

#pragma mark Parser callbacks

#pragma mark Start Elements

XML_START_ELEMENT(resultset) {
    [self initItems];
    _hasData = YES;
}

XML_START_ELEMENT(route) {
    self.currentRouteObject = [Route data];
    
    self.currentRouteObject.route = XML_NON_NULL_ATR_STR(@"route");
    self.currentRouteObject.desc = XML_NON_NULL_ATR_STR(@"desc");
}

XML_START_ELEMENT(dir) {
    self.currentRouteObject.directions[XML_NON_NULL_ATR_STR(@"dir")] = XML_NON_NULL_ATR_STR(@"desc");
}

#pragma mark End Elements

XML_END_ELEMENT(route) {
    [self addItem:self.currentRouteObject];
    self.currentRouteObject = nil;
}

@end
