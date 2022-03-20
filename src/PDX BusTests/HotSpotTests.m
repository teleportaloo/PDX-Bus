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


#define DEBUG_LEVEL_FOR_FILE kLogTests

#import <XCTest/XCTest.h>
#import "../PDXBusCore/src/TriMetInfo.h"
#import "../PDXBusCore/src/NSString+Helper.h"
#import "../Classes/XMLStops.h"
#import "../Classes/XMLRoutes.h"
#import "../Classes/RailMapView.h"
#import "../Classes/AllRailStationView.h"
#import "../Classes/RailStation.h"
#import "../PDXBusCore/src/DebugLogging.h"
#import "LinkChecker.h"


@interface HotSpotTests : XCTestCase {
}

@property (atomic, strong) LinkChecker *linkChecker;

@end

@implementation HotSpotTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.linkChecker = [LinkChecker withContext:NSSTR_FUNC];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.

    self.linkChecker = nil;
}



- (void)test_Online_HOTSPOT_Integrity {
    [RailMapView initHotspotData];
    HotSpot *hotSpots = [RailMapView hotspotRecords];
    NSDictionary<NSString *, Stop *> *allRailStops = [XMLRoutes getAllRailStops];

    XCTAssert(allRailStops.count > 0);
    
    self.linkChecker.context = NSSTR_FUNC;

    // Check that each station has a hotspot
    [allRailStops enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull route, Stop *_Nonnull stop, BOOL *_Nonnull stopLoop) {
                      RailStation *station = [AllRailStationView railstationFromStopId:stop.stopId];

                      XCTAssert(station != nil, @"StopId: %@ %@", stop.stopId, stop.desc);
                  }];

    int i = 0;

    // Check that each hotspot still has a station
    for (HotSpot *hs = hotSpots; hs->action != nil; hs++, i++) {
        switch (hs->action.firstUnichar) {
            default:
                break;

            case kLinkTypeStop: {
                RailStation *station = [RailStation fromHotSpot:hs index:i];
                bool foundNameMatch = NO;
                NSString *name = nil;
                bool mutlipleNames = NO;

                // Check wikilinks exit

                [self.linkChecker checkWikiLink:station.wikiLink];

                for (NSString *stationStopId in station.stopIdArray) {
                    Stop *stop = allRailStops[stationStopId];

                    if (stop == nil) {
                        XCTAssertNotNil(stop, @"StopId %@", stationStopId);
                    } else if (name == nil) {
                        name = stop.desc;
                    } else if (![name isEqual:stop.desc]) {
                        DEBUG_TEST_WARNING(@"TriMet mismatch too:  '%@' vs '%@'", name, stop.desc);
                        mutlipleNames = YES;
                    }

                    if (stop != nil) {
                        if (![stop.desc hasPrefix:station.station]) {
                            // Search from back to get the last space character
                            NSRange range = [station.station rangeOfString:@" " options:NSBackwardsSearch];

                            // Take the first substring: from 0 to the space character
                            NSString *removedLastWord = [station.station substringToIndex:range.location]; // @"this is a"

                            if ([stop.desc hasPrefix:removedLastWord]) {
                                foundNameMatch = YES;
                            }
                        } else {
                            foundNameMatch = YES;
                        }
                    }
                }

                // 13607 is allowed to be different, it's a weird stop with a combo name
                if (!foundNameMatch && ![station.stopIdArray[0] isEqual:@"13607"]) {
                    XCTAssert(!mutlipleNames, @"Station: %@", station.station);
                    XCTAssert(foundNameMatch, @"Station: %@", station.station);
                    XCTAssertEqualObjects(name, station.station, @"Station: %@", station.station);
                }
                
                
                // Check the transfers work both ways
                [station findTransfers];
                
                NSString *stopId;
                
                for (stopId in station.transferStopIdArray) {
                    RailStation *transfer = [AllRailStationView railstationFromStopId:stopId];
                    
                    XCTAssertNotNil(transfer, @"No station for transfer %@ in station %@", stopId, station.station);
                    
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
                    
                        XCTAssert(found, @"No opposite for transfer %@ in station %@",  stopId, station.station);
                    }
                    
                }

                break;
            }

            case kLinkTypeHttp:
                [self.linkChecker checkLink:hs->action];
                break;

            case kLinkTypeWiki:
                [self.linkChecker checkWikiLink:[hs->action substringFromIndex:2]];
                break;
        }
    }

    [self.linkChecker waitUntilDone];
}

@end
