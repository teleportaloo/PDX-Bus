//
//  XMLDepartureTests.m
//  PDX BusTests
//
//  Created by Andrew Wallace on 10/4/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "../PDXBusCore/src/DebugLogging.h"
#import "../PDXBusCore/src/XMLMultipleDepartures.h"
#import "XMLTestFile.h"
#import <XCTest/XCTest.h>

@interface XMLDepartureTests : XCTestCase

@end

@implementation XMLDepartureTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each
    // test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of
    // each test method in the class.
}

- (void)test_XMLMultipleDepartures {
    // Build
    XMLMultipleDepartures *sut = [XMLMultipleDepartures xml];
    sut.queryTransformer = [XMLTestFile queryBlockWithFileForClass:@{
        @"XMLMultipleDepartures" : @"arrivals-multiple-stops"
    }];

    // Operate
    [sut getDeparturesForStopIds:@"9818, 365, 9837"];

    // Assert
    XCTAssert(sut.gotData);
    XCTAssertEqual(sut.count, 3);
    XCTAssertEqual(sut.allDetours.count, 2);
    XCTAssertEqual(sut.allRoutes.count, 2);

    XCTAssertEqual(sut[0].count, 3);
    XCTAssertEqual(sut[1].count, 4);
    XCTAssertEqual(sut[2].count, 3);

    // Stop
    XMLDepartures *xml = sut[0];
    XCTAssertEqualObjects(xml.locDesc, @"Beaverton TC MAX Station");
    XCTAssertEqualObjects(xml.locDir, @"Southbound");
    XCTAssertEqual(xml.loc.coordinate.latitude, 45.4913303686551);
    XCTAssertEqual(xml.loc.coordinate.longitude, -122.801723195359);
    XCTAssertEqualObjects(xml.stopId, @"9818");
    XCTAssert(!xml.hasError);
    // First Departure
    Departure *dep = xml[0];
    XCTAssertEqualObjects(dep.block, @"9008");
    XCTAssertEqualObjects(dep.dir, @"1");
    XCTAssertEqual(dep.status, ArrivalStatusEstimated);
    XCTAssertEqual(MS_EPOCH(dep.departureTime), 1524420435000);
    XCTAssertEqualObjects(dep.fullSign, @"MAX Blue Line to Hillsboro");
    XCTAssertEqualObjects(dep.route, @"100");
    XCTAssertEqual(MS_EPOCH(dep.scheduledTime), 1524420435000);
    XCTAssertEqualObjects(dep.shortSign, @"Blue to Hillsboro");
    XCTAssertEqualObjects(dep.stopId, @"9818");
    XCTAssert(!dep.dropOffOnly);
    XCTAssertEqual(dep.blockPositionFeet, 0);
    XCTAssertEqualObjects(dep.vehicleIds[0], @"413");
    XCTAssertEqual(dep.loadPercentage, 0);
    XCTAssertEqual(dep.minsToArrival, 0);
    XCTAssert(!dep.needToFetchStreetcarLocation);
    XCTAssertEqual(dep.nextBusMins, 0);
    XCTAssert(!dep.nextBusFeedInTriMetData);

    // Block Data
    XCTAssertEqual(MS_EPOCH(dep.blockPositionAt), 1524420381077);
    XCTAssertEqual(dep.blockPosition.coordinate.latitude, 45.4913658);
    XCTAssertEqual(dep.blockPosition.coordinate.longitude, -122.8016574);
    XCTAssertEqualObjects(dep.blockPositionDir, @"1");
    XCTAssertEqualObjects(dep.blockPositionRouteNumber, @"100");
    XCTAssertEqualObjects(dep.nextStopId, @"9818");
    XCTAssertEqualObjects(dep.blockPositionHeading, @"217");
    XCTAssert(dep.hasBlock);

    // Trip Data
    DepartureTrip *trip = dep.trips[0];
    XCTAssertEqualObjects(trip.name, @"Hatfield Government Center");
    XCTAssertEqualObjects(trip.dir, @"1");
    XCTAssertEqualObjects(trip.route, @"100");
    XCTAssertEqual(trip.distanceFeet, 118307);
    XCTAssertEqual(trip.progressFeet, 118307);
    XCTAssertEqual(MS_EPOCH(trip.startTime), 0);
    XCTAssertEqual(MS_EPOCH(trip.endTime), 0);
}

