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


#define DEBUG_LEVEL_FOR_FILE kLogSettings

#import "Settings.h"
#import "TriMetTypes.h"
#import "DebugLogging.h"
#import "PDXBusCore.h"
#import "FormatDistance.h"

@interface Settings () {
    NSUserDefaults *_defaults;
}

+ (Settings *)sharedInstance;

@end


@implementation Settings

#define kiCloudTokenKey       @"org.teleportaloo.PDXBus.UbiquityIdentityToken"
#define kSharedDomain         @"group.teleportaloo.pdxbus"
#define kSystemWideDetoursKey @"hidden_system_wide_detours"
#define kTransitioned         @"hidden_transitioned"

- (void)transition:(NSArray *)array from:(NSUserDefaults *)old {
    for (NSString *key in array) {
        NSObject *obj = [old objectForKey:key];
        
        if (obj) {
            DEBUG_LOG(@"Transitioning %@", key);
            [_defaults setObject:obj forKey:key];
            [old removeObjectForKey:key];
        }
    }
}

- (instancetype)init {
    
     
    
    if ((self = [super init])) {
        
        
#if !TARGET_OS_MACCATALYST
         _defaults = [[NSUserDefaults alloc] initWithSuiteName:kSharedDomain];
#ifdef PDXBUS_WATCH
        NSString *defaults = @"Defaults-watchOS";
#else
        NSString *defaults = @"Defaults-iOS";
        
#endif
#else
        NSString *defaults = @"Defaults-macOS";
        _defaults = [NSUserDefaults standardUserDefaults];
#endif

        NSDictionary *defaultValues = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:defaults ofType:@"plist"]];
        [_defaults registerDefaults:defaultValues];
        
#ifndef PDXBUS_WATCH
#if !TARGET_OS_MACCATALYST
        // Transitions to a shared domain by removing the old one into the new
        // domain.
        
        BOOL transitioned = YES;
        
        if ([_defaults objectForKey:kTransitioned] == nil) {
            transitioned = NO;
        } else {
            transitioned = [_defaults boolForKey:kTransitioned];
        }
        
        if (!transitioned) {
            NSUserDefaults *old = [NSUserDefaults standardUserDefaults];
            
            [self transition:defaultValues.allKeys from:old];
            [self transition:@[kiCloudTokenKey, kSystemWideDetoursKey] from:old];
            
            [_defaults setBool:YES forKey:kTransitioned];
            
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication);
        }
#endif
#endif // ifdef PDXBUS_WATCH
    }
    
    return self;
}

+ (Settings *)sharedInstance {
    static Settings *singleton = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        singleton = [[Settings alloc] init];
    });
    return singleton;
}

// Macros create setters and getters a but like @dynamic but not automatic.
// uncrustify-off
// Note - uncrustify messes this up even if we try to switch it off.

#define GET_BOOL(PROPERTY, V)                                                  \
+ (bool)PROPERTY {                                                             \
    bool setting = [Settings.sharedInstance->_defaults boolForKey:(V)];        \
    DEBUG_LOG(@"Setting " V " %@", setting ? @"True" : @"False");              \
    return setting;                                                            \
}

#define GET_FLOAT(PROPERTY,V)                                                  \
+ (float)PROPERTY {                                                            \
    float setting = [Settings.sharedInstance->_defaults floatForKey: (V)];     \
    DEBUG_LOG(@"Setting " V " %f", setting);                                   \
    return setting;                                                            \
}

#define GET_INT(PROPERTY,V)                                                    \
+ (int)PROPERTY {                                                              \
    int setting = (int)[Settings.sharedInstance->_defaults integerForKey:(V)]; \
    DEBUG_LOG(@"Setting " V " %d", setting);                                   \
    return setting;                                                            \
}

#define GET_STR(PROPERTY,V)                                                    \
+ (NSString*)PROPERTY {                                                        \
    NSString *setting = [Settings.sharedInstance->_defaults stringForKey:(V)]; \
    DEBUG_LOG(@"Setting " V " %@", setting);                                   \
    return setting;                                                            \
}

