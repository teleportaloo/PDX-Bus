//
//  XMLRouteTests.m
//  PDX BusTests
//
//  Created by Andrew Wallace on 10/6/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//




/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <XCTest/XCTest.h>
#import <XCTest/XCTest.h>
#import "XMLTestFile.h"
#import "../PDXBusCore/src/DebugLogging.h"
#import "../Classes/XMLRoutes.h"
#import "../Classes/XMLStops.h"
#import "../PDXBusCore/src/XMLLocateStops.h"
#import "../PDXBusCore/src/FormatDistance.h"
#import "../PDXBusCore/src/CLLocation+Helper.h"
#import "../PDXBusCore/src/RouteDistance.h"

@interface XMLRouteTests : XCTestCase

@end

@implementation XMLRouteTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)test_XMLRoutes_routes {
    // Build
    XMLRoutes *sut =  [XMLRoutes xml];
    sut.queryBlock = [XMLTestFile queryBlockWithFileForClass:@{@"XMLRoutes":@"routeConfig-routes"}];
    
    // Operate
    [sut getRoutesCacheAction:TriMetXMLNoCaching];
    
    // Assert
    XCTAssert(                                      sut.gotData);
    XCTAssertEqual(                                 sut.count, 95);
    XCTAssertNil(                                   sut.parseError);
    Route *route = sut[0];
    XCTAssertEqualObjects(  route.desc,             @"MAX Blue Line");
    XCTAssertEqualObjects(  route.route,            @"100");
    XCTAssertEqual(         route.routeSortOrder,   100);
    XCTAssert(                                      !route.systemWide);
 
}

- (void)test_XMLRoutes_routeWithStops {
    // Build
    XMLRoutes *sut =  [XMLRoutes xml];
    sut.queryBlock = [XMLTestFile queryBlockWithFileForClass:@{@"XMLRoutes":@"routeConfig-stops"}];
    
    // Operate
    [sut getStops:@"14" cacheAction:TriMetXMLNoCaching];
    
    // Assert
    XCTAssert(                                      sut.gotData);
    XCTAssertEqual(                                 sut.count, 1);
    Route *route = sut[0];
    XCTAssertEqualObjects(  route.desc,             @"14-Hawthorne");
    XCTAssertEqualObjects(  route.route,            @"14");
    XCTAssertEqual(         route.routeSortOrder,   1700);
    XCTAssert(                                      !route.systemWide);
    XCTAssertEqualObjects(  route.frequentService,  @(TRUE));
    
    
    Direction *directon = route.directions[@"0"];
    
    XCTAssertEqualObjects(  directon.desc,              @"To Foster & 94th");
    XCTAssertEqualObjects(  directon.dir,               @"0");
    
    Stop *stop = directon.stops[10];
    XCTAssertEqualObjects(  stop.desc,                  @"SE Hawthorne & 23rd");
    XCTAssertEqualObjects(  stop.stopId,                @"2608");
    XCTAssertEqualObjects(         stop.dir,            @"Eastbound");
    XCTAssert(                                          !stop.timePoint);
    XCTAssertEqual(                                     stop.index,       11);
    XCTAssertEqual(stop.location.coordinate.latitude,   45.5120033162158);
    XCTAssertEqual(stop.location.coordinate.longitude,  -122.642332695456);
    XCTAssertNil(           sut.parseError);
}

- (void)test_XMLRoutes_directions
{
    // Build
    XMLRoutes *sut =  [XMLRoutes xml];
    sut.queryBlock = [XMLTestFile queryBlockWithFileForClass:@{@"XMLRoutes":@"routeConfig-directions"}];
    
    // Operate
    [sut getDirections:@"19" cacheAction:TriMetXMLNoCaching];
    
    // Assert
    XCTAssert(                                      sut.gotData);
    XCTAssertEqual(                                 sut.count, 1);
    XCTAssertNil(                                   sut.parseError);
    Route *route = sut[0];
    XCTAssertEqualObjects(  route.desc,             @"19-Woodstock/Glisan");
    XCTAssertEqualObjects(  route.route,            @"19");
    XCTAssertEqual(         route.routeSortOrder,   2400);
    XCTAssertEqual(         route.directions.count, 2);
    XCTAssert(              route.directions[@"0"], @"To Mt. Scott & 112th");
    XCTAssert(              route.directions[@"1"], @"To Gateway Transit Center");
    XCTAssert(                                      !route.systemWide);
 
}

