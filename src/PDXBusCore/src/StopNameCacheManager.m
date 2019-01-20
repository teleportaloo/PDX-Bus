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
#import "XMLMultipleDepartures.h"

#define kStopNameCacheLocation                      0
#define kStopNameCacheLongDescription               1
#define kStopNameCacheShortDescription              2
#define kStopNameCacheArraySizeWithShortDescription 3

@implementation StopNameCacheManager

+ (instancetype)cache
{
     return [[[self class] alloc] init];
}

- (instancetype)init
{
    if ((self = [super initWithFileName:@"stopNameCache.plist"]))
    {
        self.maxSize               = 55;
    }
    
    return self;
}

+ (NSString *)shortDirection:(NSString *)dir
{
    static NSDictionary *directions = nil;
    
    if (directions == nil)
    {
        directions = @{
                       @"Northbound"       :@"N",
                       @"Southbound"       :@"S",
                       @"Eastbound"        :@"E",
                       @"Westbound"        :@"W",
                       @"Northeastbound"   :@"NE",
                       @"Southeastbound"   :@"SE",
                       @"Southwestbound"   :@"SW",
                       @"Northwestbound"   :@"NW" };
    }

    if (dir == nil)
    {
        return @"";
    }
    
    NSString *result = directions[dir];
    
    if (result == nil)
    {
        return dir;
    }
    return result;
}

+ (NSString *)getShortName:(NSArray *)data
{
    if (data)
    {
        if (data.count >= kStopNameCacheArraySizeWithShortDescription)
        {
            return data[kStopNameCacheShortDescription];
        }
        return data[kStopNameCacheLongDescription];
    }
    return nil;
}

+ (NSString *)getLongName:(NSArray *)data
{
    if (data)
    {
        return data[kStopNameCacheLongDescription];
    }
    return nil;
}

+ (NSString *)getStopId:(NSArray *)data
{
    if (data)
    {
        return data[kStopNameCacheLocation];
    }
    return nil;
}

- (NSDictionary *)getStopNames:(NSArray<NSString*> *)stopIds fetchAndCache:(bool)fetchAndCache updated:(bool*)updated completion:(void (^ __nullable)(int item))completion
{
    NSMutableArray<NSString*> *itemsToFetch = [NSMutableArray array];
    NSMutableDictionary<NSString *, NSArray*> *names = [NSMutableDictionary dictionary];
    int items = 0;
    
    for (NSString *stopId in stopIds)
    {
        NSArray *cachedData = [self getCachedQuery:stopId];
        NSArray *result = nil;
    
        // Need to check if this is an old cache with only two items in it, if so
        // we read it again.
        
        if (cachedData==nil)
        {
            if (fetchAndCache)
            {
                [itemsToFetch addObject:stopId];
            }
            else
            {
                NSString *name = [NSString stringWithFormat:@"Stop ID %@ (getting full name)",stopId];
                result = @[stopId, name, name];
                if (updated)
                {
                    *updated = NO;
                }
                names[stopId] = result;
            }
        }
        else
        {
            NSData *data = cachedData[kCacheData];
#ifdef BASE_IOS12
            // Untested
            NSError *error = nil;
            result =[NSKeyedUnarchiver unarchivedObjectOfClass:[NSArray class] fromData:data error:&error];
#else
            result =[NSKeyedUnarchiver unarchiveObjectWithData:data];
#endif
            if (fetchAndCache && result && result.count < (kStopNameCacheArraySizeWithShortDescription))
            {
                [itemsToFetch addObject:stopId];
            }
            else
            {
                names[stopId] = result;
                
                if (completion)
                {
                    completion(items);
                    items++;
                }
            }
        }
    }
    
    if (itemsToFetch.count > 0 && fetchAndCache)
    {
    
        NSArray *batches = [XMLMultipleDepartures batchesFromEnumerator:stopIds selector:@selector(self)  max:INT_MAX];
        int batch = 0;
    
        while (batch < batches.count)
        {
            XMLMultipleDepartures *multiple = [XMLMultipleDepartures xmlWithOptions:DepOptionsOneMin | DepOptionsNoDetours];
        
            // multiple.oneTimeDelegate = self.backgroundTask.callbackWhenFetching;
            
            [multiple getDeparturesForLocations:batches[batch]];
            
            for (XMLDepartures * dep in multiple)
            {
                if (dep.locid)
                {
                    NSString *longDesc = nil;
                    NSString *shortDesc = nil;
                    NSString *stopId = dep.locid;
                
                    bool cache = NO;
                
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
                
                    if (dep.locid && longDesc && shortDesc)
                    {
                        NSArray *result = @[dep.locid, longDesc, shortDesc];
                        if (updated)
                        {
                            *updated = YES;
                        }
                        
                        names[stopId] = result;
                        
                        if (cache)
                        {
#ifdef BASE_IOS12
                            // Untested
                            NSError *error = nil;
                            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:result requiringSecureCoding:NO error:&error];
#else
                            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:result];
#endif
                            [self addToCache:stopId item:data write:YES];
                        }
                    }
                }
                if (completion)
                {
                    completion(items);
                    items++;
                }
            }
            batch++;
        }
    }

    return names;
}

@end
