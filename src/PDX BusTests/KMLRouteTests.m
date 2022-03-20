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




#import <XCTest/XCTest.h>
#import "XMLTestFile.h"
#import "../Classes/KMLRoutes.h"

@interface KMLRouteTests : XCTestCase

@end

@implementation KMLRouteTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [KMLRoutes deleteCacheFile];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [KMLRoutes deleteCacheFile];
}

- (void)test_KMLRoutes {
    // Build
    KMLRoutes *sut = [KMLRoutes xml];
    
    sut.queryBlock = [XMLTestFile queryBlockWithFileForClass:@{@"KMLRoutes":@"kml-routes"}];
    
    // Operate
    [sut fetchNowForced:YES];
    
    ShapeRoutePath *path = [sut lineCoordsForRoute:@"1" direction:@"0"];
    
    XCTAssert(                  sut.keyEnumerator.allObjects.count > 0);
    XCTAssertNil(               sut.parseError);
    XCTAssert(                  path!=nil);
    XCTAssertEqual(             path.route,                         1);
    XCTAssertEqualObjects(      path.desc,                          @"1 Vermont");
    XCTAssertEqualObjects(      path.dirDesc,                       @"To Vermont & Shattuck and Maplewood");
    XCTAssertEqual(             path.segments.count,                35);
    
    id<ShapeSegment> seg = path.segments[0];
    
    XCTAssertEqual(             seg.count,                          266);
    XCTAssertEqualWithAccuracy( seg.compact.coords[0].latitude,     45.4762299486,      0.0000000001);
    XCTAssertEqualWithAccuracy( seg.compact.coords[0].longitude,     -122.721885142,    0.000000001);
}


- (void)test_Online_KMLRoutes {
    // Build
    KMLRoutes *sut = [KMLRoutes xml];
    
    // Operate
    [sut fetchNowForced:YES];
    
    ShapeRoutePath *path = [sut lineCoordsForRoute:@"1" direction:@"0"];
    
    XCTAssertNil(               sut.parseError);
    
    XCTAssert(                                                      path!=nil);
    XCTAssertEqual(             path.route,                         1);
    XCTAssertEqualObjects(      path.desc,                          @"1 Vermont");
    XCTAssertEqualObjects(      path.dirDesc,                       @"To Vermont & Shattuck and Maplewood");
    XCTAssertEqual(             path.segments.count,                35);
    
    if (path != nil)
    {
        id<ShapeSegment> seg = path.segments[0];
    
        XCTAssertEqual(             seg.count,                          266);
        XCTAssertEqualWithAccuracy( seg.compact.coords[0].latitude,     45.4762299486,      0.0000000001);
        XCTAssertEqualWithAccuracy( seg.compact.coords[0].longitude,     -122.721885142,    0.000000001);
    }
}

@end
