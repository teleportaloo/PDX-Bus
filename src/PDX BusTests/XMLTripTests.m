//
//  XMLTripTests.m
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
#import "../Classes/XMLTrips.h"
#import "../Classes/LegShapeParser.h"
#import "../Classes/ShapeCompactSegment.h"

@interface XMLTripTests : XCTestCase

@end

@implementation XMLTripTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}



- (void)test_XMLTrips {
    // Build
    XMLTrips *sut =  [XMLTrips xml];
    
    sut.queryBlock = [XMLTestFile queryBlockWithFileForClass:@{@"XMLTrips":@"trip-planner"}];

    
    NSDictionary *userRequestDict = @{
        @"arrivalTime": @(0),
        @"dateAndTime":  [NSDate dateWithTimeIntervalSince1970:0], // Doesn't matter "2020-10-09 05:42:09 +0000"
        @"fromPoint" : @{
            @"additionalInfo" : @"Fair Complex/Hillsboro Airport MAX Stn (Eastbound)",
            @"locationDesc" : @"9838",
            @"useCurrentLocation" : @0
        },
        @"maxItineraries": @46,
        @"timeChoice": @1,
        @"toPoint" : @{
            @"additionalInfo" : @"SE Hawthorne & 12th",
            @"locationDesc" : @"2599",
            @"useCurrentLocation" : @0
        },
        @"tripMin"  : @0,
        @"tripMode" : @2,
        @"walk"     : @0.75
    };

    TripUserRequest *userRequest = [TripUserRequest fromDictionary:userRequestDict];

    sut.userRequest = userRequest;

    // Operate
    [sut fetchItineraries:nil];

    // Assert
    XCTAssertEqual(sut.count, 3);
    XCTAssertNil(  sut.parseError);
    
    TripItinerary *it = sut[0];
    
    XCTAssertEqual(it.legCount, 4);
    
    XCTAssertEqual       (  it.waitingTimeMins,             7);
    XCTAssertEqualObjects(  it.startDateFormatted,         @"10/8/20");
    XCTAssertEqualObjects(  it.startTimeFormatted,         @"10:43 PM");
    XCTAssertEqualObjects(  it.endTimeFormatted,           @"11:44 PM");
    XCTAssertEqual       (  it.durationMins,                61);
    XCTAssertEqual       (  it.distanceMiles,               17.52);
    XCTAssertEqualObjects(  it.message,                     nil);
    XCTAssertEqual       (  it.numberOfTransfers,           1);
    XCTAssertEqual       (  it.numberOfTripLegs,            4);
    XCTAssertEqual       (  it.walkingTimeMins,             0);
    XCTAssertEqual       (  it.transitTimeMins,             54);
    XCTAssertEqualObjects(  it.fare,                        @"Adult: $2.50\nHonored Citizen: $1.25\nYouth/Student: $1.25\n");
    XCTAssertEqualObjects(  it.travelTime,                  @"61 mins, including 7 mins waiting.");
    XCTAssertEqualObjects(  it.shortTravelTime,             @"Travel time: 1:01");
    XCTAssert(                                              it.hasFare);
    
    XCTAssertEqual(it.displayEndPoints.count, 7);
    
    TripLegEndPoint *ep = it.displayEndPoints[0];
  
   
    //XCTAssertEqualObjects(  ep.xlat,                        nil);
    //XCTAssertEqualObjects(  ep.xlon,                        nil);
    XCTAssertEqualObjects(  ep.desc,                        @"Fair Complex/Hillsboro Airport MAX Stn");
    XCTAssertEqualObjects(  ep.strStopId,                   @"9838");
    XCTAssertEqualObjects(  ep.displayText,                 @"#bStart at#b Fair Complex/Hillsboro Airport MAX Stn (Stop ID 9838)");
    XCTAssertEqualObjects(  ep.mapText,                     nil);
    XCTAssertEqualObjects(  ep.displayModeText,             @"Start");
    XCTAssertEqualObjects(  ep.displayTimeText,             nil);
    XCTAssertEqualObjects(  ep.leftColor,                   nil);
    XCTAssertEqualObjects(  ep.displayRouteNumber,          nil);
    XCTAssertEqual(         ep.index,                       0);
    XCTAssert(              !ep.thruRoute);
    XCTAssert(              !ep.deboard);
    XCTAssertEqualObjects(  ep.stopId,                      @"9838");
    XCTAssertEqual(         ep.pinColor,                    1);
    XCTAssertEqualObjects(  ep.pinStopId,                   @"9838");
    XCTAssertEqual(         ep.loc.coordinate.latitude,     +45.52704100);
    XCTAssertEqual(         ep.loc.coordinate.longitude,    -122.94580800);
    XCTAssert(              !ep.fromAppleMaps);
    
    TripLeg *leg = it.legs[0];
    
    XCTAssertEqualObjects(  leg.mode,                       @"Light Rail");
    XCTAssertEqualObjects(  leg.order,                      @"start");
    XCTAssertEqualObjects(  leg.startStartDateFormatted,    @"10/8/20");
    XCTAssertEqualObjects(  leg.startTimeFormatted,         @"10:43 PM");
    XCTAssertEqualObjects(  leg.endTimeFormatted,           @"11:28 PM");
    XCTAssertEqual       (  leg.durationMins,               45);
    XCTAssertEqual       (  leg.distanceMiles,              15.62);
    XCTAssertEqualObjects(  leg.displayRouteNumber,         @"MAX");
    XCTAssertEqualObjects(  leg.internalRouteNumber,        @"100");
    XCTAssertEqualObjects(  leg.routeName,                  @"MAX Blue Line to Gresham");
    XCTAssertEqualObjects(  leg.key,                        @"A");
    XCTAssertEqualObjects(  leg.direction,                  @"north");
    XCTAssertEqualObjects(  leg.block,                      @"9009");
    XCTAssert(              leg.from                        != nil);
    XCTAssert(              leg.to                          != nil);
    XCTAssert(              leg.legShape.segment            == nil);

    ep = leg.to;
    
    // XCTAssertEqualObjects(  ep.xlat,                        @"45.517153");
    // XCTAssertEqualObjects(  ep.xlon,                        @"-122.674172");
    XCTAssertEqualObjects(  ep.desc,                        @"Yamhill District MAX Station");
    XCTAssertEqualObjects(  ep.strStopId,                   @"8336");
    XCTAssertEqualObjects(  ep.displayText,                 @"#bGet off#b at Yamhill District MAX Station (Stop ID 8336)");
    XCTAssertEqualObjects(  ep.mapText,                     nil);
    XCTAssertEqualObjects(  ep.displayModeText,             @"Deboard");
    XCTAssertEqualObjects(  ep.displayTimeText,             @"11:28 PM");
    XCTAssert(              ep.leftColor                    !=nil);
    XCTAssertEqualObjects(  ep.displayRouteNumber,          @"100");
    XCTAssertEqual(         ep.index,                       0);
    XCTAssert(              !ep.thruRoute);
    XCTAssert(              ep.deboard);
    XCTAssertEqualObjects(  ep.stopId,                      @"8336");
    XCTAssertEqual(         ep.pinColor,                    1);
    XCTAssertEqualObjects(  ep.pinStopId,                   @"8336");
    XCTAssertEqual(         ep.loc.coordinate.latitude,     +45.517153);
    XCTAssertEqual(         ep.loc.coordinate.longitude,    -122.674172);
    XCTAssert(              !ep.fromAppleMaps);
}





