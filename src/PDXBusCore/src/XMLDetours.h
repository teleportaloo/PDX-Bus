//
//  XMLDetours.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetXMLv2.h"
#import "Detour.h"
#import "Route.h"


@interface XMLDetours : TriMetXMLv2<Detour *>

@property (nonatomic, strong) AllTriMetRoutes *allRoutes;
@property (nonatomic) bool noEmojis;

- (BOOL)getDetoursForRoutes:(NSArray<NSString *> *)routeIdArray;
- (BOOL)getDetoursForRoute:(NSString *)route;
- (BOOL)getDetours;
- (BOOL)getSystemWideDetours;


@end
