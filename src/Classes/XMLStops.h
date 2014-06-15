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


@interface XMLStops : TriMetXML {
	Stop			*_currentStopObject;
	NSString		*_direction;
	NSString		*_routeId;
	NSString		*_routeDescription;
	NSString		*_afterStop;
}

@property (nonatomic, retain) Stop *currentStopObject;
@property (nonatomic, retain) NSString *direction;
@property (nonatomic, retain) NSString *routeId;
@property (nonatomic, retain) NSString *routeDescription;
@property (nonatomic, retain) NSString *afterStop;

- (BOOL)getStopsForRoute:(NSString *)route direction:(NSString *)dir 
			 description:(NSString *)desc parseError:(NSError **)error cacheAction:(CacheAction)cacheAction;
- (BOOL)getStopsAfterLocation:(NSString *)locid route:(NSString *)route direction:(NSString *)dir 
				  description:(NSString *)desc parseError:(NSError **)error cacheAction:(CacheAction)cacheAction;


@end
