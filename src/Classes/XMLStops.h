//
//  XMLStops.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "Stop.h"
#import "TriMetXML.h"


@interface XMLStops : TriMetXML<Stop*> 

@property (nonatomic, strong) Stop *currentStopObject;
@property (nonatomic, copy)   NSString *direction;
@property (nonatomic, copy)   NSString *routeId;
@property (nonatomic, copy)   NSString *routeDescription;
@property (nonatomic, copy)   NSString *afterStop;
@property (nonatomic, copy)   NSString *staticQuery;

- (BOOL)getStopsForRoute:(NSString *)route direction:(NSString *)dir 
             description:(NSString *)desc cacheAction:(CacheAction)cacheAction;
- (BOOL)getStopsAfterLocation:(NSString *)locid route:(NSString *)route direction:(NSString *)dir 
                  description:(NSString *)desc cacheAction:(CacheAction)cacheAction;


@end
