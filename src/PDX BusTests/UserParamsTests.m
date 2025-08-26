//
//  UserParamsTests.m
//  PDX BusTests
//
//  Created by Andy Wallace on 2/22/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "../PDXBusCore/src/BlockColorInfo.h"
#import "../PDXBusCore/src/UserInfo.h"
#import "../PDXBusCore/src/UserParams.h"
#import <XCTest/XCTest.h>

#import "../PDXBusCore/src/DebugLogging.h"

#define DEBUG_LEVEL_FOR_FILE LogTestFiles

@interface UserParamsTests : XCTestCase

@end

@implementation UserParamsTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each
    // test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of
    // each test method in the class.
}

#define OBJ_CHECK(X, V)                                                        \
    params.X = V;                                                              \
    XCTAssertEqualObjects(params.X, V);                                        \
    expectedSize++;                                                            \
    XCTAssertEqual(expectedSize, params.dictionary.count);
#define OBJ_CHECK_NOT_EQUALITY(X, V)                                           \
    params.X = V;                                                              \
    expectedSize++;                                                            \
    XCTAssertEqual(expectedSize, params.dictionary.count);                     \
    (void)params.X;
#define VAL_CHECK(X, V)                                                        \
    params.X = V;                                                              \
    XCTAssertEqual(params.X, V);                                               \
    expectedSize++;                                                            \
    XCTAssertEqual(expectedSize, params.dictionary.count);

#define CHECK_EXIST(X, B)                                                      \
    XCTAssertEqual(params.X, false);                                           \
    B();                                                                       \
    XCTAssertEqual(params.X, true)

- (void)testUserParams {
    MutableUserParams *params = MutableUserParams.new;

    NSInteger expectedSize = 0;

    // Ensures each param is unique and adds to dictionary and each
    // method has been defined.
    XCTAssertEqual(expectedSize, params.dictionary.count);

    OBJ_CHECK(valChosenName, @"hello");
    OBJ_CHECK(valOriginalName, @"nope");
    OBJ_CHECK(valLocation, @"123");
    OBJ_CHECK(valTrip, @{@"trip" : @"hey"}.mutableCopy);
    OBJ_CHECK(valTripResults,
              [@"some data" dataUsingEncoding:NSUTF8StringEncoding]);
    VAL_CHECK(valDayOfWeek, 2);
    VAL_CHECK(valMorning, true);
    OBJ_CHECK(valBlock, @"1234");
    OBJ_CHECK(valDir, @"AB");
    OBJ_CHECK(valVehicleId, @"0124");
    VAL_CHECK(valLocateMode, 4);
    VAL_CHECK(valLocateDist, 5);
    VAL_CHECK(valLocateShow, 6);
    OBJ_CHECK(valRecent, @{@"recently" : @"or not"});

    DEBUG_LOG_NSString(params.mutableDictionary.description);
}

- (void)testUserInfo {
    MutableUserInfo *params = MutableUserInfo.new;

    __block NSInteger expectedSize = 0;

    // Ensures each param is unique and adds to dictionary and each
    // method has been defined.
    XCTAssertEqual(expectedSize, params.dictionary.count);

    OBJ_CHECK(valLocs, @"1,2,3,4");
    OBJ_CHECK(valXml, [@"some data" dataUsingEncoding:NSUTF8StringEncoding]);
    OBJ_CHECK(valStopId, @"123");
    OBJ_CHECK(valAlarmBlock, @"1");
    OBJ_CHECK(valAlarmDir, @"2");
    OBJ_CHECK(valStopMapDesc, @"4");

    VAL_CHECK(valMapLat, 1.1);
    VAL_CHECK(valMapLng, 1.2);

    CHECK_EXIST(existsCurLat, ^{
      VAL_CHECK(valCurLat, 1.3);
    });

    CHECK_EXIST(existsCurLng, ^{
      VAL_CHECK(valCurLng, 1.4);
    });

    OBJ_CHECK(valCurTimestamp, @"5");

    OBJ_CHECK(valDist, @"1");
    OBJ_CHECK(valMode, @"2");
    OBJ_CHECK(valShow, @"3");

    __block int methods = 0;

    [PlistParams enumerateMethods:[UserInfo class]
                           prefix:@"val"
                            block:^(SEL sel, BOOL *stop) {
                              DEBUG_LOG_NSString(NSStringFromSelector(sel));
                              methods++;
                            }];

    XCTAssertEqual(expectedSize, methods);

    DEBUG_LOG_NSString(params.mutableDictionary.description);
}

- (void)testColorBlockInfo {
    MutableBlockColorInfo *params = MutableBlockColorInfo.new;

    __block NSInteger expectedSize = 0;

    // Ensures each param is unique and adds to dictionary and each
    // method has been defined.
    XCTAssertEqual(expectedSize, params.dictionary.count);

    VAL_CHECK(valR, 0.1);
    VAL_CHECK(valG, 0.2);
    VAL_CHECK(valB, 0.3);
    VAL_CHECK(valA, 0.4);
    VAL_CHECK(valTime, 0.5);
    OBJ_CHECK(valDesc, @"desc");

    __block int methods = 0;

    [PlistParams enumerateMethods:[BlockColorInfo class]
                           prefix:@"val"
                            block:^(SEL sel, BOOL *stop) {
                              DEBUG_LOG_NSString(NSStringFromSelector(sel));
                              methods++;
                            }];

    XCTAssertEqual(expectedSize, methods);

    DEBUG_LOG_NSString(params.mutableDictionary.description);
}

@end
