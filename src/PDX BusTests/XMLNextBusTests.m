//
//  XMLNextBusMessagesTests.m
//  PDX BusTests
//
//  Created by Andrew Wallace on 10/6/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "../PDXBusCore/src/DebugLogging.h"
#import "../PDXBusCore/src/Vehicle.h"
#import "../PDXBusCore/src/XMLStreetcarLocations.h"
#import "../PDXBusCore/src/XMLStreetcarMessages.h"
#import "../PDXBusCore/src/XMLStreetcarPredictions.h"
#import "XMLTestFile.h"
#import <XCTest/XCTest.h>

@interface XMLNextBusMessagesTests : XCTestCase

@end

@implementation XMLNextBusMessagesTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each
    // test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of
    // each test method in the class.
}

- (void)test_XMLStreetcarMessages_noMessages {

    // Build
    XMLStreetcarMessages *sut = [XMLStreetcarMessages xml];
    sut.queryTransformer = [XMLTestFile queryBlockWithFileForClass:@{
        @"XMLStreetcarMessages" : @"nextbus-no-messages"
    }];

    // Operate
    [sut getMessages];

    // Assert
    XCTAssertNil(sut.parseError);
    XCTAssertEqual(sut.count, 0);
}

- (void)test_XMLStreetcar_messages {

    // Build
    XMLStreetcarMessages *sut = [XMLStreetcarMessages xml];
    sut.queryTransformer = [XMLTestFile queryBlockWithFileForClass:@{
        @"XMLStreetcarMessages" : @"nextbus-messages"
    }];

    // Operate
    [sut alwaysGetMessages];

    // Assert
    XCTAssertEqual(sut.count, 2);
    XCTAssertNil(sut.parseError);

    Detour *det = sut[0];

    XCTAssert(sut.gotData);
    XCTAssertEqualObjects(det.detourDesc, @"A & B Loop being served by buses.");
    XCTAssertEqualObjects(det.headerText, nil);
    XCTAssertEqualObjects(det.beginDate, nil);
    XCTAssertEqual(DETOUR_ID_STRIP_TAG(det.detourId), 6487);
    XCTAssertEqual(DETOUR_TYPE_FROM_ID(det.detourId), @"Streetcar ");
    XCTAssertEqualObjects(det.infoLinkUrl, nil);
    XCTAssertEqual(det.systemWide, FALSE);
    XCTAssertEqual(det.embeddedStops.count, 0);
    XCTAssertEqual(det.locations.count, 0);
    XCTAssertEqual(det.routes.count, 3);

    Route *route = det.routes[0];
    XCTAssertEqualObjects(route.desc, @"Portland Streetcar - B Loop");
    XCTAssertEqualObjects(route.routeId, @"195");
    XCTAssertEqual(det.routes[0].systemWide, NO);
}

- (void)test_XMLStreetcarMessages_nextbusPredictions {
    // Build
    XMLStreetcarPredictions *sut = [XMLStreetcarPredictions xml];
    sut.queryTransformer = [XMLTestFile queryBlockWithFileForClass:@{
        @"XMLStreetcarPredictions" : @"nextbus-predictions"
    }];

    // Operate
    [sut getDeparturesForStopId:@"9600"];

    // Assert
    XCTAssertEqual(sut.count, 9);
    XCTAssertNil(sut.parseError);

    XCTAssertEqualObjects(sut.nextBusRouteId, nil);
    XCTAssertEqualObjects(sut.copyright,
                          @"All data copyright Portland Streetcar 2020.");
    XCTAssertEqualObjects(sut.stopTitle, @"SW 11th & Alder");

    // First Departure
    Departure *dep = sut[0];
    XCTAssertEqualObjects(dep.block, @"77");
    XCTAssertEqualObjects(dep.dir, nil);
    XCTAssertEqual(dep.status, ArrivalStatusEstimated);
    XCTAssertEqual(MS_EPOCH(dep.departureTime), 0);
    XCTAssertEqualObjects(dep.fullSign,
                          @"NS North/South NS Line to South Waterfront");
    XCTAssertEqualObjects(dep.route, nil);
    XCTAssertEqual(MS_EPOCH(dep.scheduledTime), 0);
    XCTAssertEqualObjects(dep.shortSign,
                          @"NS North/South NS Line to South Waterfront");
    XCTAssertEqualObjects(dep.stopId, nil);
    XCTAssert(!dep.dropOffOnly);
    XCTAssertEqual(dep.blockPositionFeet, 0);
    XCTAssertEqualObjects(dep.vehicleIds, nil);
    XCTAssertEqual(dep.loadPercentage, 0);
    XCTAssertEqual(dep.minsToArrival, 0);
    XCTAssert(!dep.needToFetchStreetcarLocation);
    XCTAssertEqual(dep.nextBusMins, 1);
    XCTAssert(!dep.nextBusFeedInTriMetData);
}

- (void)test_XMLStreetcarLocations_NextBusLocations {

    // Build
    XMLStreetcarLocations *sut =
        [XMLStreetcarLocations sharedInstanceForRoute:@"195"];

    sut.queryTransformer = [XMLTestFile queryBlockWithFileForClass:@{
        @"XMLStreetcarLocations" : @"nextbus-locations"
    }];

    // Operate
    [sut getLocations];

    Vehicle *veh = sut.locations[@"SC022"];

    // Assert
    XCTAssertNil(sut.parseError);
    XCTAssertEqualObjects(veh.type, kVehicleTypeStreetcar);
    XCTAssertEqualObjects(veh.block, @"SC022");
    XCTAssertEqualObjects(veh.routeNumber, @"195");
    XCTAssertEqualWithAccuracy(
        [[NSDate date] timeIntervalSinceDate:veh.locationTime], 6, 1);
    XCTAssertEqual(veh.location.coordinate.latitude, 45.5190785);
    XCTAssertEqual(veh.location.coordinate.longitude, -122.660727);
    XCTAssertEqualObjects(veh.speedKmHr, @"8");
    XCTAssertEqualObjects(veh.bearing, @"3");
}

@end
