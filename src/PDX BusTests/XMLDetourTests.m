//
//  XMLDetourTests.m
//  PDX BusTests
//
//  Created by Andrew Wallace on 10/4/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogTests

#import <XCTest/XCTest.h>
#import "XMLTestFile.h"
#import "../PDXBusCore/src/DebugLogging.h"
#import "../PDXBusCore/src/XMLDetours.h"
#import "../PDXBusCore/src/CLLocation+Helper.h"
#import "../PDXBusCore/src/NSString+Helper.h"

@interface XMLDetourTests : XCTestCase

@end

@implementation XMLDetourTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_XMLDetours_systemWide {
    // Build
    XMLDetours *sut =  [XMLDetours xml];
    
    XMLTestFile *xmlFile =  [XMLTestFile new];
    [xmlFile addHeaderTag:[NSDate date]];
    [xmlFile tagWithAtrributes:@"alert " attributes:@[
        @[@"begin", @"1495713600000"],
        @[@"end", @""],
        @[@"id", @"1"],
        @[@"info_link_url", @"https://trimet.org"],
        @[@"header_text", @"Thanksgiving Day Service"],
        @[@"system_wide_flag", @"true"],
        @[@"desc", @"A system-wide event with balloons is happening."]
    ]];
    
    [xmlFile closeHeaderTag];
    
    sut.queryBlock = xmlFile.queryBlock;
    
    // Operate
    [sut getDetours];
    
    // Assert
    XCTAssert(                                                      sut.gotData);
    XCTAssert(                                                      sut.count == 1);
    XCTAssert(              sut[0].extractStops.count == 0);
    XCTAssertEqualObjects(  sut[0].headerText,                      @"🦃 Thanksgiving Day Service");
    XCTAssertEqual(         MS_EPOCH(sut[0].beginDate),             1495713600000);
    XCTAssertEqual(         DETOUR_ID_STRIP_TAG(sut[0].detourId),   1);
    XCTAssertEqual(         DETOUR_TYPE_FROM_ID(sut[0].detourId),   @"");
    XCTAssertEqualObjects(  sut[0].infoLinkUrl,                     @"https://trimet.org");
    XCTAssertEqual(         sut[0].systemWide,                      TRUE);
    XCTAssertEqualObjects(  sut[0].detourDesc,                      @"A system-wide event with balloons is happening.");
    XCTAssertEqualObjects(  sut[0].detectStops.removeMarkUp,        sut[0].detourDesc);
    
    DEBUG_LOG(@"Processed detour %@", sut[0].detectStops.removeMarkUp);
    DEBUG_LOG(@"Original detour  %@", sut[0].detourDesc);
    
    XCTAssertNil(           sut.parseError);
}


- (void)test_XMLDetours_secondUrl {
    // Build
    XMLDetours *sut =  [XMLDetours xml];
    
    XMLTestFile *xmlFile =  [XMLTestFile new];
    [xmlFile addHeaderTag:[NSDate date]];
    [xmlFile tagWithAtrributes:@"alert " attributes:@[
        @[@"begin", @"1495713600000"],
        @[@"end", @""],
        @[@"id", @"1"],
        @[@"info_link_url", @"https://trimet.org https://gobytram.org"],
        @[@"header_text", @"Thanksgiving Day Service"],
        @[@"system_wide_flag", @"true"],
        @[@"desc", @"A system-wide event with balloons is happening."]
    ]];
    
    [xmlFile closeHeaderTag];
    
    sut.queryBlock = xmlFile.queryBlock;
    
    // Operate
    [sut getDetours];
    
    // Assert
    XCTAssertEqualObjects(  sut[0].infoLinkUrl, @"https://gobytram.org");
    XCTAssertNil(           sut.parseError);
    XCTAssertEqualObjects(  sut[0].detectStops.removeMarkUp,        sut[0].detourDesc);
    
    DEBUG_LOG(@"Processed detour %@", sut[0].detectStops.removeMarkUp);
    DEBUG_LOG(@"Original detour  %@", sut[0].detourDesc);
}

