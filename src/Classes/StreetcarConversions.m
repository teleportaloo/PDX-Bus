//
//  StreetcarConversions.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/13/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "StreetcarConversions.h"
#import "DebugLogging.h"

@implementation StreetcarConversions


@synthesize streetcarMapping		= _streetcarMapping;

- (void)dealloc
{
    self.streetcarMapping = nil;
    
    [MemoryCaches removeCache:self];
    
    [super dealloc];
}

-(void)loadStreetcarMapping
{
	if (self.streetcarMapping == nil)
	{
		self.streetcarMapping = [[[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PortlandStreetcar" ofType:@"plist"]] autorelease];
	}
}

+ (StreetcarConversions*)getSingleton
{
    static StreetcarConversions *singleton = nil;
    if (singleton == nil)
    {
        singleton = [[StreetcarConversions alloc] init];
        [MemoryCaches addCache:singleton];
    }
    
    [singleton loadStreetcarMapping];
    
    return singleton;
}

+ (NSDictionary *)getStreetcarRoutes
{
	
	return [[StreetcarConversions getSingleton].streetcarMapping  objectForKey:@"route"];
}


+ (NSDictionary *)getStreetcarBlockMap
{
	return [[StreetcarConversions getSingleton].streetcarMapping  objectForKey:@"block"];
}

+ (NSDictionary *)getStreetcarPlatforms
{
	return [[StreetcarConversions getSingleton].streetcarMapping  objectForKey:@"platforms"];
}

+ (NSDictionary *)getStreetcarDirections
{
	return [[StreetcarConversions getSingleton].streetcarMapping  objectForKey:@"directions"];
}

+(NSDictionary *)getStreetcarShortNames
{
	return [[StreetcarConversions getSingleton].streetcarMapping  objectForKey:@"shortnames"];
}

+ (NSDictionary *)getSubstitutions
{
	return [[StreetcarConversions getSingleton].streetcarMapping  objectForKey:@"substitutions"];
}


- (void)memoryWarning
{
    DEBUG_LOG(@"Releasing streetcar conversions %p\n", self.streetcarMapping);
    self.streetcarMapping = nil;
}


@end
