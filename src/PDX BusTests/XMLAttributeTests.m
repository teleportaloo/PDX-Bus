//
//  XMLAttributeTests.m
//  PDX BusTests
//
//  Created by Andrew Wallace on 10/3/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogTests

#import "../PDXBusCore/src/CLLocation+Helper.h"
#import "../PDXBusCore/src/DebugLogging.h"
#import "../PDXBusCore/src/NSDictionary+Types.h"
#import "../PDXBusCore/src/TriMetXMLSelectors.h"
#import "XMLAttributeTester.h"
#import "XMLTestFile.h"
#import <XCTest/XCTest.h>

#define FORMAT_STR(X) [NSString stringWithFormat:@"%@", (X)]
#define FORMAT_PTR(X) [NSString stringWithFormat:@"%p", (X)]
#define FORMAT_LLD(X) [NSString stringWithFormat:@"%lld", (long long)(X)]

@interface XMLAttributeTests : XCTestCase

@end

@implementation XMLAttributeTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each
    // test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of
    // each test method in the class.
}

- (void)test_TriMetXML_blank {
    // Build
    XMLTestFile *xmlFile = [XMLTestFile new];
    XMLAttributeTester *tester = [XMLAttributeTester xml];

    tester.action = ^(XmlAttributes *attributeDict, XMLAttributeTester *xml) {
    };

    // Operate
    [tester startParsing:xmlFile.makeURLstring];

    // Assert
    XCTAssert(!tester.gotData);
    XCTAssert(tester.count == 0);
    XCTAssert(tester.parseError.code == 1);
}

- (void)test_TriMetXML_empty {
    // Build
    XMLTestFile *xmlFile = [XMLTestFile new];
    [xmlFile.xml appendString:@"        "];
    XMLAttributeTester *tester = [XMLAttributeTester xml];

    tester.action = ^(XmlAttributes *attributeDict, XMLAttributeTester *xml) {
    };

    // Operate
    [tester startParsing:xmlFile.makeURLstring];

    // Assert
    XCTAssert(!tester.gotData);
    XCTAssert(tester.count == 0);
    XCTAssert(tester.parseError.code == 111);
}

- (void)test_TriMetXML_queryTime {
    // Build
    XMLAttributeTester<NSString *> *tester = [XMLAttributeTester xml];

    XMLTestFile *xmlFile = [XMLTestFile new];

    NSDate *date = [NSDate date];

    [xmlFile addHeaderTag:date];
    [xmlFile closeHeaderTag];

    // Operate
    [tester startParsing:xmlFile.makeURLstring];

    // Assert
    XCTAssert(tester.gotData);
    XCTAssertEqualWithAccuracy(tester.queryTime.timeIntervalSince1970,
                               date.timeIntervalSince1970, 0.001);
    XCTAssertNil(tester.parseError);
}

- (void)test_TriMetXML_XML_ATR_DATE {
    // Build
    XMLTestFile *xmlFile =
        [XMLTestFile fileWithOneTag:XML_TEST_ATTRIBUTE_TAG
                         attributes:@[ @[ @"item", @"56000" ] ]];
    XMLAttributeTester *tester = [XMLAttributeTester xml];

    tester.action = ^(XmlAttributes *attributeDict, XMLAttributeTester *xml) {
      [xml.items addObject:XML_ATR_DATE(@"item")];
      [xml.items addObject:FORMAT_PTR(XML_ATR_DATE(@"item2"))];
    };

    // Operate
    [tester startParsing:xmlFile.makeURLstring];

    // Assert
    XCTAssert(tester.gotData);
    XCTAssertEqual(tester.count, 2);

    XCTAssertEqualObjects(tester.nextItem,
                          [NSDate dateWithTimeIntervalSince1970:56]);
    XCTAssertEqualObjects(tester.nextItem, @"0x0");
    XCTAssertNil(tester.parseError);
}

