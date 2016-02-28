//
//  XMLDetours.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TriMetXML.h"


@interface XMLDetour : TriMetXML {
	NSString *_detour;
	NSString *_route;
}

@property (nonatomic, retain) NSString *detour;
@property (nonatomic, retain) NSString *route;
- (BOOL)getDetourForRoute:(NSString *)route;
- (BOOL)getDetourForRoutes:(NSArray *)routes;
- (BOOL)getDetours;


@end