- (void)test_reportingStatus {
    XMLMultipleDepartures *sut = [XMLMultipleDepartures xml];
    sut.queryTransformer = [XMLTestFile queryBlockWithFileForClass:@{
        @"XMLMultipleDepartures" : @"arrivals-reporting-status"
    }];

    // Operate
    [sut getDeparturesForStopIds:@"9838,9821,8169,364"];

    // Assert
    XCTAssert(sut.gotData);
    XCTAssertEqual(sut.count, 4);

    XMLDepartures *canceled = sut[0];
    XMLDepartures *ok = sut[1];

    XCTAssertEqual(canceled.reportingStatus, ReportingStatusCanceled);
    XCTAssertEqual(ok.reportingStatus, ReportingStatusNone);
    XCTAssertEqual(canceled.detourSorter.detourIds.count, 1);
    XCTAssertEqual(ok.detourSorter.detourIds.count, 0);
    XCTAssertEqual(sut.allDetours.count, 15);
}

- (void)test_XMLDepartures {
    // Build
    XMLDepartures *sut = [XMLDepartures xml];
    sut.queryTransformer = [XMLTestFile queryBlockWithFileForClass:@{
        @"XMLDepartures" : @"arrivals-single-stop"
    }];

    // Operate
    [sut getDeparturesForStopId:@"9837"];

    // Assert
    XCTAssert(sut.gotData);
    XCTAssertEqual(sut.count, 2);
    XCTAssertEqual(sut.allRoutes.count, 3);
    XCTAssert(!sut.hasError);

    // Stop
    XCTAssertEqualObjects(sut.locDesc,
                          @"Fair Complex/Hillsboro Airport MAX Stn");
    XCTAssertEqualObjects(sut.locDir, @"Westbound");
    XCTAssertEqual(sut.loc.coordinate.latitude, 45.5269236271043);
    XCTAssertEqual(sut.loc.coordinate.longitude, -122.946499150393);
    XCTAssertEqualObjects(sut.stopId, @"9837");

    // First Departure
    Departure *dep = sut[0];
    XCTAssertEqualObjects(dep.block, @"9003");
    XCTAssertEqualObjects(dep.dir, @"1");
    XCTAssertEqual(dep.status, ArrivalStatusEstimated);
    XCTAssertEqual(MS_EPOCH(dep.departureTime), 1523778211000);
    XCTAssertEqualObjects(dep.fullSign, @"MAX Blue Line to Hillsboro");
    XCTAssertEqualObjects(dep.route, @"100");
    XCTAssertEqual(MS_EPOCH(dep.scheduledTime), 1523776655000);
    XCTAssertEqualObjects(dep.shortSign, @"Blue to Hillsboro");
    XCTAssertEqualObjects(dep.stopId, @"9837");
    XCTAssert(!dep.dropOffOnly);
    XCTAssertEqual(dep.blockPositionFeet, 80429);
    XCTAssertEqualObjects(dep.vehicleIds[0], @"524");
    XCTAssertEqual(dep.loadPercentage, 23);
    XCTAssertEqual(dep.minsToArrival, 31);
    XCTAssert(!dep.needToFetchStreetcarLocation);
    XCTAssertEqual(dep.nextBusMins, 0);
    XCTAssert(!dep.nextBusFeedInTriMetData);

    // Block Data
    XCTAssertEqual(MS_EPOCH(dep.blockPositionAt), 1523776263877);
    XCTAssertEqual(dep.blockPosition.coordinate.latitude, 45.520239);
    XCTAssertEqual(dep.blockPosition.coordinate.longitude, -122.6830174);
    XCTAssertEqualObjects(dep.blockPositionDir, @"1");
    XCTAssertEqualObjects(dep.blockPositionRouteNumber, @"100");
    XCTAssertEqualObjects(dep.nextStopId, @"9757");
    XCTAssertEqualObjects(dep.blockPositionHeading, @"289");
    XCTAssert(dep.hasBlock);

    // Trip Data
    DepartureTrip *trip = dep.trips[0];
    XCTAssertEqualObjects(trip.name, @"Hatfield Government Center");
    XCTAssertEqualObjects(trip.dir, @"1");
    XCTAssertEqualObjects(trip.route, @"100");
    XCTAssertEqual(trip.distanceFeet, 159579);
    XCTAssertEqual(trip.progressFeet, 79150);
    XCTAssertEqual(MS_EPOCH(trip.startTime), 0);
    XCTAssertEqual(MS_EPOCH(trip.endTime), 0);
}