- (void)test_TriMetXML_XML_XML_ATR_INT {
    // Build
    XMLTestFile *xmlFile = [XMLTestFile fileWithOneTag:XML_TEST_ATTRIBUTE_TAG
                                            attributes:@[ @[ @"item", @"1" ] ]];
    XMLAttributeTester<NSString *> *tester = [XMLAttributeTester xml];

    tester.action = ^(XmlAttributes *attributeDict, XMLAttributeTester *xml) {
      [xml.items addObject:FORMAT_LLD(XML_ATR_INT(@"item"))];
      [xml.items addObject:FORMAT_LLD(XML_ATR_INT(@"missing"))];
    };

    // Operate
    [tester startParsing:xmlFile.makeURLstring];

    // Assert
    XCTAssert(tester.gotData);
    XCTAssertEqual(tester.count, 2);

    XCTAssertEqualObjects(tester.nextItem, @"1");
    XCTAssertEqualObjects(tester.nextItem, @"0");
    XCTAssertNil(tester.parseError);
}

- (void)test_TriMetXML_XML_ATR_INT_OR_MISSING {
    // Build
    XMLTestFile *xmlFile = [XMLTestFile fileWithOneTag:XML_TEST_ATTRIBUTE_TAG
                                            attributes:@[ @[ @"item", @"1" ] ]];
    XMLAttributeTester<NSString *> *tester = [XMLAttributeTester xml];

    tester.action = ^(XmlAttributes *attributeDict, XMLAttributeTester *xml) {
      [xml.items addObject:FORMAT_LLD(XML_ATR_INT_OR_MISSING(@"item", -2))];
      [xml.items addObject:FORMAT_LLD(XML_ATR_INT_OR_MISSING(@"missing", -2))];
    };

    // Operate

    [tester startParsing:xmlFile.makeURLstring];

    // Assert
    XCTAssert(tester.gotData);
    XCTAssertEqual(tester.count, 2);

    XCTAssertEqualObjects(tester.nextItem, @"1");
    XCTAssertEqualObjects(tester.nextItem, @"-2");
    XCTAssertNil(tester.parseError);
}

- (void)test_TriMetXML_XML_NON_NULL_ATR_STR {
    // Build
    XMLTestFile *xmlFile =
        [XMLTestFile fileWithOneTag:XML_TEST_ATTRIBUTE_TAG
                         attributes:@[ @[ @"item", @"hello" ] ]];
    XMLAttributeTester<NSString *> *tester = [XMLAttributeTester xml];

    tester.action = ^(XmlAttributes *attributeDict, XMLAttributeTester *xml) {
      [xml.items addObject:XML_NON_NULL_ATR_STR(@"item")];
      [xml.items addObject:XML_NON_NULL_ATR_STR(@"item2")];
    };

    // Operate
    [tester startParsing:xmlFile.makeURLstring];

    // Assert
    XCTAssert(tester.gotData);
    XCTAssertEqual(tester.count, 2);

    XCTAssertEqualObjects(tester.nextItem, @"hello");
    XCTAssertEqualObjects(tester.nextItem, @"?");
    XCTAssertNil(tester.parseError);
}

- (void)test_TriMetXML_XML_NULLABLE_ATR_STR {
    // Build
    XMLTestFile *xmlFile =
        [XMLTestFile fileWithOneTag:XML_TEST_ATTRIBUTE_TAG
                         attributes:@[ @[ @"item", @"hello" ] ]];
    XMLAttributeTester<NSString *> *tester = [XMLAttributeTester xml];

    tester.action = ^(XmlAttributes *attributeDict, XMLAttributeTester *xml) {
      [xml.items addObject:XML_NULLABLE_ATR_STR(@"item")];
      [xml.items addObject:FORMAT_STR(XML_NULLABLE_ATR_STR(@"item2"))];
    };

    // Operate
    [tester startParsing:xmlFile.makeURLstring];

    // Assert
    XCTAssert(tester.gotData);
    XCTAssertEqual(tester.count, 2);

    XCTAssertEqualObjects(tester.nextItem, @"hello");
    XCTAssertEqualObjects(tester.nextItem, @"(null)");
    XCTAssertNil(tester.parseError);
}

