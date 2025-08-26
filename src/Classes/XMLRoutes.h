//
//  XMLRoutes.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Route.h"
#import "TriMetXML.h"

@interface XMLRoutes : TriMetXML <Route *>

- (BOOL)getRoutesCacheAction:(CacheAction)cacheAction;
- (BOOL)getDirections:(NSString *)route cacheAction:(CacheAction)cacheAction;
- (BOOL)getAllDirectionsCacheAction:(CacheAction)cacheAction;
- (BOOL)getStops:(NSString *)route cacheAction:(CacheAction)cacheAction;

+ (NSDictionary<NSString *, Stop *> *)getAllRailStops;
- (NSDictionary<NSString *, Stop *> *)getAllRailStops;

@end