#define G_OBJ(PROPERTY,V)                                                      \
+ (NSObject*)PROPERTY {                                                        \
    NSObject *setting = [Settings.sharedInstance->_defaults objectForKey:(V)]; \
    DEBUG_LOG(@"Setting " V " %p", setting);                                   \
    return setting;                                                            \
}

#define S_OBJ(SET_PROPERTY, V)                                                 \
+ (void)SET_PROPERTY:(NSObject*)setting {                                      \
    [Settings.sharedInstance->_defaults setObject:setting forKey:(V)];         \
    DEBUG_LOG(@"Set Setting " V " %p", setting);                               \
}

#define S_BOOL(SET_PROPERTY, V)                                                \
+ (void)SET_PROPERTY:(_Bool)setting {                                          \
    [Settings.sharedInstance->_defaults setBool:setting forKey:(V)];           \
    DEBUG_LOG(@"Set Setting " V " %@", setting ? @"True" : @"False");          \
}

#define SET_GET_BOOL(READ, V, SET)   \
    GET_BOOL(READ, V)             \
    S_BOOL(SET, V)

#define SET_GET_OBJ(READ, V, SET)    \
    G_OBJ(READ, V)              \
    S_OBJ(SET, V)

//  OP  Type  Get Method                       Value to Read                  Set Method
    GET_STR  (minsForArrivals,                @"mins_for_arrivals"                                                )
    GET_BOOL (autoCommute,                    @"auto_commute"                                                     )
    GET_BOOL (bookmarksAtTheTop,              @"bookmarks_at_the_top"                                             )
SET_GET_BOOL (locateToolbarIcon,              @"locate_toolbar_icon",         setLocateToolbarIcon                )
    GET_BOOL (commuteButton,                  @"commute_button"                                                   )
SET_GET_BOOL (flashingLightIcon,              @"flashing_light_icon",         setFlashingLightIcon                )
    GET_INT  (rawToolbarColors,               @"toolbar_colors"                                                   )
SET_GET_BOOL (flashLed,                       @"flash_led",                   setFlashLed                         )
SET_GET_BOOL (flashingLightWarning,           @"flashing_light_warning",      setFlashingLightWarning             )
    GET_BOOL (autoRefresh,                    @"auto_refresh"                                                     )
    GET_BOOL (groupByArrivalsIcon,            @"group_by_arrivals_icon"                                           )
SET_GET_BOOL (autoLocateShowOptions,          @"auto_locate_show_options",    setAutoLocateShowOptions            )
    GET_BOOL (useAppleGeoLocator,             @"use_apple_geolocator"                                             )
    GET_FLOAT(maxWalkingDistance,             @"max_walking_distance"                                             )
    GET_INT  (travelBy,                       @"travel_by"                                                        )
    GET_INT  (tripMin,                        @"min"                                                              )
    GET_STR  (alarmSoundFile,                 @"alarm_sound"                                                      )
SET_GET_BOOL (showStreetcarMapFirst,          @"streetcar_map_first",         setShowStreetcarMapFirst            )
    GET_BOOL (useChrome,                      @"chrome"                                                           )
    GET_BOOL (searchStations,                 @"search_stations"                                                  )
    GET_BOOL (searchBookmarks,                @"search_bookmarks"                                                 )
    GET_BOOL (searchRoutes,                   @"search_routes"                                                    )
    GET_INT  (rawKmlRoutes,                   @"kml_routes2"                                                      )
    GET_BOOL (kmlWifiOnly,                    @"kml_route_only_wifi"                                              )
    GET_INT  (vehicleLocatorDistance,         @"vehicle_locator_distance2"                                         )
    GET_FLOAT(useGpsWithin,                   @"proximity_gps"                                                    )
    GET_INT  (xmlViewer,                      @"debug_xml3"                                                       )
    GET_BOOL (progressDebug,                  @"progress_debug"                                                   )
    GET_BOOL (networkInParallel,              @"network_in_parallel"                                              )
    GET_BOOL (showTransitTracker,             @"show_transit_tracker"                                             )
    GET_BOOL (showSizes,                      @"show_sizes"                                                       )
    GET_BOOL (debugCommuter,                  @"debug_commuter"                                                   )
    GET_BOOL (clearCacheOnUnexpectedRestart,  @"clear_cache"                                                      )
    GET_BOOL (useVehicleLocator,              @"use_beta_vehicle_locator"                                         )
    GET_BOOL (showTrips,                      @"show_trips"                                                       )
    GET_BOOL (showDetourIds,                  @"show_detour_ids"                                                  )
    GET_BOOL (useGpsForAllAlarms,             @"use_gps_for_all_alarms"                                           )
    GET_INT  (networkTimeout,                 @"network_timeout2"                                                 )