- (void)test_TriMet_XML_XML_NULLABLE_ATR_NUM {
    // Build
    XMLTestFile *xmlFile =
        [XMLTestFile fileWithOneTag:XML_TEST_ATTRIBUTE_TAG
                         attributes:@[ @[ @"item", @"456" ] ]];
    XMLAttributeTester *tester = [XMLAttributeTester xml];

    tester.action = ^(XmlAttributes *attributeDict, XMLAttributeTester *xml) {
      [xml.items addObject:XML_NULLABLE_ATR_NUM(@"item")];
      [xml.items addObject:FORMAT_STR(XML_NULLABLE_ATR_NUM(@"missing"))];
    };

    // Operate
    [tester startParsing:xmlFile.makeURLstring];

    // Assert
    XCTAssert(tester.gotData);
    XCTAssertEqual(tester.count, 2);

    XCTAssertEqualObjects(tester.nextItem, @(456));
    XCTAssertEqualObjects(tester.nextItem, @"(null)");
    XCTAssertNil(tester.parseError);
}

- (void)test_TriMetXML_XML_ATR_TIME {
    // Build
    XMLTestFile *xmlFile =
        [XMLTestFile fileWithOneTag:XML_TEST_ATTRIBUTE_TAG
                         attributes:@[ @[ @"item", @"1234567890" ] ]];
    XMLAttributeTester<NSString *> *tester = [XMLAttributeTester xml];

    tester.action = ^(XmlAttributes *attributeDict, XMLAttributeTester *xml) {
      [xml.items addObject:FORMAT_LLD(XML_ATR_TIME(@"item"))];
      [xml.items addObject:FORMAT_LLD(XML_ATR_TIME(@"missing"))];
    };

    // Operate
    [tester startParsing:xmlFile.makeURLstring];

    // Assert
    XCTAssert(tester.gotData);
    XCTAssertEqual(tester.count, 2);

    XCTAssertEqualObjects(tester.nextItem, @"1234567890");
    XCTAssertEqualObjects(tester.nextItem, @"0");
    XCTAssertNil(tester.parseError);
}