- (void)test_XMLDepartures_XMLStreetcarMessages_Streetcar {
    // Build
    XMLDepartures *sut = [XMLDepartures xml];
    sut.queryTransformer = [XMLTestFile queryBlockWithFileForClass:@{
        @"XMLDepartures" : @"arrivals-with-streetcar",
        @"XMLStreetcarMessages" : @"nextbus-no-messages"
    }];

    // Operate
    [sut getDeparturesForStopId:@"8989"];

    // Assert
    XCTAssert(sut.gotData);
    XCTAssertEqual(sut.count, 5);
    XCTAssertEqual(sut.allRoutes.count, 5);
    XCTAssert(!sut.hasError);

    // Stop
    XCTAssertEqualObjects(sut.locDesc, @"NW 23rd & Marshall");
    XCTAssertEqualObjects(sut.locDir, @"Southbound");
    XCTAssertEqual(sut.loc.coordinate.latitude, 45.5306116478909);
    XCTAssertEqual(sut.loc.coordinate.longitude, -122.698688376761);
    XCTAssertEqualObjects(sut.stopId, @"8989");
    XCTAssertNil(sut.parseError);

    // First Departure
    Departure *dep = sut[1];
    XCTAssertEqualObjects(dep.block, @"76");
    XCTAssertEqualObjects(dep.dir, @"1");
    XCTAssertEqual(dep.status, ArrivalStatusEstimated);
    XCTAssertEqual(MS_EPOCH(dep.departureTime), 1602014880000);
    XCTAssertEqualObjects(dep.fullSign,
                          @"Portland Streetcar NS Line to South Waterfront");
    XCTAssertEqualObjects(dep.route, @"193");
    XCTAssertEqual(MS_EPOCH(dep.scheduledTime), 1602014880000);
    XCTAssertEqualObjects(dep.shortSign, @"NS Line to South Waterfront");
    XCTAssertEqualObjects(dep.stopId, @"8989");
    XCTAssert(!dep.dropOffOnly);
    XCTAssertEqual(dep.blockPositionFeet, 0);
    XCTAssertEqual(dep.loadPercentage, -1);
    XCTAssertEqual(dep.minsToArrival, 15);
    XCTAssert(dep.needToFetchStreetcarLocation);
    XCTAssertEqual(dep.nextBusMins, 0);
    XCTAssert(dep.nextBusFeedInTriMetData);

    // Block Data
    XCTAssert(dep.hasBlock);
}

- (void)test_XMLDepartures_errorMessage {
    // Build
    XMLDepartures *sut = [XMLDepartures xml];
    sut.queryTransformer = [XMLTestFile queryBlockWithFileForClass:@{
        @"XMLDepartures" : @"arrivals-error-message"
    }];

    // Operate
    [sut getDeparturesForStopId:@"1"];

    // Assert
    XCTAssert(sut.gotData);
    XCTAssertEqual(sut.count, 1);
    XCTAssertEqual(sut.allRoutes.count, 0);
    XCTAssert(sut.hasError);
    XCTAssertEqualObjects(sut.networkErrorMsg, nil);
    XCTAssertNil(sut.parseError);

    // Stop
    XCTAssertEqualObjects(sut.locDesc, @"Error message");
    XCTAssertEqualObjects(sut.locDir, nil);
    XCTAssertEqualObjects(sut.stopId, @"1");

    // First Departure
    Departure *dep = sut[0];
    XCTAssertEqualObjects(dep.errorMessage, @"Location id not found 1");
    XCTAssertEqual(dep.trips.count, 0);
}

@end
