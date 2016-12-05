//
//  UserPrefs.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/19/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import "UserPrefs.h"
#import "TriMetTypes.h"
#include "DebugLogging.h"
#import <UIKit/UIKit.h>


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

#define kPreferencesDomain      @"org.teleportaloo.PDXBus"
#define kWatchSuite             @"group.teleportaloo.pdxbus"


#define kDefaultRecentStops 10
#define kDefaultTripHistory 10
#define kDefaultRouteCache  1
#define kDefaultNetworkTimeout 0
#define kDefaultUseGpsWithin 3218.688



- (NSUserDefaults*)watchPreferences
{
    if ([NSUserDefaults instancesRespondToSelector:@selector(initWithSuiteName:)])
    {
        return [[[NSUserDefaults alloc] initWithSuiteName:kWatchSuite] autorelease];
    }
    
    return nil;
}

- (instancetype)init {
	if ((self = [super init]))
	{
        
#ifdef PDXBUS_WATCH
        _defaults = [[self watchPreferences] retain];
#else
        _defaults = [[NSUserDefaults standardUserDefaults] retain];
        _sharedDefaults = [[self watchPreferences] retain];
#endif
	}
	return self;
}

- (void)dealloc
{
	[_defaults release];
#ifndef PDXBUS_WATCH
    [_sharedDefaults release];
#endif
	[super dealloc];
}


+ (UserPrefs*) singleton
{
    static UserPrefs *_userPrefs = nil;
    
    if (_userPrefs == nil)
    {
        _userPrefs = [[UserPrefs alloc] init];
    }
    return _userPrefs;
}


- (bool)missing:(NSString *)key
{
    id obj = [_defaults objectForKey:key];

#ifdef PDXBUS_WATCH
    if  (obj == nil)
    {
        return YES;
    }
#else
    if  (([_defaults persistentDomainForName:kPreferencesDomain] == nil)
         || obj == nil)
    {
        return YES;
    }
#endif
    return NO;
}

- (BOOL)getBoolFromDefaultsForKey:(NSString*)key ifMissing:(BOOL)missing writeToShared:(BOOL)writeToShared
{
    if  ([self missing:key])
	{
		return missing;
	}
    
    BOOL res = [_defaults boolForKey:key];
    
    if (writeToShared && _sharedDefaults)
    {
        [_sharedDefaults setBool:res forKey:key];
    }
    
	return res;
	
}

- (NSString*)getStringFromDefaultsForKey:(NSString*)key ifMissing:(NSString*)missing
{
	if  ([self missing:key])
	{
        DEBUG_LOG(@"UserPrefs: Missing key %@ used %@\n", key, missing);
		return missing;
	}
    NSString *ret = [_defaults stringForKey:key];
    DEBUG_LOG(@"UserPrefs key %@ value %@\n", key, ret);

    
	return ret;
}



- (float)getFloatFromDefaultsForKey:(NSString*)key ifMissing:(float)missing max:(float)max min:(float)min writeToShared:(BOOL)writeToShared
{
	float res;
	if  ([self missing:key])
	{
		return missing;
	}
	res = [_defaults floatForKey:key];
	
	if (res > max || res < min)
	{
		return missing;
	}
    
    if (writeToShared && _sharedDefaults)
    {
        [_sharedDefaults setFloat:res forKey:key];
    }
    
	return res;
}

- (int)getIntFromDefaultsForKey:(NSString*)key ifMissing:(int)missing max:(int)max min:(int)min writeToShared:(BOOL)writeToShared
{
	int res;
    
	if  ([self missing:key])
	{
		return missing;
	}

	res = (int)[_defaults integerForKey:key];
	
	if (res > max || res < min)
	{
		return missing;
	}
    
    if (writeToShared && _sharedDefaults)
    {
        [_sharedDefaults setInteger:res forKey:key];
    }
    
	return res;
}

- (bool) bookmarksAtTheTop
{
	return [self getBoolFromDefaultsForKey:@"bookmarks_at_the_top"		ifMissing:NO writeToShared:NO];
}

- (bool) autoCommute
{
	return [self getBoolFromDefaultsForKey:@"auto_commute"				ifMissing:YES writeToShared:NO];
}

