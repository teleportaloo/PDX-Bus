//
//  RailStation.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/4/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RailStation.h"
#import "DebugLogging.h"
#include "StationData.h"
#import "TaskDispatch.h"
#import "TriMetInfo.h"
#import "XMLStops.h"
#import "NSString+Convenience.h"

@implementation NSValue (RouteInfo)

- (PtrConstRouteInfo)PtrConstRouteInfoValue {
    return self.pointerValue;
}

@end

@interface RailStation ()

@property(nonatomic, strong) NSArray<NSString *> *stopIdArray;
@property(nonatomic, strong) NSArray<NSString *> *dirArray;

@property(nonatomic, strong) NSArray<NSString *> *transferStopIdArray;
@property(nonatomic, strong) NSArray<NSString *> *transferDirArray;
@property(nonatomic, strong) NSArray<NSString *> *transferNameArray;
@property(nonatomic, strong) NSArray<NSNumber *> *transferHotSpotIndexArray;
@property(nonatomic, strong) NSArray<NSValue *> *routeInfoWithTransfersArray;
@property(nonatomic, strong) NSArray<NSValue *> *routeInfoArray;

@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *wikiLink;
@property(nonatomic) int index;

@end

@implementation RailStation

+ (void)scannerInc:(NSScanner *)scanner {
    if (!scanner.atEnd) {
        scanner.scanLocation++;
    }
}

+ (void)nextSlash:(NSScanner *)scanner intoString:(NSString **)substr;
{
    if (!scanner.atEnd) {
        [scanner scanUpToString:@"/" intoString:substr];

        // NSLog(@"%@", *substr);
        [self scannerInc:scanner];
    }
}

- (NSString *)longDirectionFromTableName:(NSString *)dir {
    static NSDictionary *names = nil;

    if (names == nil) {
        names = @{
            @"N" : NSLocalizedString(@"Northbound", @"Train direction"),
            @"S" : NSLocalizedString(@"Southbound", @"Train direction"),
            @"E" : NSLocalizedString(@"Eastbound", @"Train direction"),
            @"W" : NSLocalizedString(@"Westbound", @"Train direction"),
            @"NE" : NSLocalizedString(@"Northeastbound", @"Train direction"),
            @"SE" : NSLocalizedString(@"Southeastbound", @"Train direction"),
            @"SW" : NSLocalizedString(@"Southwestbound", @"Train direction"),
            @"NW" : NSLocalizedString(@"Northwestbound", @"Train direction"),
            @"MAXN" : NSLocalizedString(@"MAX Northbound", @"Train direction"),
            @"MAXS" : NSLocalizedString(@"MAX Southbound", @"Train direction"),
            @"WESS" : NSLocalizedString(@"WES Southbound", @"Train direction"),
            @"WESA" :
                NSLocalizedString(@"WES Both Directions", @"Train direction"),
        };
    }

    NSString *obj = names[dir];

    if (obj == nil) {
        obj = [dir stringByRemovingPercentEncoding];
    }

    return obj;
}

+ (NSString *)nameFromHotspot:(PtrConstHotSpot)hotspot {
    NSScanner *scanner = [NSScanner scannerWithString:HS_ACTION(*hotspot)];
    NSCharacterSet *colon =
        [NSCharacterSet characterSetWithCharactersInString:@":"];

    NSString *substr;
    NSString *stationName = @"";

    [scanner scanUpToCharactersFromSet:colon intoString:&substr];

    if (substr == nil) {
        return nil;
    }

    [RailStation scannerInc:scanner];
    [RailStation nextSlash:scanner intoString:&stationName];

    return [stationName stringByRemovingPercentEncoding];
}

+ (instancetype)fromHotSpotIndex:(int)index {
    static NSCache<NSNumber *, RailStation *> *cache;
    static RailStation *dummy;
    DoOnce(^{
      cache = [[NSCache alloc] init];
      dummy = [[RailStation alloc] initDummy];
    });

    RailStation *result = [cache objectForKey:@(index)];

    if (result == nil) {
        result = [[[self class] alloc] initFromHotSpotIndex:index];

        if (result) {
            [cache setObject:result forKey:@(index)];
        } else {
            result = dummy;
            [cache setObject:dummy forKey:@(index)];
        }
    }

    if (result.name == nil) {
        return nil;
    }
    return result;
}

- (instancetype)initDummy {
    if ((self = [super init])) {
    }
    return self;
}

