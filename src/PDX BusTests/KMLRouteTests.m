//
//  KMLRouteTests.m
//  PDX BusTests
//
//  Created by Andrew Wallace on 10/8/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "../Classes/KMLRoutes.h"
#import "../Classes/XMLRoutes.h"
#import "XMLTestFile.h"
#import <XCTest/XCTest.h>

#define DEBUG_LEVEL_FOR_FILE LogTests

@interface KMLRouteTests : XCTestCase

@end

@implementation KMLRouteTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each
    // test method in the class.
    [KMLRoutes deleteCacheFile];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of
    // each test method in the class.
    [KMLRoutes deleteCacheFile];
}

- (void)test_KMLRoutes {
    // Build
    KMLRoutes *sut = [KMLRoutes xml];

    sut.queryTransformer = [XMLTestFile
        queryBlockWithFileForClass:@{@"KMLRoutes" : @"kml-routes"}];

    // Operate
    [sut fetchNowForced:YES];

    ShapeRoutePath *path = [sut lineCoordsForRoute:@"1" direction:@"0"];

    XCTAssert(sut.keyEnumerator.allObjects.count > 0);
    XCTAssertNil(sut.parseError);
    XCTAssert(path != nil);
    XCTAssertEqual(path.route, 1);
    XCTAssertEqualObjects(path.desc, @"1 Vermont");
    XCTAssertEqualObjects(path.dirDesc, @"To Vermont & Shattuck and Maplewood");
    XCTAssertEqual(path.segments.count, 35);

    id<ShapeSegment> seg = path.segments[0];

    XCTAssertEqual(seg.count, 266);
    XCTAssertEqualWithAccuracy(seg.compact.coords[0].latitude, 45.4762299486,
                               0.0000000001);
    XCTAssertEqualWithAccuracy(seg.compact.coords[0].longitude, -122.721885142,
                               0.000000001);
}

- (void)test_Online_KMLRoutes {
    // Build
    KMLRoutes *sut = [KMLRoutes xml];

    XMLRoutes *routes = [XMLRoutes xml];
    [routes getRoutesCacheAction:TriMetXMLNoCaching];

    // Operate
    [sut fetchNowForced:YES];

    ShapeRoutePath *path = [sut lineCoordsForRoute:@"1" direction:@"0"];

    XCTAssertNil(sut.parseError);

    XCTAssert(path != nil);
    XCTAssertEqual(path.route, 1);
    XCTAssertEqualObjects(path.desc, @"1 Vermont");
    XCTAssertEqualObjects(path.dirDesc,
                          @"To Hayhurst and Maplewood via Vermont");
    XCTAssertEqual(path.segments.count, 41);

    if (path != nil) {
        id<ShapeSegment> seg = path.segments[0];

        XCTAssertEqual(seg.count, 17);
        XCTAssertEqualWithAccuracy(seg.compact.coords[0].latitude,
                                   45.4764268846, 0.0000000001);
        XCTAssertEqualWithAccuracy(seg.compact.coords[0].longitude,
                                   -122.742690184, 0.000000001);
    }

    NSSet *routesToIgnore = [NSSet setWithArray:@[ @"98" ]];

    for (Route *route in routes) {
        ShapeRoutePath *path = [sut lineCoordsForRoute:route.routeId
                                             direction:@"0"];
        if (![routesToIgnore containsObject:route.routeId]) {
            DEBUG_ASSERT_WARNING(path != nil, @"Route %@ missing- %@",
                                 route.routeId, route.desc);
        } else {
            DEBUG_TEST_WARNING(@"Route %@ has no shapes", route.routeId);
        }
        if (path != nil) {
            DEBUG_LOG(@"Route %@ has %ld segments", route.routeId,
                      (long)path.segments.count);
        }
    }
}

@end
