//
//  UserPrefs.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/19/10.
//  Copyright 2010. All rights reserved.
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


#import "UserPrefs.h"
#import "XMLTrips.h"
#import "XMLYahooPlaceNames.h"
#import "XMLReverseGeoCode.h"
#import "XMLYahooPlaceNames.h"
#import "XMLGeoNames.h"
#import "XMLGeoNamesNeighborhood.h"
#include "debug.h"


@implementation UserPrefs

@dynamic bookmarksAtTheTop;
@dynamic maxRecentStops;
@dynamic maxRecentTrips;
@dynamic maxWalkingDistance;
@dynamic travelBy;
@dynamic tripMin;
@dynamic autoRefresh;
@dynamic toolbarColors;
@dynamic actionIcons;
@dynamic routeCacheDays;
@dynamic networkTimeout;
@dynamic useGpsWithin;
@dynamic commuteButton;
@dynamic autoLocateShowOptions;

#define kPreferencesDomain @"org.teleportaloo.PDXBus"
#define kDefaultRecentStops 10
#define kDefaultTripHistory 10
#define kDefaultRouteCache  1
#define kDefaultNetworkTimeout 0
#define kDefaultUseGpsWithin 3218.688


- (id)init {
	if ((self = [super init]))
	{
		[_defaults = [NSUserDefaults standardUserDefaults] retain];
	}
	return self;
}

- (void)dealloc
{
	[_defaults release];
	[super dealloc];
	
}

+ (UserPrefs*) getSingleton
{
    static UserPrefs *_userPrefs = nil;
    
    if (_userPrefs == nil)
    {
        _userPrefs = [[UserPrefs alloc] init];
    }
    
    return _userPrefs;
}

- (BOOL)getBoolFromDefaultsForKey:(NSString*)key ifMissing:(BOOL)missing
{
	if  ([_defaults persistentDomainForName:kPreferencesDomain] == nil
		 || [_defaults objectForKey:key] == nil)
	{
		return missing;
	}
	return [_defaults boolForKey:key];
	
}

- (NSString*)getStringFromDefaultsForKey:(NSString*)key ifMissing:(NSString*)missing
{
	if  ([_defaults persistentDomainForName:kPreferencesDomain] == nil
		 || [_defaults objectForKey:key] == nil)
	{
        DEBUG_LOG(@"UserPrefs: Missing key %@ used %@\n", key, missing);
		return missing;
	}
    NSString *ret = [_defaults stringForKey:key];
    DEBUG_LOG(@"UserPrefs key %@ value %@\n", key, ret);
    
	return ret;
	
}

- (float)getFloatFromDefaultsForKey:(NSString*)key ifMissing:(float)missing max:(float)max min:(float)min
{
	float res;
	if  ([_defaults persistentDomainForName:kPreferencesDomain] == nil
		 || [_defaults objectForKey:key] == nil)
	{
		return missing;
	}
	res = [_defaults floatForKey:key];
	
	if (res > max || res < min)
	{
		return missing;
	}
	return res;
}

- (int)getIntFromDefaultsForKey:(NSString*)key ifMissing:(int)missing max:(int)max min:(int)min
{
	int res;
	if  ([_defaults persistentDomainForName:kPreferencesDomain] == nil
		 || [_defaults objectForKey:key] == nil)
	{
		return missing;
	}
	res =  [_defaults integerForKey:key];
	
	if (res > max || res < min)
	{
		return missing;
	}
	return res;
}

- (XMLReverseGeoCode *) reverseGeoCodeProvider
{
	int prov = [self getIntFromDefaultsForKey:@"geocode_provider"		
									ifMissing:UserPrefs_ReverseGeoCodeYahoo 
										  max:UserPrefs_ReverseGeoCodeMax 
										  min:0];
	if (prov == UserPrefs_ReverseGeoCodeYahoo && [kYahooAppId length]==0)
	{
		prov = UserPrefs_ReverseGeoCodeGeoNames;
	}
	
	XMLReverseGeoCode *geoCoder=nil;
	
	switch (prov)
	{
		case UserPrefs_ReverseGeoCodeYahoo:
			geoCoder = [[[XMLYahooPlaceNames alloc] init] autorelease];
			break;
		case UserPrefs_ReverseGeoCodeGeoNames:
			geoCoder = [[[XMLGeoNames alloc] init] autorelease];
			break;
		case UserPrefs_ReverseGeoCodeGeoNamesNbh:
			geoCoder = [[[XMLGeoNamesNeighborhood alloc] init] autorelease];
			break;
	}
	
	return geoCoder;
		
}

- (bool) bookmarksAtTheTop
{
	return [self getBoolFromDefaultsForKey:@"bookmarks_at_the_top"		ifMissing:NO];	
}

- (bool) autoCommute
{
	return [self getBoolFromDefaultsForKey:@"auto_commute"				ifMissing:YES];	
}

- (bool) commuteButton
{
	return [self getBoolFromDefaultsForKey:@"commute_button"			ifMissing:YES];
}

- (bool) showTransitTracker
{
	return [self getBoolFromDefaultsForKey:@"show_transit_tracker"		ifMissing:NO];	
}

- (bool) shakeToRefresh
{
	return [self getBoolFromDefaultsForKey:@"shake_to_refresh"			ifMissing:YES];	
}

