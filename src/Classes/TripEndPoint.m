//
//  TripEndPoint.m
//  PDX Bus
//
//  Created by Andrew Wallace on 6/8/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TripEndPoint.h"

#define kDictEndPointUseCurrentLocation @"useCurrentLocation"
#define kDictEndPointLocationDec		@"locationDesc"
#define kDictEndPointAddtionalInfo		@"additionalInfo"
#define kDictEndPointLocationLat		@"lat"
#define kDictEndPointLocationLng		@"lng"


@implementation TripEndPoint
@synthesize locationDesc			= _locationDesc;
@synthesize coordinates             = _coordinates;
@synthesize useCurrentLocation		= _useCurrentLocation;
@synthesize additionalInfo			= _additionalInfo;

- (void)dealloc
{
	self.locationDesc   = nil;
	self.coordinates    = nil;
	self.additionalInfo = nil;
    
	[super dealloc];
}

- (NSString *)toQuery:(NSString *)toOrFrom
{
    NSMutableString *ret = [NSMutableString string];
    
	NSString * desc = self.locationDesc;
    
	if (desc == nil || self.coordinates!=nil)
	{
		desc = kAcquiredLocation;
	}
    
    NSMutableString *ms = [NSMutableString string];
    
	[ms appendString:[desc stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    
	[ms replaceOccurrencesOfString:@"/"
                        withString:@"%2F"
                           options:NSLiteralSearch
                             range:NSMakeRange(0, ms.length)];
    
    
	[ms replaceOccurrencesOfString:@"&"
                        withString:@"%26"
                           options:NSLiteralSearch
                             range:NSMakeRange(0, ms.length)];
    
	[ret appendFormat:@"%@Place=%@",toOrFrom, ms];

    
	if (self.coordinates != nil)
	{
		[ret appendFormat:@"&%@Coord=%f,%f", toOrFrom, self.coordinates.coordinate.longitude, self.coordinates.coordinate.latitude];
	}
	return ret;
}




- (NSDictionary *)toDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	
    dict[kDictEndPointUseCurrentLocation] = @(self.useCurrentLocation);
	
	if (self.locationDesc != nil)
	{
		dict[kDictEndPointLocationDec] = self.locationDesc;
	}
	
	if (self.additionalInfo != nil)
	{
		dict[kDictEndPointAddtionalInfo] = self.additionalInfo;
	}
	
	if (self.coordinates!=nil)
	{
        dict[kDictEndPointLocationLat] = @(self.coordinates.coordinate.latitude);
        dict[kDictEndPointLocationLng] = @(self.coordinates.coordinate.longitude);
		
	}
	return dict;
	
}

- (void)resetCurrentLocation
{
    if (self.useCurrentLocation)
    {
        self.locationDesc = nil;
        self.coordinates = nil;
    }
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
- (bool)readDictionary:(NSDictionary *)dict
{
	if (dict == nil)
	{
		return false;
	}
	
	
	NSNumber *useCurretLocation = [self forceNSNumber:dict[kDictEndPointUseCurrentLocation]];
	
	if (useCurretLocation)
	{
		self.useCurrentLocation = useCurretLocation.boolValue;
	}
	else {
		self.useCurrentLocation = false;
	}
    
	self.locationDesc = [self forceNSString:dict[kDictEndPointLocationDec]];
	self.additionalInfo = [self forceNSString:dict[kDictEndPointAddtionalInfo]];
	
	
	NSNumber *lat = [self forceNSNumber:dict[kDictEndPointLocationLat]];
	NSNumber *lng = [self forceNSNumber:dict[kDictEndPointLocationLng]];
    
	if (lat!=nil && lng!=nil)
	{
		self.coordinates = [[[CLLocation alloc] initWithLatitude:lat.doubleValue longitude:lng.doubleValue]
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

+ (instancetype)fromDictionary:(NSDictionary *)dict
{
    id item = [[[[self class] alloc] init] autorelease];
    if ([item readDictionary:dict])
    {
        return item;
    }
    return nil;
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
	return [NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), self.locationDesc];
}

@end
