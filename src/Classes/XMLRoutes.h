//
//  XMLRoutes.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "Route.h"
#import "TriMetXML.h"


@interface XMLRoutes : TriMetXML<Route*> {
	Route *_currentRouteObject;
}

- (BOOL)getRoutesCacheAction:(CacheAction)cacheAction;
- (BOOL)getDirections:(NSString *)route cacheAction:(CacheAction)cacheAction;

@property (nonatomic, retain) Route *currentRouteObject;


@end