- (bool) commuteButton
{
	return [self getBoolFromDefaultsForKey:@"commute_button"			ifMissing:YES writeToShared:NO];
}

- (bool) showTransitTracker
{
	return [self getBoolFromDefaultsForKey:@"show_transit_tracker"		ifMissing:NO writeToShared:NO];
}

- (bool) shakeToRefresh
{
	return [self getBoolFromDefaultsForKey:@"shake_to_refresh"			ifMissing:YES writeToShared:NO];
}

- (int)  maxRecentStops
{
	return [self getIntFromDefaultsForKey:@"recent_stops"				ifMissing:kDefaultRecentStops max:20 min:0 writeToShared:YES];
}
- (int)  maxRecentTrips
{
	return [self getIntFromDefaultsForKey:@"trip_history"				ifMissing:kDefaultTripHistory max:20 min:0 writeToShared:YES];
}

- (float)maxWalkingDistance
{
	return [self getFloatFromDefaultsForKey:@"max_walking_distance"		ifMissing:0.5 max:2.0 min:0.1 writeToShared:NO];
	
}
- (bool) flashLed
{
	return [self getBoolFromDefaultsForKey:@"flash_led"                 ifMissing:NO writeToShared:NO];
    
}

- (void)setFlashLed:(_Bool)flashLed
{
    [_defaults setBool:flashLed forKey:@"flash_led"];
}

- (bool) flashingLightWarning
{
	return [self getBoolFromDefaultsForKey:@"flashing_light_warning"	ifMissing:YES writeToShared:NO];
    
}

- (void)setFlashingLightWarning:(_Bool)warning
{
    [_defaults setBool:warning forKey:@"flashing_light_warning"];
}


- (bool) locateToolbarIcon
{
	return [self getBoolFromDefaultsForKey:@"locate_toolbar_icon"		ifMissing:YES writeToShared:NO];
    
}

- (bool) groupByArrivalsIcon
{
	return [self getBoolFromDefaultsForKey:@"group_by_arrivals_icon"    ifMissing:NO writeToShared:NO];
    
}


- (bool) flashingLightIcon
{
	return [self getBoolFromDefaultsForKey:@"flashing_light_icon"       ifMissing:YES writeToShared:NO];
    
}

- (void)setFlashingLightIcon:(_Bool)icon
{
    [_defaults setBool:icon forKey:@"flashing_light_icon"];
}


- (bool) qrCodeScannerIcon
{
	return [self getBoolFromDefaultsForKey:@"qr_code_scanner_icon"      ifMissing:YES writeToShared:NO];
    
}
- (void)setLocateToolbarIcon:(_Bool)icon
{
    [_defaults setBool:icon forKey:@"locate_toolbar_icon"];
}


- (bool) ticketAppIcon
{
    return [self getBoolFromDefaultsForKey:@"ticket_app_icon"           ifMissing:YES writeToShared:NO];
}

- (void)setTicketAppIcon:(_Bool)icon
{
    [_defaults setBool:icon forKey:@"ticket_app_icon"];
}


- (bool) showStreetcarMapFirst
{
	return [self getBoolFromDefaultsForKey:@"streetcar_map_first"		ifMissing:NO writeToShared:NO];
    
}

- (void)setShowStreetcarMapFirst:(_Bool)first
{
    [_defaults setBool:first forKey:@"streetcar_map_first"];
}




- (float)useGpsWithin
{
	return [self getFloatFromDefaultsForKey:@"use_gps_within"			ifMissing:4828.032 max:8046.72 min:1609.344 writeToShared:NO];
}	
- (int)  travelBy
{
	return [self getIntFromDefaultsForKey:@"travel_by"					ifMissing:(int)TripModeAll max:2 min:0 writeToShared:NO];
}

- (bool) autoLocateShowOptions
{
	return [self getBoolFromDefaultsForKey:@"auto_locate_show_options"	ifMissing:YES writeToShared:NO];
}

- (void)setAutoLocateShowOptions:(_Bool)showOptions
{
    [_defaults setBool:showOptions forKey:@"auto_locate_show_options"];
}