- (void)test_XMLDetours_secondUrlUpperCase {
    // Build
    XMLDetours *sut =  [XMLDetours xml];
    
    XMLTestFile *xmlFile =  [XMLTestFile new];
    [xmlFile addHeaderTag:[NSDate date]];
    [xmlFile tagWithAtrributes:@"alert " attributes:@[
        @[@"begin", @"1495713600000"],
        @[@"end", @""],
        @[@"id", @"1"],
        @[@"info_link_url", @"https://trimet.org HTTP://gobytram.org"],
        @[@"header_text", @"Thanksgiving Day Service"],
        @[@"system_wide_flag", @"true"],
        @[@"desc", @"A system-wide event with balloons is happening."]
    ]];
    
    [xmlFile closeHeaderTag];
    
    sut.queryBlock = xmlFile.queryBlock;
    
    // Operate
    [sut getDetours];
    
    // Assert
    XCTAssertEqualObjects(  sut[0].infoLinkUrl, @"HTTP://gobytram.org");
    XCTAssertNil(           sut.parseError);
    XCTAssertEqualObjects(  sut[0].detectStops.removeMarkUp,        sut[0].detourDesc);
    
    
    DEBUG_LOG(@"Processed detour %@", sut[0].detectStops.removeMarkUp);
    DEBUG_LOG(@"Original detour  %@", sut[0].detourDesc);
}

- (void)test_XMLDetours_badScan {
    // Build
    XMLDetours *sut =  [XMLDetours xml];
    
    XMLTestFile *xmlFile =  [XMLTestFile new];
    [xmlFile addHeaderTag:[NSDate date]];
    [xmlFile startTagWithAttributes:@"alert" attributes:@[
        @[@"begin", @"1495713600000"],
        @[@"end", @""],
        @[@"id", @"10"],
        @[@"info_link_url", @""],
        @[@"header_text", @""],
        @[@"system_wide_flag", @"false"],
        @[@"desc", @"Hello (Stop IDs bad (Stop ID 12 is bad so is 16 and 17) # nope 101 #detour (Stop Id(stop id 18) (Stop Idx 1234567) #"]
    ]];
    
    [xmlFile tagWithAtrributes:@"route" attributes:@[
        @[@"xmlns", @"urn:trimet:schedule"],
        @[@"desc", @"52-Farmington/185th"],
        @[@"route", @"52"],
        @[@"id", @"52"],
        @[@"type", @"B"],
        @[@"no_service_flag", @"false"],
    ]];
    
    [xmlFile closeTag:@"alert"];
    
    [xmlFile closeHeaderTag];
    
    sut.queryBlock = xmlFile.queryBlock;
    
    // Operate
    [sut getDetours];
    
    Detour *result = sut[0];
    NSArray<NSString *> *stops = result.extractStops;
    
    // Assert
    XCTAssert(                      sut.gotData);
    XCTAssertEqual(                 sut.count,                              1);
    XCTAssertEqualObjects(          result.headerText,                      @"");
   
    XCTAssertEqualObjects(          result.beginDate,                       [NSDate dateWithTimeIntervalSince1970:1495713600]);
    XCTAssertEqual(                 DETOUR_ID_STRIP_TAG(result.detourId),   10);
    XCTAssertEqual(                 DETOUR_TYPE_FROM_ID(result.detourId),   @"");
    XCTAssertEqualObjects(          result.infoLinkUrl,                     nil);
    XCTAssertEqual(                 result.systemWide,                      FALSE);
    
    XCTAssertEqual(                 stops.count,                            5);
    XCTAssert(                      [result.embeddedStops containsObject:   @"12"]);
    XCTAssert(                      [result.embeddedStops containsObject:   @"16"]);
    XCTAssert(                      [result.embeddedStops containsObject:   @"17"]);
    XCTAssert(                      [result.embeddedStops containsObject:   @"18"]);
    XCTAssert(                      [result.embeddedStops containsObject:   @"1234567"]);
    XCTAssertEqualObjects(          result.detectStops.removeMarkUp,        result.detourDesc);
    
    DEBUG_LOG(@"Processed detour %@", result.detectStops.removeMarkUp);
    DEBUG_LOG(@"Original detour  %@", result.detourDesc);
}