- (int)  maxRecentStops
{
	return [self getIntFromDefaultsForKey:@"recent_stops"				ifMissing:kDefaultRecentStops max:20 min:0];
}
- (int)  maxRecentTrips
{
	return [self getIntFromDefaultsForKey:@"trip_history"				ifMissing:kDefaultTripHistory max:20 min:0];
}

- (float)maxWalkingDistance
{
	return [self getFloatFromDefaultsForKey:@"max_walking_distance"		ifMissing:0.5 max:2.0 min:0.1];
	
}
- (bool) flashLed
{
	return [self getBoolFromDefaultsForKey:@"flash_led"		ifMissing:NO];
    
}

- (void)setFlashLed:(_Bool)flashLed
{
    [_defaults setBool:flashLed forKey:@"flash_led"];
}

- (bool) flashingLightWarning
{
	return [self getBoolFromDefaultsForKey:@"flashing_light_warning"		ifMissing:YES];
    
}

- (void)setFlashingLightWarning:(_Bool)warning
{
    [_defaults setBool:warning forKey:@"flashing_light_warning"];
}



- (bool) locateToolbarIcon
{
	return [self getBoolFromDefaultsForKey:@"locate_toolbar_icon"		ifMissing:YES];
    
}

- (bool) groupByArrivalsIcon
{
	return [self getBoolFromDefaultsForKey:@"group_by_arrivals_icon"         ifMissing:NO];
    
}


- (bool) flashingLightIcon
{
	return [self getBoolFromDefaultsForKey:@"flashing_light_icon"         ifMissing:YES];
    
}

- (void)setFlashingLightIcon:(_Bool)icon
{
    [_defaults setBool:icon forKey:@"flashing_light_icon"];
}


- (bool) qrCodeScannerIcon
{
	return [self getBoolFromDefaultsForKey:@"qr_code_scanner_icon"         ifMissing:YES];
    
}
- (void)setLocateToolbarIcon:(_Bool)icon
{
    [_defaults setBool:icon forKey:@"locate_toolbar_icon"];
}


- (bool) ticketAppIcon
{
	return [self getBoolFromDefaultsForKey:@"ticket_app_icon"		ifMissing:YES];
    
}

- (void)setTicketAppIcon:(_Bool)icon
{
    [_defaults setBool:icon forKey:@"ticket_app_icon"];
}


- (bool) showStreetcarMapFirst
{
	return [self getBoolFromDefaultsForKey:@"streetcar_map_first"		ifMissing:NO];
    
}

- (void)setShowStreetcarMapFirst:(_Bool)first
{
    [_defaults setBool:first forKey:@"streetcar_map_first"];
}




- (float)useGpsWithin
{
	return [self getFloatFromDefaultsForKey:@"use_gps_within"			ifMissing:4828.032 max:8046.72 min:1609.344];
}	
- (int)  travelBy
{
	return [self getIntFromDefaultsForKey:@"travel_by"					ifMissing:(int)TripModeAll max:2 min:0];
}

- (bool) autoLocateShowOptions
{
	return [self getBoolFromDefaultsForKey:@"auto_locate_show_options"			ifMissing:YES];
}

- (void)setAutoLocateShowOptions:(_Bool)showOptions
{
    [_defaults setBool:showOptions forKey:@"auto_locate_show_options"];
}

- (int)  tripMin
{
	return [self getIntFromDefaultsForKey:@"min"						ifMissing:(int)TripMinQuickestTrip max:2 min:0];	
}
- (bool) autoRefresh
{
	return [self getBoolFromDefaultsForKey:@"auto_refresh"				ifMissing:YES];
}
- (int) toolbarColors
{
	return [self getIntFromDefaultsForKey:@"toolbar_colors"			    ifMissing:0x094D8E max:0xFFFFFF min:0];
}
- (bool) actionIcons
{
	return [self getBoolFromDefaultsForKey:@"action_icons"				ifMissing:YES];
}

- (int) routeCacheDays
{
				
	return  [self getIntFromDefaultsForKey:@"route_cache"			     ifMissing:kDefaultRouteCache max:7 min:0];
}

- (bool) useCaching
{
    return [self getBoolFromDefaultsForKey:@"use_caching"				ifMissing:YES];
}

- (int)vehicleLocatorDistance
{
    return [self getIntFromDefaultsForKey:@"vehicle_locator_distance"	ifMissing:(int)0 max:800 min:0];
}

- (bool) vehicleLocations
{
    return self.vehicleLocatorDistance!=0;
}

- (bool) debugXML
{
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0)
    {
        return [self getBoolFromDefaultsForKey:@"debug_xml"				ifMissing:NO];
    }
    return FALSE;
}

- (bool) useChrome
{
    return [self getBoolFromDefaultsForKey:@"chrome"				ifMissing:NO];
}

- (int) networkTimeout
{
	
	return  [self getIntFromDefaultsForKey:@"network_timeout2"			 ifMissing:kDefaultNetworkTimeout max:60 min:0];
}

- (bool) alarmInitialWarning
{
	return [self getBoolFromDefaultsForKey:@"alarm_initial_10_min_warning"	ifMissing:YES];
}

- (bool) googleMapApp
{
	return [self getBoolFromDefaultsForKey:@"google_maps"	ifMissing:YES];
}
- (NSString*)alarmSoundFile
{
    NSString *fileName = [self getStringFromDefaultsForKey:@"alarm_sound" ifMissing:@"Train_Honk_Horn_2x-Mike_Koenig-157974048.aif"];

    DEBUG_LOG(@"alarmSoundFile %@\n", fileName);
    return fileName;
}


@end
