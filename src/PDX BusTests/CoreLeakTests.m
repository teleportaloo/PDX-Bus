//
//  CoreLeakTests.m
//  PDX BusTests
//
//  Created by Andy Wallace on 9/22/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "../PDXBusCore/src/SharedFile.h"
#import <XCTest/XCTest.h>

@interface CoreLeakTests : XCTestCase

@end

@implementation CoreLeakTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each
    // test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of
    // each test method in the class.
}

- (void)testDeepCopy {
    // Tests if the deep copy leaks
    NSURL *myURL =
        [[NSBundle bundleForClass:[self class]] URLForResource:@"test-dict"
                                                 withExtension:@"plist"];

    NSMutableDictionary *dict =
        [NSMutableDictionary dictionaryWithContentsOfURL:myURL];
    NSDictionary *deep = [dict deepCopy];
    __weak NSDictionary *weakDeep = deep;
    [self addTeardownBlock:^{
      XCTAssertNil(weakDeep, @"Weak Copy is expected to be nil");
    }];
}

@end