- (void)test_XMLDetours_routeAndStops {
    // Build
    XMLDetours *sut =  [XMLDetours xml];
    
    XMLTestFile *xmlFile =  [XMLTestFile new];
    [xmlFile addHeaderTag:[NSDate date]];
    [xmlFile startTagWithAttributes:@"alert" attributes:@[
        @[@"begin", @"1495713600000"],
        @[@"end", @""],
        @[@"id", @"10"],
        @[@"info_link_url", @""],
        @[@"header_text", @""],
        @[@"system_wide_flag", @"false"],
        @[@"desc", @"No service to northbound stops on SW 158th Ave at Jenkins (Stop ID 8234), Jay (Stop ID 6839), Baseline (Stop ID 8232) and Greystone Ct (Stop ID 13202), due to construction. Use stops before or after at Merlo Rd/SW 158th MAX Stn (Stop ID 12899) or SW 158th &amp; Walker (Stop ID 6832). Test (Stop ID bad) (Stop ID "]
    ]];
    
    [xmlFile tagWithAtrributes:@"route" attributes:@[
        @[@"xmlns", @"urn:trimet:schedule"],
        @[@"desc", @"52-Farmington/185th"],
        @[@"route", @"52"],
        @[@"id", @"52"],
        @[@"type", @"B"],
        @[@"no_service_flag", @"false"],
    ]];
    
    
    [xmlFile tagWithAtrributes:@"location" attributes:@[
        @[@"id", @"7122"],
        @[@"desc", @"NW 21st &amp; Lovejoy"],
        @[@"dir", @"Northbound"],
        @[@"lat", @"45.530113999998"],
        @[@"lng", @"-122.69447499998"],
        @[@"no_service_flag", @"false"],
        @[@"passengerCode", @"E"]
    ]];
    
    [xmlFile closeTag:@"alert"];
    
    [xmlFile closeHeaderTag];
    
    sut.queryBlock = xmlFile.queryBlock;
    
    // Operate
    [sut getDetours];
    
    Detour *result = sut[0];
    NSArray<NSString *> *stops = result.extractStops;
    
    // Assert
    XCTAssert(                      sut.gotData);
    XCTAssertEqual(                 sut.count,                              1);
    XCTAssertEqualObjects(          result.headerText,                      @"");
//    XCTAssertEqualObjects(          result.detectStops,                      @"");
    
    XCTAssertEqualObjects(          result.beginDate,                       [NSDate dateWithTimeIntervalSince1970:1495713600]);
    XCTAssertEqual(                 DETOUR_ID_STRIP_TAG(result.detourId),   10);
    XCTAssertEqual(                 DETOUR_TYPE_FROM_ID(result.detourId),   @"");
    XCTAssertEqualObjects(          result.infoLinkUrl,                     nil);
    XCTAssertEqual(                 result.systemWide,                      FALSE);
    
    XCTAssertEqual(                 stops.count,                            6);
    XCTAssert(                      [result.embeddedStops containsObject:   @"8234"]);
    XCTAssert(                      [result.embeddedStops containsObject:   @"6839"]);
    XCTAssert(                      [result.embeddedStops containsObject:   @"8232"]);
    XCTAssert(                      [result.embeddedStops containsObject:   @"13202"]);
    XCTAssert(                      [result.embeddedStops containsObject:   @"12899"]);
    XCTAssert(                      [result.embeddedStops containsObject:   @"6832"]);
    XCTAssertEqualObjects(          result.detectStops.removeMarkUp,        result.detourDesc);
    
    DEBUG_LOG(@"Processed detour %@", result.detectStops.removeMarkUp);
    DEBUG_LOG(@"Original detour  %@", result.detourDesc);
    
    
    XCTAssertEqual(                 result.locations.count, 1);
    DetourLocation *location = result.locations[0];
    XCTAssertEqualObjects(          location.stopId,                        @"7122");
    XCTAssertEqualObjects(          location.desc,                          @"NW 21st & Lovejoy");
    XCTAssertEqualObjects(          location.dir,                           @"Northbound");
    XCTAssertEqual(                 location.location.coordinate.latitude,  45.530113999998);
    XCTAssertEqual(                 location.location.coordinate.longitude, -122.69447499998);
    XCTAssert(                                                              !location.noServiceFlag);
    XCTAssertEqual(                 location.passengerCode,                 PassengerCodeEither);
    XCTAssertNil(                   sut.parseError);
    
  }


