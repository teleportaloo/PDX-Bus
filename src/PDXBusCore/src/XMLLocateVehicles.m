//
//  XMLLocateVehicles.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/9/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLLocateVehicles.h"
#import "VehicleData.h"
#import <MapKit/MapKit.h>
#import <MapKit/MKGeometry.h>
#import "XMLStreetcarLocations.h"
#import "StringHelper.h"
#import "UserPrefs.h"

#define MetersInAMile 1609.344

@implementation XMLLocateVehicles

@synthesize location = _location;
@synthesize dist   = _dist;
@synthesize direction = _direction;
@synthesize noErrorAlerts = _noErrorAlerts;

- (void)dealloc
{
    self.location = nil;
    self.direction = nil;
    
    [super dealloc];
}


#define min(A,B) ((A) < (B) ? (A) : (B))
#define max(A,B) ((A) > (B) ? (A) : (B))

- (BOOL)findNearestVehicles:(NSSet *)routes direction:(NSString *)direction blocks:(NSSet *)blocks
{
    NSString *query = nil;
    
    NSMutableString *routeIDs = [[[NSMutableString alloc] init] autorelease];
    NSMutableString *blockQuery   = [[[NSMutableString alloc] init] autorelease];
    
    if (routes)
    {
        routeIDs = [StringHelper commaSeparatedStringFromEnumerator:routes selector:@selector(self)];
        
        [routeIDs insertString:@"/routes/" atIndex:0];
    }
    
    if (blocks)
    {
        for (NSString *block in blocks)
        {
            if (blockQuery.length > 0)
            {
                [blockQuery appendFormat:@","];
            }
            
            [blockQuery appendString:block];
        }
        
        [routeIDs insertString:@"/blocks/" atIndex:0];
    }
    
    
    if (self.dist > 1.0)
    {
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.location.coordinate, self.dist * 2.0, self.dist * 2.0);
        CLLocationCoordinate2D northWestCorner, southEastCorner;
        northWestCorner.latitude  = self.location.coordinate.latitude  - (region.span.latitudeDelta  / 2.0);
        northWestCorner.longitude = self.location.coordinate.longitude + (region.span.longitudeDelta / 2.0);
        southEastCorner.latitude  = self.location.coordinate.latitude  + (region.span.latitudeDelta  / 2.0);
        southEastCorner.longitude = self.location.coordinate.longitude - (region.span.longitudeDelta / 2.0);
    
        double lonmin = min(northWestCorner.longitude, southEastCorner.longitude);
        double latmin = min(northWestCorner.latitude,  southEastCorner.latitude);
        double lonmax = max(northWestCorner.longitude, southEastCorner.longitude);
        double latmax = max(northWestCorner.latitude,  southEastCorner.latitude);
    
        query = [NSString stringWithFormat:@"vehicles/bbox/%f,%f,%f,%f/xml/true/onRouteOnly/true%@%@",
   					   lonmin,latmin, lonmax, latmax, routeIDs, blockQuery];
    }
    else
    {
        query = [NSString stringWithFormat:@"vehicles/xml/true/onRouteOnly/true%@%@", routeIDs, blockQuery];
    }
    
    self.direction = direction;
	
    
	bool res =  [self startParsing:query cacheAction:TriMetXMLNoCaching];
    
    if (self.gotData)
    {
        [_itemArray sortUsingSelector:NSSelectorFromString(@"compareUsingDistance:")];
    }

	
	return res;
}

- (NSString*)fullAddressForQuery:(NSString *)query
{
	NSString *str = nil;
	
    str = [NSString stringWithFormat:@"%@://developer.trimet.org/ws/v2/%@/appID/%@",
                [UserPrefs getSingleton].triMetProtocol,
                query, TRIMET_APP_ID];
	
	return str;
	
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    [super parser:parser didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict];
    
    if (qName) {
        elementName = qName;
    }
	
	if ([elementName isEqualToString:@"resultSet"]) {
		
		[self initArray];
		hasData = YES;
	}
	
    if ([elementName isEqualToString:@"vehicle"]) {
        
        NSString *dir = [self safeValueFromDict:attributeDict valueForKey:@"direction"];
        
        if (self.direction == nil || [self.direction isEqualToString:dir])
        {
        
            VehicleData *currentVehicle = [[VehicleData alloc] init];
    
            currentVehicle.block           = [self safeValueFromDict:attributeDict valueForKey:@"blockID"];
            currentVehicle.nextLocID       = [self safeValueFromDict:attributeDict valueForKey:@"nextLocID"];
            currentVehicle.lastLocID       = [self safeValueFromDict:attributeDict valueForKey:@"nextLocID"];
            currentVehicle.routeNumber     = [self safeValueFromDict:attributeDict valueForKey:@"routeNumber"];
            currentVehicle.direction       = dir;
            currentVehicle.signMessage     = [attributeDict objectForKey:@"signMessage"];
            currentVehicle.signMessageLong = [self safeValueFromDict:attributeDict valueForKey:@"signMessageLong"];
            currentVehicle.type            = [self safeValueFromDict:attributeDict valueForKey:@"type"];
            currentVehicle.locationTime    = [self getTimeFromAttribute:attributeDict valueForKey:@"time"];
            currentVehicle.garage          = [self safeValueFromDict:attributeDict valueForKey:@"garage"];
            currentVehicle.bearing         = [self safeValueFromDict:attributeDict valueForKey:@"bearing"];

            currentVehicle.location = [[[CLLocation alloc] initWithLatitude:[self getCoordFromAttribute:attributeDict valueForKey:@"latitude"]
                                                                   longitude:[self getCoordFromAttribute:attributeDict valueForKey:@"longitude"] ] autorelease];
        
            if (self.location != nil)
            {
                currentVehicle.distance = [currentVehicle.location distanceFromLocation:self.location];
            }
        
        
            [self addItem:currentVehicle];
        
            [currentVehicle release];
        }
	}
}

/*

- (bool)displayErrorIfNoneFound:(id<BackgroundTaskProgress>)progress
{
	NSThread *thread = [NSThread currentThread];
    
    if (self.noErrorAlerts)
    {
        return false;
    }
	
	if ([self safeItemCount] == 0 && ![self gotData])
	{
		
		if (![thread isCancelled])
		{
			[thread cancel];
			//UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Nearby stops"
			//												   message:@"Network problem: please try again later."
			//												  delegate:delegate
			//										 cancelButtonTitle:@"OK"
			//										 otherButtonTitles:nil] autorelease];
			//[delegate retain];
            //[alert show];
            
            [progress backgroundSetErrorMsg:@"Network problem: please try again later."];
            
			return true;
		}
		
	}
	else if ([self safeItemCount] == 0)
	{
		if (![thread isCancelled])
		{
			[thread cancel];
            
            
            [progress backgroundSetErrorMsg:[NSString stringWithFormat:@"No vehicles were found within %0.1f miles, note Streetcar is not supported.",
                                             self.dist / MetersInAMile]];
			//UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Nearby stops"
			//												   message:[NSString stringWithFormat:@"No stops were found within %0.1f miles",
			//															self.minDistance / 1609.344]
			//
			//												  delegate:delegate
			//										 cancelButtonTitle:@"OK"
			//										 otherButtonTitles:nil] autorelease];
			//[alert performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
            // [alert show];
			return true;
		}
	}
	
	return false;
	
}
*/

@end
