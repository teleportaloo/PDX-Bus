//
//  Route.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DataFactory.h"
#import "TriMetInfo.h"

#define kSystemWideRouteId @"SWRID"
#define kSystemWideDetour NSLocalizedString(@"System Wide Alert", @"heading")

@interface Route : DataFactory {
    const ROUTE_INFO* _col;
}

@property (nonatomic, strong) NSMutableDictionary<NSString*, NSString*> *directions;
@property (nonatomic, readonly) bool systemWide;
@property (nonatomic, copy) NSString *route;
@property (nonatomic, copy) NSString *desc;

- (NSComparisonResult)compare:(Route *)route2;
- (BOOL)isEqualToRoute:(Route*)route;
- (PC_ROUTE_INFO )rawColor;

+ (instancetype)systemWide:(NSNumber *)detourId;

@end
