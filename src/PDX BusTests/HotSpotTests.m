//
//  HotSpotTests.m
//  PDX BusTests
//
//  Created by Andrew Wallace on 10/10/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogTests

#define RAILSTATION_SORT

#import "../Classes/AllRailStationViewController.h"
#import "../Classes/RailMapViewController.h"
#import "../Classes/RailStation.h"
#import "../Classes/StationData.h"
#import "../Classes/XMLRoutes.h"
#import "../Classes/XMLStops.h"
#import "../PDXBusCore/src/DebugLogging.h"
#import "../PDXBusCore/src/NSString+Core.h"
#import "../PDXBusCore/src/TriMetInfo.h"
#import "LinkChecker.h"
#import <XCTest/XCTest.h>

@interface HotSpotTests : XCTestCase {
}

@property(atomic, strong) LinkChecker *linkChecker;

@end

@implementation HotSpotTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each
    // test method in the class.
    self.linkChecker = [LinkChecker withContext:NSSTR_FUNC];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of
    // each test method in the class.

    self.linkChecker = nil;
}

- (void)test_Online_HOTSPOT_Integrity {
    PtrConstHotSpot hotSpots = HotSpotArrays.sharedInstance.hotSpots;
    NSDictionary<NSString *, Stop *> *allRailStops =
        [XMLRoutes getAllRailStops];

    int nHotSpots = HotSpotArrays.sharedInstance.hotSpotCount;

    XCTAssert(nHotSpots < MAP_END);
    XCTAssert(allRailStops.count > 0);

    self.linkChecker.context = NSSTR_FUNC;

    // Check that each station has a hotspot
    [allRailStops enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull route,
                                                      Stop *_Nonnull stop,
                                                      BOOL *_Nonnull stopLoop) {
      RailStation *station = [StationData railstationFromStopId:stop.stopId];

      XCTAssert(station != nil, @"StopId: %@ %@", stop.stopId, stop.desc);
    }];

    int i = 0;

    // Check that each hotspot still has a station
    for (PtrConstHotSpot hs = hotSpots; i < nHotSpots; hs++, i++) {
        XCTAssert(hs->action != NULL);
       
        NSString *action = HS_ACTION(*hs);
        
        XCTAssert(action.length > 0);
       
        switch (HS_TYPE(*hs)) {
        default:
            break;

        case kLinkTypeStop: {
            RailStation *station = [RailStation fromHotSpotIndex:i];
            bool foundNameMatch = NO;
            NSString *name = nil;
            bool mutlipleNames = NO;

            XCTAssertNotNil(station, @"Station %d", i);

            if (station == nil) {
                continue;
            }

            [self.linkChecker checkWikiLink:station.wikiLink];

            for (NSString *stationStopId in station.stopIdArray) {
                Stop *stop = allRailStops[stationStopId];

                if (stop == nil) {
                    XCTAssertNotNil(stop, @"StopId %@", stationStopId);
                } else if (name == nil) {
                    name = stop.desc;
                } else if (![name isEqual:stop.desc]) {
                    DEBUG_TEST_WARNING(@"TriMet mismatch too:  '%@' vs '%@'",
                                       name, stop.desc);
                    mutlipleNames = YES;
                }

                if (stop != nil) {
                    if (![stop.desc hasPrefix:station.name]) {
                        // Search from back to get the last space character
                        NSRange range =
                            [station.name rangeOfString:@" "
                                                options:NSBackwardsSearch];

                        // Take the first substring: from 0 to the space
                        // character
                        NSString *removedLastWord = [station.name
                            substringToIndex:range.location]; // @"this is a"

                        if ([stop.desc hasPrefix:removedLastWord]) {
                            foundNameMatch = YES;
                        }
                    } else {
                        foundNameMatch = YES;
                    }
                }
            }

            // 13607 is allowed to be different, it's a weird stop with a combo
            // name
            if (!foundNameMatch && ![station.stopIdArray[0] isEqual:@"13607"]) {
                XCTAssert(!mutlipleNames, @"Station: %@", station.name);
                XCTAssert(foundNameMatch, @"Station: %@", station.name);
                XCTAssertEqualObjects(name, station.name, @"Station: %@",
                                      station.name);
            }

            // Check the transfers work both ways
            [station findTransfers];

            NSString *stopId;

            for (stopId in station.transferStopIdArray) {
                RailStation *transfer =
                    [StationData railstationFromStopId:stopId];

                XCTAssertNotNil(transfer,
                                @"No station for transfer %@ in station %@",
                                stopId, station.name);

                if (transfer != nil) {
                    bool found = NO;
                    [transfer findTransfers];

                    for (NSString *opposite in transfer.transferStopIdArray) {

                        for (NSString *here in station.stopIdArray) {
                            if ([opposite isEqualToString:here]) {
                                found = YES;
                                break;
                            }
                        }

                        if (found) {
                            break;
                        }
                    }

                    XCTAssert(found,
                              @"No opposite for transfer %@ in station %@",
                              stopId, station.name);
                }
            }

            break;
        }

        case kLinkTypeHttp:
            [self.linkChecker checkLink:action];
            break;

        case kLinkTypeWiki:
            [self.linkChecker checkWikiLink:[action substringFromIndex:2]];
            break;
        }
    }

    [self.linkChecker waitUntilDone];
}

@end
