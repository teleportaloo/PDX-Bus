//
//  Route.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetInfo.h"
#import "Direction.h"
#import "Stop.h"

#define kSystemWideRouteId @"SWRID"
#define kSystemWideDetour  NSLocalizedString(@"System-wide Alert", @"heading")

@interface Route : NSObject {
}

@property (nonatomic, strong) NSMutableDictionary<NSString *, Direction *> *directions;
@property (nonatomic, readonly) bool systemWide;
@property (nonatomic, readonly) NSInteger systemWideId;

@property (nonatomic, copy) NSString *route;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic)       NSInteger routeSortOrder;
@property (nonatomic)       NSInteger routeColor;
@property (nonatomic)       NSNumber *frequentService;

- (NSComparisonResult)compare:(Route *)route2;
- (BOOL)isEqualToRoute:(Route *)route;
- (PtrConstRouteInfo)rawColor;

+ (instancetype)systemWide:(NSNumber *)detourId;

@end