- (void)test_XMLTrips_unknown {
    // Build
    XMLTrips *sut =  [XMLTrips xml];
    
    sut.queryBlock = [XMLTestFile queryBlockWithFileForClass:@{@"XMLTrips":@"trip-lists"}];
        
    NSDictionary *userRequestDict = @{
        @"arrivalTime": @(0),
        @"dateAndTime":  [NSDate dateWithTimeIntervalSince1970:0], // Doesn't matter "2020-10-09 05:42:09 +0000"
        @"fromPoint" : @{
                @"locationDesc" : @"City hall",
                @"useCurrentLocation" : @0
        },
        @"maxItineraries": @6,
        @"timeChoice": @0,
        @"toPoint" : @{
                @"locationDesc" : @"Middle  school",
                @"useCurrentLocation" : @0
        },
        @"tripMin"  : @0,
        @"tripMode" : @2,
        @"walk"     : @0.75
    };
    
    TripUserRequest *userRequest = [TripUserRequest fromDictionary:userRequestDict];
    
    sut.userRequest = userRequest;
    
    // Operate
    [sut fetchItineraries:nil];
    
    // Assert
    XCTAssertEqual(sut.count, 1);
    XCTAssertEqual(sut.fromList.count, 4);
    XCTAssertEqual(sut.toList.count, 3);
    XCTAssertNil(sut.parseError);
    
    TripLegEndPoint *ep = sut.fromList[0];

    
    // XCTAssertEqualObjects(  ep.xlat,                        @"45.485367");
    // XCTAssertEqualObjects(  ep.xlon,                        @"-122.796572");
    XCTAssertEqualObjects(  ep.desc,                        @"BEAVERTON CITY HALL");
    XCTAssertEqualObjects(  ep.strStopId,                   nil);
    XCTAssertEqualObjects(  ep.displayText,                 nil);
    XCTAssertEqualObjects(  ep.mapText,                     nil);
    XCTAssertEqualObjects(  ep.displayModeText,             nil);
    XCTAssertEqualObjects(  ep.displayTimeText,             nil);
    XCTAssertEqualObjects(  ep.leftColor,                   nil);
    XCTAssertEqualObjects(  ep.displayRouteNumber,          nil);
    XCTAssertEqual(         ep.index,                       0);
    XCTAssert(                                              !ep.thruRoute);
    XCTAssert(                                              !ep.deboard);
    XCTAssertEqualObjects(  ep.stopId,                      nil);
    XCTAssertEqual(         ep.pinColor,                    1);
    XCTAssertEqualObjects(  ep.pinStopId,                   nil);
    XCTAssertEqual(         ep.loc.coordinate.latitude,     +45.485367);
    XCTAssertEqual(         ep.loc.coordinate.longitude,    -122.796572);
    XCTAssert(                                              !ep.fromAppleMaps);
    
   
}


