//
//  XMLStops.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Stop.h"
#import "TriMetXML.h"

@interface XMLStops : TriMetXML <Stop *>

@property(nonatomic, copy) NSString *direction;
@property(nonatomic, copy) NSString *routeId;
@property(nonatomic, copy) NSString *routeDescription;
@property(nonatomic, copy) NSString *afterStopId;
@property(nonatomic, copy) NSString *staticQuery;

- (BOOL)getStopsForRoute:(NSString *)route
               direction:(NSString *)dir
             description:(NSString *)desc
             cacheAction:(CacheAction)cacheAction;

- (BOOL)getStopsAfterStopId:(NSString *)stopId
                      route:(NSString *)route
                  direction:(NSString *)dir
                description:(NSString *)desc
                cacheAction:(CacheAction)cacheAction;

@end