SET_GET_BOOL (firstLaunchWithiCloudAvailable, @"first_launch_with_icloud",    setFirstLaunchWithiCloudAvailable   )
SET_GET_BOOL (hideWatchDetours,               @"watch_hidden_detours",        setHideWatchDetours                 )
SET_GET_OBJ  (rawSystemWideDetours,           kSystemWideDetoursKey,          setRawSystemWideDetours             )
SET_GET_OBJ  (iCloudToken,                    kiCloudTokenKey,                setRawCloudToken                    )

// uncrustify-on

+ (int)toolbarColors {
    int color = Settings.rawToolbarColors;
    
    // Black does not work with iOS7 - so make it standard instead
    if (color == 0) {
        color = 0xFFFFFF;
    }
    
    return color;
}

+ (int)kmlAgeOut {
    int res = Settings.rawKmlRoutes;
    
    if (res < 0) {
        res = INT_MAX;
    }
    
    return res;
}

+ (bool)kmlManual {
    return Settings.rawKmlRoutes == -1;
}

+ (bool)kmlRoutes {
    return Settings.kmlAgeOut > 0;
}

+ (bool)vehicleLocations {
    return Settings.vehicleLocatorDistance != 0;
}

+ (bool)debugXML {
    return Settings.xmlViewer != 0;
}

+ (void)removeOldSystemWideDetours:(NSSet *)detoursNoLongerFound {
    NSMutableSet *hidden = Settings.hiddenSystemWideDetours.mutableCopy;
    
    for (NSNumber *oldId in detoursNoLongerFound) {
        [hidden removeObject:oldId];
    }
    
    Settings.hiddenSystemWideDetours = hidden;
}

+ (NSSet<NSNumber *> *)hiddenSystemWideDetours {
    NSArray *array = (NSArray *)Settings.rawSystemWideDetours;
    
    if (array == nil) {
        return [NSMutableSet set];
    }
    
    return [NSSet setWithArray:array];
}

+ (void)setHiddenSystemWideDetours:(NSSet<NSNumber *> *)set {
    Settings.rawSystemWideDetours = [set allObjects];
}

+ (void)toggleHiddenSystemWideDetour:(NSNumber *)detourId {
    NSMutableSet<NSNumber *> *hidden = Settings.hiddenSystemWideDetours.mutableCopy;
    
    if ([hidden containsObject:detourId]) {
        [hidden removeObject:detourId];
    } else {
        [hidden addObject:detourId];
    }
    
    Settings.hiddenSystemWideDetours = hidden;
}

+ (bool)isHiddenSystemWideDetour:(NSNumber *)detourId {
    return [Settings.hiddenSystemWideDetours containsObject:detourId];
}

+ (void)setICloudToken:(id)iCloudToken {
    if (iCloudToken) {
#ifdef PDXBUS_WATCH
        Settings.rawCloudToken = [NSKeyedArchiver archivedDataWithRootObject:iCloudToken];
#else
        Settings.rawCloudToken = [NSKeyedArchiver archivedDataWithRootObject:iCloudToken requiringSecureCoding:NO error:nil];
        
#endif
    } else {
        [Settings.sharedInstance->_defaults removeObjectForKey:kiCloudTokenKey];
    }
    
    
}

@end