- (void)test_LegShapeParser_badLeg {
    // Build
    LegShapeParser *sut =  [[LegShapeParser alloc] init];
    
    NSURL *myURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"trip-route" withExtension:@"json"];
    
    sut.replaceQueryBlock = ^NSString *_Nonnull (LegShapeParser *_Nonnull xml, NSString *_Nonnull query) {
        return myURL.absoluteString;
    };
    
    // Operate
    [sut fetchCoords];
    
    // Assert
    XCTAssertEqual(sut.segment.count, 0);
}

- (void)test_LegShapeParser_goodLeg {
    // Build
    LegShapeParser *sut =  [[LegShapeParser alloc] init];
   
    NSURL *myURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"trip-route2" withExtension:@"json"];
    
    sut.replaceQueryBlock = ^NSString * _Nonnull(LegShapeParser * _Nonnull xml, NSString * _Nonnull query) {
        return myURL.absoluteString;
    };
        
    // Operate
    [sut fetchCoords];
    
    // Assert
    XCTAssertEqual(sut.segment.count, 32);
    XCTAssertEqualWithAccuracy(sut.segment.compact.coords[0].latitude,        45.515199877,  0.000000001);
    XCTAssertEqualWithAccuracy(sut.segment.compact.coords[0].longitude,     -122.675600059,  0.000000001);
}



@end
