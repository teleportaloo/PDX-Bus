//
//  XMLDetours.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TriMetXML.h"
#import "Detour.h"


@interface XMLDetours : TriMetXML<Detour*> {
	NSString *_detour;
	NSString *_route;
}

@property (nonatomic, copy)   NSString *detour;
@property (nonatomic, copy)   NSString *route;
- (BOOL)getDetoursForRoute:(NSString *)route;
- (BOOL)getDetoursForRoutes:(NSArray *)routes;
- (BOOL)getDetours;


@end