- (void)test_XMLRoutes_stops
{
    // Build
    XMLStops *sut =  [XMLStops xml];
    sut.queryBlock = [XMLTestFile queryBlockWithFileForClass:@{@"XMLStops":@"routeConfig-stops"}];
    
    // Operate
    [sut getStopsForRoute:@"14" direction:@"0" description:@"" cacheAction:TriMetXMLNoCaching];
    
    // Assert
    XCTAssert(                                          sut.gotData);
    XCTAssertEqual(                                     sut.count, 40);
    XCTAssertNil(                                       sut.parseError);
    Stop *stop = sut[10];
    XCTAssertEqualObjects(  stop.desc,                  @"SE Hawthorne & 23rd");
    XCTAssertEqualObjects(  stop.stopId,                @"2608");
    XCTAssertEqualObjects(  stop.dir,                   @"Eastbound");
    XCTAssert(                                          !stop.timePoint,                );
    XCTAssertEqual(                                     stop.index,       11);
    XCTAssertEqual(stop.location.coordinate.latitude,   45.5120033162158);
    XCTAssertEqual(stop.location.coordinate.longitude,  -122.642332695456);

}

- (void)test_XMLRoutes_locateStops
{
    // Build
    XMLLocateStops *sut =  [XMLLocateStops xml];
    sut.queryBlock = [XMLTestFile queryBlockWithFileForClass:@{@"XMLLocateStops":@"stops-locate"}];
    
    sut.maxToFind = 6;
    sut.minDistance = kMetresInAMile;
    sut.mode = TripModeAll;
    sut.location = [CLLocation withLat:45.530612 lng:-122.698688];
    sut.includeRoutesInStops = NO;
    
    // Operate
    [sut findNearestStops];
    
    // Assert
    XCTAssert(                                                              sut.gotData);
    XCTAssertEqual(                                                         sut.count, 6);
    XCTAssertNil(                                                           sut.parseError);
    StopDistance *stop = sut[2];
    XCTAssertEqualObjects(          stop.desc,                              @"NW 23rd & Overton");
    XCTAssertEqualObjects(          stop.stopId,                            @"10287");
    XCTAssertEqualObjects(          stop.dir,                               @"Southbound");
    XCTAssertEqual(                 stop.location.coordinate.latitude,      45.5320287369524);
    XCTAssertEqual(                 stop.location.coordinate.longitude,     -122.698762732352);

}

- (void)test_XMLLocateStops_routes
{
    // Build
    XMLLocateStops *sut =  [XMLLocateStops xml];
    sut.queryBlock = [XMLTestFile queryBlockWithFileForClass:@{@"XMLLocateStops":@"stops-locate-routes"}];
    
    sut.maxToFind = 6;
    sut.minDistance = kMetresInAMile;
    sut.mode = TripModeAll;
    sut.location = [CLLocation withLat:45.5270414684259 lng:-122.945808297437];
    
    // Operate
    [sut findNearestRoutes];
    
    // Assert
    XCTAssert(                                                              sut.gotData);
    XCTAssertEqual(                                                         sut.routes.count, 4);
    XCTAssertNil(                                                           sut.parseError);
    
    RouteDistance *route = sut.routes[1];
    XCTAssertEqualObjects(          route.desc,                             @"46-North Hillsboro");
    XCTAssertEqualObjects(          route.route,                            @"46");
    XCTAssertEqualObjects(          route.type,                             @"B");
    XCTAssertEqual(                 route.stops.count,                      4);
    
    StopDistance *stop = route.stops[0];
    XCTAssertEqualObjects(          stop.desc,                              @"Fair Complex/Airport Park & Ride");
    XCTAssertEqualObjects(          stop.stopId,                            @"9953");
    XCTAssertEqualObjects(          stop.dir,                               @"Eastbound");
    XCTAssertEqual(                 stop.location.coordinate.latitude,      45.527197999998);
    XCTAssertEqual(                 stop.location.coordinate.longitude,     -122.94587999998);
    
}

/*
- (void)test_XMLRoutes_fillCache {
    XMLRoutes *sut =  [XMLRoutes xml];
    
    [sut getRoutesCacheAction:TrIMetXMLRouteCacheReadOrFetch];
    
    for (Route *route in sut) {
        XMLRoutes *dir = [XMLRoutes xml];
        [dir getDirections:route.route cacheAction:TrIMetXMLRouteCacheReadOrFetch];
        
        for (Route *routeDir in dir) {
            [routeDir.directions enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, Direction * _Nonnull obj, BOOL * _Nonnull stop) {
                XMLStops *stops =  [XMLStops xml];
                [stops getStopsForRoute:route.route direction:obj.dir description:@"" cacheAction:TrIMetXMLRouteCacheReadOrFetch];
            }];
        }
    }

}
*/


@end
