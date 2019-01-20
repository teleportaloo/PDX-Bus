//
//  Detour.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DataFactory.h"
#import "DetourLocation.h"
#import "Route.h"



@interface Detour : DataFactory

@property (nonatomic, strong) NSMutableArray<DetourLocation *> *locations;
@property (nonatomic, strong) NSMutableArray<NSString *> *embeddedStops;
@property (nonatomic, strong) NSMutableOrderedSet<Route *> *routes;
@property (nonatomic,copy) NSString *infoLinkUrl;
@property (nonatomic,copy) NSString *detourDesc;
@property (nonatomic,copy) NSString *headerText;
@property (nonatomic,strong) NSNumber *detourId;
@property (nonatomic, strong) NSDate *beginDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic) bool systemWideFlag;

- (NSMutableArray<NSString *> *)extractStops;
- (NSComparisonResult)compare:(Detour *)detour;

+ (Detour *)fromAttributeDict:(NSDictionary *)attributeDict allRoutes:(NSMutableDictionary<NSString *, Route*> *)allRoutes;

@end
