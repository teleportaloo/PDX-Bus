//
//  StopNameCacheManager.m
//  PDXBusCore
//
//  Created by Andrew Wallace on 5/16/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "StopNameCacheManager.h"
#import "XMLDepartures.h"

@implementation StopNameCacheManager

- (id)init
{
    if ((self = [super initWithFileName:@"stopNameCache.plist"]))
    {
        self.maxSize               = 25;
    }
    
    return self;
}

+ (NSString *)shortDirection:(NSString *)dir
{
    static NSDictionary *directions = nil;
    
    if (directions == nil)
    {
         directions = [[NSDictionary alloc] initWithObjectsAndKeys:
                                 @"N",   @"Northbound",
                                 @"S",   @"Southbound",
                                 @"E",   @"Eastbound",
                                 @"W",   @"Westbound",
                                 @"NE",  @"Northeastbound",
                                 @"SE",  @"Southeastbound",
                                 @"SW",  @"Southwestbound",
                                 @"NW",  @"Northwestbound",
                                 nil];
    }

    if (dir == nil)
    {
        return @"";
    }
    
    NSString *result = [directions objectForKey:dir];
    
    if (result == nil)
    {
        return dir;
    }
    return result;
}

+ (NSString *)getShortName:(NSArray *)data
{
    if (data.count >= kStopNameCacheArraySizeWithShortDescription)
    {
        return [data objectAtIndex:kStopNameCacheShortDescription];
    }
    return [data objectAtIndex:kStopNameCacheLongDescription];
}

+ (NSString *)getLongName:(NSArray *)data
{
    return [data objectAtIndex:kStopNameCacheLongDescription];
}

- (NSArray *)getStopNameAndCache:(NSString *)stopId
{
    NSArray *cachedData = [self getCachedQuery:stopId];
    NSArray *result = nil;
    
    
    // Need to check if this is an old cache with only two items in it, if so
    // we read it again.
    
    if (cachedData !=nil)
    {
        NSData *data = [cachedData objectAtIndex:kCacheData];
        result =[NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    
    if (cachedData == nil || (result && result.count < (kStopNameCacheArraySizeWithShortDescription)))
    {
        XMLDepartures *dep = [[[ XMLDepartures alloc ] init] autorelease];
        [dep getDeparturesForLocation:stopId];
        
        NSString *longDesc = nil;
        NSString *shortDesc = nil;
        
        
        bool cache= NO;

        
        if (dep.locDesc !=nil)
        {
            if (dep.locDir.length > 0)
            {
            
                longDesc = [NSString stringWithFormat:@"%@ (%@)", dep.locDesc, dep.locDir];
                shortDesc = [NSString stringWithFormat:@"%@: %@", [StopNameCacheManager shortDirection:dep.locDir], dep.locDesc];
            }
            else
            {
                longDesc = dep.locDesc;
                shortDesc = longDesc;
            }
            cache = YES;
            
        }
        else
        {
            longDesc  = [NSString stringWithFormat:@"Stop ID - %@", dep.locid];
            shortDesc = longDesc;
        }
        
        result = [NSArray arrayWithObjects:stopId, longDesc, shortDesc, nil];
        
        
        if (cache)
        {
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:result];
            
            [self addToCache:stopId item:data write:YES];
        }
        
        return result;
    }
    else
    {
        
        
        return result;
    }
}

@end
