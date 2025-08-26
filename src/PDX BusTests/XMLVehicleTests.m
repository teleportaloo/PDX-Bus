//
//  XMLVehicleTests.m
//  PDX BusTests
//
//  Created by Andrew Wallace on 10/7/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "../PDXBusCore/src/CLLocation+Helper.h"
#import "../PDXBusCore/src/DebugLogging.h"
#import "../PDXBusCore/src/FormatDistance.h"
#import "../PDXBusCore/src/XMLLocateVehicles.h"
#import "XMLTestFile.h"
#import <XCTest/XCTest.h>

@interface XMLVehicleTests : XCTestCase

@end

@implementation XMLVehicleTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each
    // test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of
    // each test method in the class.
}

- (void)test_XMLLocateVehicles {
    // Build
    XMLLocateVehicles *sut = [XMLLocateVehicles xml];
    sut.queryTransformer = [XMLTestFile
        queryBlockWithFileForClass:@{@"XMLLocateVehicles" : @"vehicles"}];

    // Operate
    [sut findNearestVehicles:nil
                   direction:nil
                      blocks:nil
                    vehicles:nil
                       since:nil];

    // Assert
    XCTAssert(sut.gotData);
    XCTAssertEqual(sut.count, 24);
    XCTAssertNil(sut.parseError);

    Vehicle *vehicle = sut[0];
    XCTAssertEqualObjects(vehicle.vehicleId, @"3103");
    XCTAssertEqualObjects(vehicle.type, @"bus");
    XCTAssertEqualObjects(vehicle.block, @"405");
    XCTAssertEqual(vehicle.location.coordinate.longitude, -122.67409);
    XCTAssertEqual(vehicle.location.coordinate.latitude, 45.526755);
    XCTAssertEqualObjects(vehicle.bearing, @"260");
    XCTAssertEqualObjects(vehicle.signMessageLong, @"4  Fessenden to Portland");
    XCTAssertEqual(MS_EPOCH(vehicle.locationTime), 1602123826662);
    XCTAssertEqualObjects(vehicle.signMessage, @"4  To Portland");
    XCTAssertEqualObjects(vehicle.routeNumber, @"4");
    XCTAssertEqualObjects(vehicle.direction, @"1");
    XCTAssertEqualObjects(vehicle.vehicleId, @"3103");
    XCTAssertEqualObjects(vehicle.nextStopId, @"9311");
    XCTAssertEqualObjects(vehicle.lastStopId, @"2592");
    XCTAssertEqualObjects(vehicle.garage, @"CENTER");
    XCTAssertEqual(vehicle.distance, 0);
    XCTAssertEqual(vehicle.loadPercentage, 1);
    XCTAssert(vehicle.inCongestion);
    XCTAssert(vehicle.offRoute);
    XCTAssertEqualObjects(vehicle.speedKmHr, nil);
    XCTAssertEqualObjects(vehicle.delay, @"-167");
}

@end
