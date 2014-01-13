//
//  TripEndPoint.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import "TripEndPoint.h"

#define kDictEndPointUseCurrentLocation @"useCurrentLocation"
#define kDictEndPointLocationDec		@"locationDesc"
#define kDictEndPointAddtionalInfo		@"additionalInfo"
#define kDictEndPointLocationLat		@"lat"
#define kDictEndPointLocationLng		@"lng"


@implementation TripEndPoint
@synthesize locationDesc			= _locationDesc;
@synthesize currentLocation			= _currentLocation;
@synthesize useCurrentLocation		= _useCurrentLocation;
@synthesize additionalInfo			= _additionalInfo;

- (void)dealloc
{
	self.locationDesc = nil;
	self.currentLocation = nil;
	self.additionalInfo = nil;
    
	[super dealloc];
}

- (NSString *)toQuery:(NSString *)toOrFrom
{
	NSMutableString *ret = [[[ NSMutableString alloc ] init] autorelease];
	
    
	NSString * desc = self.locationDesc;
    
	if (desc == nil)
	{
		desc = kAcquiredLocation;
	}
    
	NSMutableString *ms = [[NSMutableString alloc] init];
    
	[ms appendString:[desc stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    
	[ms replaceOccurrencesOfString:@"/"
                        withString:@"%2F"
                           options:NSLiteralSearch
                             range:NSMakeRange(0, [ms length])];
    
    
	[ms replaceOccurrencesOfString:@"&"
                        withString:@"%26"
                           options:NSLiteralSearch
                             range:NSMakeRange(0, [ms length])];
    
	[ret appendFormat:@"%@Place=%@",toOrFrom, ms];
	[ms release];
    
	if (self.currentLocation != nil)
	{
		[ret appendFormat:@"&%@Coord=%f,%f", toOrFrom, self.currentLocation.coordinate.longitude, self.currentLocation.coordinate.latitude];
	}
	return ret;
}




- (NSDictionary *)toDictionary
{
	NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
	
	
	[dict setObject:[[[NSNumber alloc] initWithBool:self.useCurrentLocation] autorelease]
			 forKey:kDictEndPointUseCurrentLocation];
	
	if (self.locationDesc != nil)
	{
		[dict setObject:self.locationDesc forKey:kDictEndPointLocationDec];
	}
	
	if (self.additionalInfo != nil)
	{
		[dict setObject:self.additionalInfo forKey:kDictEndPointAddtionalInfo];
	}
	
	if (self.currentLocation!=nil)
	{
		[dict setObject:[[[NSNumber alloc] initWithDouble:self.currentLocation.coordinate.latitude] autorelease]
				 forKey:kDictEndPointLocationLat];
		[dict setObject:[[[NSNumber alloc] initWithDouble:self.currentLocation.coordinate.longitude] autorelease]
				 forKey:kDictEndPointLocationLng];
		
	}
	return dict;
	
}

- (NSNumber *)forceNSNumber:(NSObject*)obj
{
	if (obj && [obj isKindOfClass:[NSNumber class]])
	{
		return (NSNumber *)obj;
	}
	return nil;
	
}


- (NSString *)forceNSString:(NSObject*)obj
{
	if (obj && [obj isKindOfClass:[NSString class]])
	{
		return (NSString*)obj;
	}
	return nil;
	
}
- (bool)fromDictionary:(NSDictionary *)dict
{
	if (dict == nil)
	{
		return false;
	}
	
	
	NSNumber *useCurretLocation = [self forceNSNumber:[dict objectForKey:kDictEndPointUseCurrentLocation]];
	
	if (useCurretLocation)
	{
		self.useCurrentLocation = [useCurretLocation boolValue];
	}
	else {
		self.useCurrentLocation = false;
	}
    
	self.locationDesc = [self forceNSString:[dict objectForKey:kDictEndPointLocationDec]];
	self.additionalInfo = [self forceNSString:[dict objectForKey:kDictEndPointAddtionalInfo]];
	
	
	NSNumber *lat = [self forceNSNumber:[dict objectForKey:kDictEndPointLocationLat]];
	NSNumber *lng = [self forceNSNumber:[dict objectForKey:kDictEndPointLocationLng]];
    
	if (lat!=nil && lng!=nil)
	{
		self.currentLocation = [[[CLLocation alloc] initWithLatitude:[lat doubleValue] longitude:[lng doubleValue]]
                                autorelease];
	}
	
    
	return YES;
}

- (bool)equalsTripEndPoint:(TripEndPoint *)endPoint
{
	return self.useCurrentLocation == endPoint.useCurrentLocation
    && ( self.useCurrentLocation
        || (self.locationDesc == nil && endPoint.locationDesc == nil)
        || (self.locationDesc != nil && [self.locationDesc isEqualToString:endPoint.locationDesc]));
}

- (id)initFromDict:(NSDictionary *)dict
{
	if ((self = [super init]))
	{
		[self fromDictionary:dict];
	}
	return self;
	
}

- (NSString *)displayText
{
	if (self.useCurrentLocation)
	{
		return kAcquiredLocation;
	}
	return self.locationDesc;
}

- (NSString *)userInputDisplayText
{
	if (self.useCurrentLocation)
	{
		return @"Current Location (GPS)";
	}
	
	if (self.locationDesc == nil)
	{
		return @"<touch to choose location>";
	}
	
	for (int i=0; i<self.locationDesc.length; i++)
	{
		unichar c = [self.locationDesc characterAtIndex:i];
		
		if ((c > '9' || c <'0') && c!=' ')
		{
			return self.locationDesc;
		}
	}
	
	if (self.additionalInfo)
	{
		return [NSString stringWithFormat:@"%@ - Stop ID %@",  self.additionalInfo, self.locationDesc];
	}
	return [NSString stringWithFormat:@"Stop ID %@", self.locationDesc];
}

@end