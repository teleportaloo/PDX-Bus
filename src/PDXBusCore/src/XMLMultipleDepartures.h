//
//  XMLMultipleDepartures.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/21/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetXMLv2.h"
#import "XMLDepartures.h"

#define kMultipleDepsMaxStops (128)
#define kMultipleDepsBatches(X) (1 + (((int)(X)) - 1) / kMultipleDepsMaxStops)

@interface XMLMultipleDepartures : TriMetXMLv2 <XMLDepartures *>

@property(nonatomic, strong)
    NSMutableDictionary<NSString *, XMLDepartures *> *stops;

@property(nonatomic) bool nextBusFeedInTriMetData;
@property(nonatomic, copy) NSString *blockFilter;
@property(nonatomic, strong) NSDate *queryTime;
@property(nonatomic, copy) NSString *stopIds;
@property(nonatomic, strong) AllTriMetDetours *allDetours;
@property(nonatomic, strong) AllTriMetRoutes *allRoutes;
@property(nonatomic) bool reportingStatusSection;

- (BOOL)getDeparturesForStopIds:(NSString *)stopIds block:(NSString *)block;
- (BOOL)getDeparturesForStopIds:(NSString *)stopIds;
- (void)reload;
- (void)reparse:(NSMutableData *)data;

+ (NSArray<NSString *> *)batchesFromEnumerator:(id<NSFastEnumeration>)container
                                selToGetStopId:(SEL)selToGetStopId
                                           max:(NSInteger)max;
+ (instancetype)xmlWithOptions:(unsigned int)options;
+ (instancetype)xmlWithOptions:(unsigned int)options
               oneTimeDelegate:(id<TriMetXMLDelegate> _Nonnull)delegate;
+ (instancetype)xmlWithOneTimeDelegate:(id<TriMetXMLDelegate> _Nonnull)delegate
                         sharedDetours:(AllTriMetDetours *)allDetours
                          sharedRoutes:(AllTriMetRoutes *)allRoutes;

@end