- (void)test_TriMetXML_XML_ATR_BOOL_DEFAULT_FALSE {
    // Build
    XMLTestFile *xmlFile = [XMLTestFile fileWithOneTag:XML_TEST_ATTRIBUTE_TAG
                                            attributes:@[
                                                @[ @"item0", @"true" ],
                                                @[ @"item1", @"false" ],
                                                @[ @"item2", @"TRUE" ],
                                                @[ @"item3", @"FALSE" ],
                                                @[ @"item4", @"True" ],
                                                @[ @"item5", @"FalsE" ],
                                                @[ @"item6", @"yes" ],
                                                @[ @"item7", @"no" ],
                                                @[ @"item8", @"Yes" ],
                                                @[ @"item9", @"NO" ],
                                                @[ @"item10", @"1" ],
                                                @[ @"item11", @"0" ],
                                                @[ @"item12", @"maybe" ],
                                            ]];

    XMLAttributeTester<NSString *> *tester = [XMLAttributeTester xml];

    tester.action = ^(XmlAttributes *attributeDict, XMLAttributeTester *xml) {
      [xml.items addObject:FORMAT_LLD(XML_ATR_BOOL_DEFAULT_FALSE(@"item0"))];
      [xml.items addObject:FORMAT_LLD(XML_ATR_BOOL_DEFAULT_FALSE(@"Item1"))];
      [xml.items addObject:FORMAT_LLD(XML_ATR_BOOL_DEFAULT_FALSE(@"item2"))];
      [xml.items addObject:FORMAT_LLD(XML_ATR_BOOL_DEFAULT_FALSE(@"item3"))];
      [xml.items addObject:FORMAT_LLD(XML_ATR_BOOL_DEFAULT_FALSE(@"item4"))];
      [xml.items addObject:FORMAT_LLD(XML_ATR_BOOL_DEFAULT_FALSE(@"item5"))];
      [xml.items addObject:FORMAT_LLD(XML_ATR_BOOL_DEFAULT_FALSE(@"item6"))];
      [xml.items addObject:FORMAT_LLD(XML_ATR_BOOL_DEFAULT_FALSE(@"item7"))];
      [xml.items addObject:FORMAT_LLD(XML_ATR_BOOL_DEFAULT_FALSE(@"item8"))];
      [xml.items addObject:FORMAT_LLD(XML_ATR_BOOL_DEFAULT_FALSE(@"item9"))];
      [xml.items addObject:FORMAT_LLD(XML_ATR_BOOL_DEFAULT_FALSE(@"item10"))];
      [xml.items addObject:FORMAT_LLD(XML_ATR_BOOL_DEFAULT_FALSE(@"item11"))];
      [xml.items addObject:FORMAT_LLD(XML_ATR_BOOL_DEFAULT_FALSE(@"item12"))];
      [xml.items addObject:FORMAT_LLD(XML_ATR_BOOL_DEFAULT_FALSE(@"missing"))];
    };

    // Operate
    [tester startParsing:xmlFile.makeURLstring];

    // Assert
    XCTAssert(tester.gotData);
    XCTAssertEqual(tester.count, 14);

    XCTAssertEqualObjects(tester.nextItem, @"1");
    XCTAssertEqualObjects(tester.nextItem, @"0");
    XCTAssertEqualObjects(tester.nextItem, @"1");
    XCTAssertEqualObjects(tester.nextItem, @"0");
    XCTAssertEqualObjects(tester.nextItem, @"1");
    XCTAssertEqualObjects(tester.nextItem, @"0");
    XCTAssertEqualObjects(tester.nextItem, @"1");
    XCTAssertEqualObjects(tester.nextItem, @"0");
    XCTAssertEqualObjects(tester.nextItem, @"1");
    XCTAssertEqualObjects(tester.nextItem, @"0");
    XCTAssertEqualObjects(tester.nextItem, @"1");
    XCTAssertEqualObjects(tester.nextItem, @"0");
    XCTAssertEqualObjects(tester.nextItem, @"0");
    XCTAssertNil(tester.parseError);
}

- (void)test_TriMetXML_XML_ATR_LOCATION {
    // Build
    XMLTestFile *xmlFile = [XMLTestFile new];

    [xmlFile addHeaderTag:[NSDate date]];
    [xmlFile tagWithAtrributes:XML_TEST_ATTRIBUTE_TAG
                    attributes:@[
                        @[ @"lat", @"-1.3141593141593" ], @[ @"lng", @"2" ]
                    ]];
    [xmlFile tagWithAtrributes:XML_TEST_ATTRIBUTE_TAG
                    attributes:@[ @[ @"lat", @"1" ] ]];
    [xmlFile tagWithAtrributes:XML_TEST_ATTRIBUTE_TAG
                    attributes:@[ @[ @"lng", @"1" ] ]];
    [xmlFile tagWithAtrributes:XML_TEST_ATTRIBUTE_TAG
                    attributes:@[
                        @[ @"lat", @"45.479869999998" ],
                        @[ @"lng", @"-122.70219199998" ]
                    ]];
    [xmlFile tagWithAtrributes:XML_TEST_ATTRIBUTE_TAG
                    attributes:@[ @[ @"what", @"1" ] ]];
    [xmlFile closeHeaderTag];

    XMLAttributeTester<NSString *> *tester = [XMLAttributeTester xml];

    tester.action = ^(XmlAttributes *attributeDict, XMLAttributeTester *xml) {
      CLLocation *loc = XML_ATR_LOCATION(@"lat", @"lng");
      [xml.items addObject:COORD_TO_LAT_LNG_STR(loc.coordinate)];
    };

    // Operate
    [tester startParsing:xmlFile.makeURLstring];

    // Assert
    XCTAssert(tester.gotData);
    XCTAssertEqual(tester.count, 5);

    XCTAssertEqualObjects(tester.nextItem, @"-1.3141593141593,2.0000000000000");
    XCTAssertEqualObjects(tester.nextItem, @"1.0000000000000,0.0000000000000");
    XCTAssertEqualObjects(tester.nextItem, @"0.0000000000000,1.0000000000000");
    XCTAssertEqualObjects(tester.nextItem,
                          @"45.4798699999980,-122.7021919999800");
    XCTAssertEqualObjects(tester.nextItem, @"0.0000000000000,0.0000000000000");
    XCTAssertNil(tester.parseError);
}