- (int)  tripMin
{
	return [self getIntFromDefaultsForKey:@"min"						ifMissing:(int)TripMinQuickestTrip max:2 min:0 writeToShared:NO];
}
- (bool) autoRefresh
{
	return [self getBoolFromDefaultsForKey:@"auto_refresh"				ifMissing:YES writeToShared:YES];
}
- (int) toolbarColors
{
    int color = [self getIntFromDefaultsForKey:@"toolbar_colors"        ifMissing:0x094D8E max:0xFFFFFF min:0 writeToShared:NO];
    
    // Black does not work with iOS7 - so make it standard instead
    if (color == 0)
    {
        color = 0xFFFFFF;
    }
	return color;
}
- (bool) actionIcons
{
	return [self getBoolFromDefaultsForKey:@"action_icons"                  ifMissing:YES writeToShared:NO];
}

- (int) routeCacheDays
{
				
	return  [self getIntFromDefaultsForKey:@"route_cache"                   ifMissing:kDefaultRouteCache max:7 min:0 writeToShared:YES];
}

- (bool) useCaching
{
    return [self getBoolFromDefaultsForKey:@"use_caching"                   ifMissing:YES writeToShared:YES];
}

- (int)vehicleLocatorDistance
{
    return [self getIntFromDefaultsForKey:@"vehicle_locator_distance"       ifMissing:(int)0 max:800 min:0 writeToShared:NO];
}

- (bool) vehicleLocations
{
    return self.vehicleLocatorDistance!=0;
}

- (bool) debugXML
{
    return [self getBoolFromDefaultsForKey:@"debug_xml"                     ifMissing:NO writeToShared:NO];
}

- (bool) useChrome
{
    return [self getBoolFromDefaultsForKey:@"chrome"                        ifMissing:NO writeToShared:NO];
}

- (int) networkTimeout
{
	
	return  [self getIntFromDefaultsForKey:@"network_timeout2"              ifMissing:kDefaultNetworkTimeout max:60 min:0 writeToShared:YES];
}

- (bool) alarmInitialWarning
{
	return [self getBoolFromDefaultsForKey:@"alarm_initial_10_min_warning"	ifMissing:YES writeToShared:NO];
}

- (bool) googleMapApp
{
	return [self getBoolFromDefaultsForKey:@"google_maps"                   ifMissing:YES writeToShared:NO];
}
- (NSString*)alarmSoundFile
{
    NSString *fileName = [self getStringFromDefaultsForKey:@"alarm_sound"   ifMissing:@"Train_Honk_Horn_2x-Mike_Koenig-157974048.aif"];

    DEBUG_LOG(@"alarmSoundFile %@\n", fileName);
    return fileName;
}


- (bool)searchBookmarks
{
    return [self getBoolFromDefaultsForKey:@"search_bookmarks"      ifMissing:YES writeToShared:NO];
}

- (bool)searchRoutes
{
    return [self getBoolFromDefaultsForKey:@"search_routes"         ifMissing:YES writeToShared:NO];
}

- (bool)searchStations
{
    return [self getBoolFromDefaultsForKey:@"search_stations"       ifMissing:YES writeToShared:NO];
}

- (bool)useBetaVehicleLocator
{
    return [self getBoolFromDefaultsForKey:@"use_beta_vehicle_locator" ifMissing:YES writeToShared:NO];
}

- (bool)showTrips
{
    return [self getBoolFromDefaultsForKey:@"show_trips" ifMissing:NO writeToShared:NO];
}


- (NSString *) triMetProtocol
{
    bool https = [self getBoolFromDefaultsForKey:@"trimet_https"	ifMissing:YES writeToShared:YES];
    
    return https ? @"https" : @"http";
}

- (NSString*)busIcon
{
    //  Currently this feature is disabled - so I return a default value.
    
    return @"icon_arrow_up.png";
    
    /*
     
    NSString *fileName = nil;
    
    if (useWatchSettings)
    {
        fileName = [self getStringFromDefaultsForKey:@"watch_bus_icon"   ifMissing:@"icon_arrow_up.png"];

    }
    else
    {
        fileName = [self getStringFromDefaultsForKey:@"bus_icon"   ifMissing:@"icon_arrow_up.png"];
    }
    
    
    DEBUG_LOG(@"bus icon %@\n", fileName);
    return fileName;
     
     */
}


@end