- (instancetype)initFromHotSpotIndex:(int)index {
    if ((self = [super init])) {
        PtrConstHotSpot hotspot = HotSpotArrays.sharedInstance.hotSpots + index;

        if (HS_TYPE(*hotspot) != kLinkTypeStop || hotspot->nVertices == 0) {
            return nil;
        }

        NSString *stationName = nil;
        NSString *wiki = nil;
        NSString *action = HS_ACTION(*hotspot);

        if (action.length < 2) {
            return nil;
        }

        NSArray *sections =
            [[action substringFromIndex:2] componentsSeparatedByString:@"/"];

        if (sections.count < 2) {
            ERROR_LOG(@"Station index %d doesn't have enough section %ld",
                      index, sections.count);
            return nil;
        }

        stationName = sections[0];
        wiki = sections[1];

        self.name = [stationName stringByRemovingPercentEncoding];
        self.wikiLink =
            (wiki.length == 0) ? nil : wiki.stringByRemovingPercentEncoding;
        NSMutableArray *stopIdArray = [NSMutableArray array];
        NSMutableArray *dirArray = [NSMutableArray array];
        NSMutableArray *transferStopIdArray = [NSMutableArray array];

        // NSString *stop = nil;
        NSString *dir = nil;
        NSString *stopId = nil;

        for (NSInteger section = 2; section < sections.count; section++) {
            NSArray *dirAndStopId =
                [sections[section] componentsSeparatedByString:@","];

            if (dirAndStopId.count < 2) {
                ERROR_LOG(
                    @"Station index %@ doesn't have enough items in stop %@",
                    stationName, sections[section]);
                continue;
            }

            dir = dirAndStopId[0];
            stopId = dirAndStopId[1];

            if ([dir isEqualToString:@"T"]) {
                [transferStopIdArray addObject:stopId];
            } else {
                [dirArray addObject:[self longDirectionFromTableName:dir]];
                [stopIdArray addObject:stopId];
            }
        }

        self.stopIdArray = stopIdArray;
        self.transferStopIdArray = transferStopIdArray;
        self.dirArray = dirArray;

        self.index = index;
    }

    return self;
}

- (void)findTransfers {
    if (self.transferStopIdArray.count != 0 && self.transferNameArray == nil) {
        NSMutableArray *transferNameArray = [NSMutableArray array];
        NSMutableArray *transferDirArray = [NSMutableArray array];
        NSMutableArray *transferHotSpotIndexArray = [NSMutableArray array];

        for (NSString *stopId in self.transferStopIdArray) {
            RailStation *station = [StationData railstationFromStopId:stopId];

            if (station != nil) {
                NSInteger i;

                bool found = NO;

                for (i = 0; i < station.stopIdArray.count; i++) {
                    if ([station.stopIdArray[i] isEqualToString:stopId]) {
                        [transferNameArray addObject:station.name];
                        [transferDirArray addObject:station.dirArray[i]];
                        [transferHotSpotIndexArray addObject:@(station.index)];
                        found = YES;
                        break;
                    }
                }

                if (!found) {
                    [transferNameArray addObject:@"unknown"];
                    [transferDirArray addObject:@"unknown"];
                    [transferHotSpotIndexArray addObject:@(0)];
                }
            }
        }

        self.transferNameArray = transferNameArray;
        self.transferDirArray = transferDirArray;
        self.transferHotSpotIndexArray = transferHotSpotIndexArray;
    }
}

- (NSString *)stringToFilter {
    return self.name;
}

- (BOOL)isEqual:(id)other {
    if (self == other) {
        return TRUE;
    }

    if ([other isKindOfClass:RailStation.class]) {
        return [self.name isEqualToString:((RailStation *)other).name];
    }

    return NO;
}

- (NSUInteger)hash {
    return self.name.hash;
}



- (NSArray<NSValue *> *)routeInfoWithTransfers {
    if (self.routeInfoWithTransfersArray == nil) {

        [self findTransfers];
        TriMetInfo_ColoredLines lines = [StationData railLines:self.index];
        NSMutableArray<NSValue *> *routeInfo = NSMutableArray.array;

        for (NSString *transferStopId in self.transferStopIdArray) {
            lines |= [StationData railLinesForStopId:transferStopId];
        }

        for (PtrConstRouteInfo info = TriMetInfoColoredLines.allLines;
             info->route_number != kNoRoute; info++) {
            if (lines & info->line_bit) {
                [routeInfo addObject:[NSValue valueWithPointer:info]];
            }
        }

        [routeInfo sortUsingComparator:^NSComparisonResult(
                       NSNumber *_Nonnull obj1, NSNumber *_Nonnull obj2) {
          return TriMetInfo_compareSortOrder(obj1.PtrConstRouteInfoValue,
                                             obj2.PtrConstRouteInfoValue);
        }];

        self.routeInfoWithTransfersArray = routeInfo;
    }
    return self.routeInfoWithTransfersArray;
}

@end