- (void)test_TriMetXML_XML_ATR_DISTANCE {
    // Build
    XMLTestFile *xmlFile =
        [XMLTestFile fileWithOneTag:XML_TEST_ATTRIBUTE_TAG
                         attributes:@[ @[ @"item", @"991234567890" ] ]];
    XMLAttributeTester<NSString *> *tester = [XMLAttributeTester xml];

    tester.action = ^(XmlAttributes *attributeDict, XMLAttributeTester *xml) {
      [xml.items addObject:FORMAT_LLD(XML_ATR_DISTANCE(@"item"))];
      [xml.items addObject:FORMAT_LLD(XML_ATR_DISTANCE(@"missing"))];
    };

    // Operate
    [tester startParsing:xmlFile.makeURLstring];

    // Assert
    XCTAssert(tester.gotData);
    XCTAssertEqual(tester.count, 2);

    XCTAssertEqualObjects(tester.nextItem, @"991234567890");
    XCTAssertEqualObjects(tester.nextItem, @"0");
}

- (void)test_TriMetXML_XML_ZERO_LEN_ATR_STR {
    // Build
    XMLTestFile *xmlFile =
        [XMLTestFile fileWithOneTag:XML_TEST_ATTRIBUTE_TAG
                         attributes:@[ @[ @"item", @"well hello dolly" ] ]];
    XMLAttributeTester<NSString *> *tester = [XMLAttributeTester xml];

    tester.action = ^(XmlAttributes *attributeDict, XMLAttributeTester *xml) {
      [xml.items addObject:XML_ZERO_LEN_ATR_STR(@"item")];
      [xml.items addObject:XML_ZERO_LEN_ATR_STR(@"item2")];
    };

    // Operate
    [tester startParsing:xmlFile.makeURLstring];

    // Assert
    XCTAssert(tester.gotData);
    XCTAssertEqual(tester.count, 2);

    XCTAssertEqualObjects(tester.nextItem, @"well hello dolly");
    XCTAssertEqualObjects(tester.nextItem, @"");
    XCTAssertNil(tester.parseError);
}

- (void)test_NextWeekOverNewYearAnomoly {
    // Build
    XMLAttributeTester<NSString *> *tester = [XMLAttributeTester xml];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy hh:mm:ss a"];

    // Jan 1st 2021 is a Saturday
    // This date is the Friday before
    NSDate *date = [dateFormatter dateFromString:@"31/12/2021 03:30:00 A"];

    DEBUG_LOG_NSString([NSDateFormatter
        localizedStringFromDate:date
                      dateStyle:NSDateFormatterShortStyle
                      timeStyle:NSDateFormatterMediumStyle]);

    // Operate
    NSTimeInterval interval = [tester secondsUntilEndOfServiceSunday:date];

    // Assert
    XCTAssertEqual(interval, 2 * 60 * 60 * 24);
}

- (void)test_NextWeekOverNewYear {
    // Build
    XMLAttributeTester<NSString *> *tester = [XMLAttributeTester xml];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy hh:mm:ss a"];

    // Jan 1st 2020 is a Friday
    // This date is the Thursday before
    // The week after Christmas is in fact first week of 2021
    NSDate *date = [dateFormatter dateFromString:@"24/12/2020 03:30:00 A"];

    DEBUG_LOG_NSString([NSDateFormatter
        localizedStringFromDate:date
                      dateStyle:NSDateFormatterShortStyle
                      timeStyle:NSDateFormatterMediumStyle]);

    // Operate
    NSTimeInterval interval = [tester secondsUntilEndOfServiceSunday:date];

    // Assert
    XCTAssertEqual(interval, 3 * 60 * 60 * 24);
}

@end
