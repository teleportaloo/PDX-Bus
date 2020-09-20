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

#define STREETCAR_DETOUR_ID_TAG     0x0
#define TRIMET_DETOUR_ID_TAG        0x1
#define DETOUR_ID_TAG_BITS          1
#define DETOUR_ID_TAG_MASK          0x1
#define STREETCAR_DETOUR_ID(X)      (((X) << DETOUR_ID_TAG_BITS) | STREETCAR_DETOUR_ID_TAG)
#define TRIMET_DETOUR_ID(X)         (((X) << DETOUR_ID_TAG_BITS) | TRIMET_DETOUR_ID_TAG)
#define DETOUR_ID_STRIP_TAG(N)      ((N).integerValue >> DETOUR_ID_TAG_BITS)
#define DETOUR_TYPE_FROM_ID(N)      (((N).integerValue & DETOUR_ID_TAG_MASK) == STREETCAR_DETOUR_ID_TAG ? @"Streetcar " : @"")

@interface Detour : DataFactory

@property (nonatomic, strong) NSMutableArray<DetourLocation *> *locations;
@property (nonatomic, strong) NSMutableSet<NSString *> *embeddedStops;
@property (nonatomic, strong) NSMutableOrderedSet<Route *> *routes;
@property (nonatomic, copy) NSString *infoLinkUrl;
@property (nonatomic, copy) NSString *detourDesc;
@property (nonatomic, copy) NSString *headerText;
@property (nonatomic, strong) NSNumber *detourId;
@property (nonatomic, strong) NSDate *beginDate;
@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic) bool systemWide;

- (NSArray<NSString *> *)extractStops;
- (NSString *)detectStops;
- (NSComparisonResult)compare:(Detour *)other;

+ (Detour *)fromAttributeDict:(NSDictionary *)attributeDict allRoutes:(NSMutableDictionary<NSString *, Route *> *)allRoutes;

@end
