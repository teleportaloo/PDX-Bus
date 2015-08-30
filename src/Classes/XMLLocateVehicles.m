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
#import "BackgroundTaskContainer.h"
#import "XMLStreetcarLocations.h"

#define MetersInAMile 1609.344

@implementation XMLLocateVehicles

@synthesize location = _location;
@synthesize dist   = _dist;

- (void)dealloc
{
    self.location = nil;
    
    [super dealloc];
}


#define min(A,B) ((A) < (B) ? (A) : (B))
#define max(A,B) ((A) > (B) ? (A) : (B))

- (BOOL)findNearestVehicles
{
    NSString *query = nil;
    
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
    
        query = [NSString stringWithFormat:@"vehicles/bbox/%f,%f,%f,%f/xml/true/onRouteOnly/false",
   					   lonmin,latmin, lonmax, latmax];
    }
    else
    {
        query = [NSString stringWithFormat:@"vehicles/xml/true/onRouteOnly/false"];
    }
    
	NSError *error = nil;
	
    
	bool res =  [self startParsing:query parseError:&error cacheAction:TriMetXMLNoCaching];
    
    if (self.gotData)
    {
        [_itemArray sortUsingSelector:@selector(compareUsingDistance:)];
    }

	
	return res;
}

- (NSString*)fullAddressForQuery:(NSString *)query
{
	NSString *str = nil;
	
    str = [NSString stringWithFormat:@"http://developer.trimet.org/beta/v2/%@/appID/%@", query, TRIMET_APP_ID];
	
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
        VehicleData *currentVehicle = [[VehicleData alloc] init];
    
		currentVehicle.block           = [self safeValueFromDict:attributeDict valueForKey:@"blockID"];
		currentVehicle.nextLocID       = [self safeValueFromDict:attributeDict valueForKey:@"nextLocID"];
        currentVehicle.lastLocID       = [self safeValueFromDict:attributeDict valueForKey:@"nextLocID"];
        currentVehicle.routeNumber     = [self safeValueFromDict:attributeDict valueForKey:@"routeNumber"];
        currentVehicle.direction       = [self safeValueFromDict:attributeDict valueForKey:@"direction"];
        currentVehicle.signMessage     = [attributeDict objectForKey:@"signMessage"];
        currentVehicle.signMessageLong = [self safeValueFromDict:attributeDict valueForKey:@"signMessageLong"];
        currentVehicle.type            = [self safeValueFromDict:attributeDict valueForKey:@"type"];
        currentVehicle.locationTime    = [self getTimeFromAttribute:attributeDict valueForKey:@"time"];
        currentVehicle.garage          = [self safeValueFromDict:attributeDict valueForKey:@"garage"];

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



- (bool)displayErrorIfNoneFound:(id<BackgroundTaskProgress>)progress
{
	NSThread *thread = [NSThread currentThread];
	
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


@end