- (void)test_XMLDetours_stops {
    // Build
    XMLDetours *sut =  [XMLDetours xml];
    
    XMLTestFile *xmlFile =  [XMLTestFile new];
    [xmlFile addHeaderTag:[NSDate date]];
    [xmlFile startTagWithAttributes:@"alert" attributes:@[
        @[@"begin", @"1495713600000"],
        @[@"end", @""],
        @[@"id", @"10"],
        @[@"info_link_url", @""],
        @[@"header_text", @""],
        @[@"system_wide_flag", @"false"],
        @[@"desc", @"#28 29 # 30 49 No service to northbound stops on SW 158th Ave at Jenkins (Stop Id (Stop ID 15( ( Stop ids 8234), Jay ( Stop id 6839,1,2,3,4,M), Baseline (Stop IDs 8232,5) and Greystone Ct (Stop ID 13202), due to construction. Use stops before or after at Merlo Rd/SW 158th MAX Stn (Stop ID 12899) or SW 158th &amp; Walker (Stop ID 6832). Test (Stop ID bad) (Stop ID "]
    ]];
    
    
    [xmlFile closeTag:@"alert"];
    
    [xmlFile closeHeaderTag];
    
    sut.queryBlock = xmlFile.queryBlock;
    
    // Operate
    [sut getDetours];
    
    Detour *result = sut[0];
    NSArray<NSString *> *stops = result.extractStops;
    
    // Assert
    XCTAssertEqualObjects(result.detectStops.removeMarkUp,  result.detourDesc);
    
    DEBUG_LOG(@"Processed detour %@", result.detectStops.removeMarkUp);
    DEBUG_LOG(@"Original detour  %@", result.detourDesc);
    
    XCTAssertEqual(stops.count, 14);
    XCTAssert([result.embeddedStops containsObject:@"8234"]);
    XCTAssert([result.embeddedStops containsObject:@"6839"]);
    XCTAssert([result.embeddedStops containsObject:@"8232"]);
    XCTAssert([result.embeddedStops containsObject:@"13202"]);
    XCTAssert([result.embeddedStops containsObject:@"12899"]);
    XCTAssert([result.embeddedStops containsObject:@"6832"]);
    XCTAssert([result.embeddedStops containsObject:@"1"]);
    XCTAssert([result.embeddedStops containsObject:@"2"]);
    XCTAssert([result.embeddedStops containsObject:@"3"]);
    XCTAssert([result.embeddedStops containsObject:@"4"]);
    XCTAssert([result.embeddedStops containsObject:@"5"]);
    XCTAssert([result.embeddedStops containsObject:@"15"]);
    XCTAssert([result.embeddedStops containsObject:@"28"]);
    XCTAssert([result.embeddedStops containsObject:@"30"]);
    XCTAssertNil(sut.parseError);
}


- (void)test_XMLDetours_realDetours {
    // Build
    XMLDetours *sut =  [XMLDetours xml];
    
    sut.queryBlock = [XMLTestFile queryBlockWithFileForClass:@{@"XMLDetours":@"detours"}];
    
    // Operate
    [sut getDetours];
    
    // Assert
    XCTAssert(                                                      sut.gotData);
    XCTAssertEqual(         sut.count,                              95);
    XCTAssertNil(           sut.parseError);
    
    Detour *result = sut[0];
    
    XCTAssertEqualObjects(  result.headerText,                      @"1st & columbia stop move");
    XCTAssertEqual(         MS_EPOCH(result.beginDate),             1546623687972);
    XCTAssertEqual(         DETOUR_ID_STRIP_TAG(result.detourId),   24912);
    XCTAssertEqual(         DETOUR_TYPE_FROM_ID(result.detourId),   @"");
    XCTAssertEqualObjects(  result.infoLinkUrl,                     nil);
    XCTAssertEqual(         result.systemWide,                      FALSE);
    XCTAssertEqualObjects(  result.detourDesc,                       @"The stop at SW Columbia & 1st (Stop ID 12795) is closed long-term for construction. Use the temporary stop at SW Columbia & 2nd (Stop ID 14053).");
    XCTAssertEqualObjects(  result.detectStops.removeMarkUp,        result.detourDesc);
    
    DEBUG_LOG(@"Processed detour %@", result.detectStops.removeMarkUp);
    DEBUG_LOG(@"Original detour  %@", result.detourDesc);
    
}

@end
