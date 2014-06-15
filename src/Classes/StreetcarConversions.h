//
//  StreetcarConversions.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/13/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "MemoryCaches.h"

@interface StreetcarConversions : NSObject <ClearableCache>
{
    NSMutableDictionary *_streetcarMapping;
}

@property (nonatomic, retain) NSMutableDictionary *streetcarMapping;


+ (StreetcarConversions *)getSingleton;
+ (NSDictionary *)getStreetcarPlatforms;
+ (NSDictionary *)getStreetcarDirections;
+ (NSDictionary *)getStreetcarShortNames;
+ (NSDictionary *)getStreetcarBlockMap;
+ (NSDictionary *)getStreetcarRoutes;
+ (NSDictionary *)getSubstitutions;

@end
