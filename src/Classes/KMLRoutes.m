//
//  KMLRoutes.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/4/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "KMLRoutes.h"
#import "DebugLogging.h"
#import "ShapeRoutePath.h"
#import "TriMetInfo.h"
#import "MapAnnotationImage.h"
#import "QueryCacheManager.h"
#import "Reachability.h"

@implementation KMLRoutes

@dynamic keyEnumerator;

static QueryCacheManager *kmlCache = nil;


- (instancetype)init
{
    if (self = [super init])
    {
        [KMLRoutes initCaches];
        _gitHubRouteShapes = [UserPrefs sharedInstance].gitHubRouteShapes;
        self.selsForProps = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (void)initCaches
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        kmlCache = [QueryCacheManager cacheWithFileName:@"kmlCache.plist"];
        kmlCache.maxSize = 999;
    });
}

+ (void)deleteCacheFile
{
    [KMLRoutes initCaches];
    [kmlCache deleteCacheFile];
}

- (NSEnumerator<NSString*> *) keyEnumerator
{
    return [kmlCache.cache keyEnumerator];
}

XML_START_ELEMENT(document)
{
    self.routes = [NSMutableDictionary dictionary];
    _hasData = YES;
}

XML_END_ELEMENT(document)
{
    [self.routes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, KMLPlacemark * _Nonnull obj, BOOL * _Nonnull stop) {
        [kmlCache addToCache:key item:[NSKeyedArchiver archivedDataWithRootObject:obj.path] write:NO];
    }];
    
    [kmlCache writeCache];
    self.routes = nil;
}

XML_START_ELEMENT(placemark)
{
    self.currentPlacemark = [KMLPlacemark data];
    self.currentPlacemark.path =  [ShapeRoutePath data];
}

XML_END_ELEMENT(placemark)
{
    NSString *route = self.currentPlacemark.xroute_number;
    NSString *direction = self.currentPlacemark.xdirection;
    
    if (route && direction && self.currentPlacemark.path.segments && self.currentPlacemark.path.segments.count > 0)
    {
        NSString *key = kKmlkey(route, direction);
        KMLPlacemark *item  = self.routes[key];
        
        if (item == nil)
        {
            [self.routes setObject:self.currentPlacemark forKey:key];
            self.currentPlacemark.path.route = self.currentPlacemark.xroute_number.integerValue;
            
            NSString *publicRoute = self.currentPlacemark.xpublic_route_number;
            
            if ([publicRoute isEqualToString:kKmlNoRouteNumber])
            {
                self.currentPlacemark.path.desc = self.currentPlacemark.xroute_description;
            }
            else
            {
                self.currentPlacemark.path.desc = [NSString stringWithFormat:@"%@ %@", self.currentPlacemark.xpublic_route_number, self.currentPlacemark.xroute_description];
            }
            self.currentPlacemark.path.dirDesc = self.currentPlacemark.xdirection_description;
        }
        else
        {
            [item.path.segments addObjectsFromArray:self.currentPlacemark.path.segments];
        }
    }
    self.self.currentPlacemark = nil;
}

XML_START_ELEMENT(data)
{
    self.currentAttribute = ATRSTR(name);
}

XML_END_ELEMENT(data)
{
    self.currentAttribute = nil;
}

- (SEL)selForProp:(NSString *)elementName
{
    NSString *lowerElement = elementName.lowercaseString;
    NSValue *cache = self.selsForProps[lowerElement];
    
    if (cache == nil)
    {
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"setX%@:", lowerElement]);
        self.selsForProps[lowerElement] = [NSValue valueWithPointer:selector];
        return selector;
    }
    
    return cache.pointerValue;
}


XML_START_ELEMENT(value)
{
    _currentSelector = [self selForProp:self.currentAttribute];
    
    if (_currentSelector!=nil && [self.currentPlacemark respondsToSelector:_currentSelector])
    {
        self.contentOfCurrentProperty = [NSMutableString string];
    }
}

XML_END_ELEMENT(value)
{
    if (self.contentOfCurrentProperty)
    {
        if (_currentSelector!=nil)
        {
            IMP imp = [self.currentPlacemark methodForSelector:_currentSelector];
            void (*func)(id, SEL, NSString *) = (void *)imp;
            func(self.currentPlacemark, _currentSelector, self.contentOfCurrentProperty);
            // [self.currentPlacemark performSelector:_currentSelector withObject:self.contentOfCurrentProperty];
        }
        self.contentOfCurrentProperty = nil;
        _currentSelector = nil;
    }
}

XML_START_ELEMENT(coordinates)
{
    self.contentOfCurrentProperty = [NSMutableString string];
}

XML_END_ELEMENT(coordinates)
{
    if (self.contentOfCurrentProperty)
    {
        NSScanner * scanner = [NSScanner scannerWithString:self.contentOfCurrentProperty];
        
        double lat;
        double lng;
        
        static NSInteger same = 0;
        
        
        ShapeMutableSegment *segment = [[ShapeMutableSegment alloc] init];
        
        while (!scanner.isAtEnd)
        {
            @autoreleasepool {
                
                if ([scanner scanDouble:&lng])
                {
                    if (!scanner.isAtEnd)
                    {
                        scanner.scanLocation++;
                        
                        if (!scanner.isAtEnd)
                        {
                            if ([scanner scanDouble:&lat])
                            {
                                ShapeCoord *coord = [[ShapeCoord alloc] init];
                                coord.latitude = lat;
                                coord.longitude = lng;
                                [segment.coords addObject: coord];
                                if (!scanner.isAtEnd)
                                {
                                    scanner.scanLocation++;
                                }
                            }
                            else
                            {
                                ERROR_LOG(@"lng fail");
                            }
                        }
                    }
                }
                else
                {
                    ERROR_LOG(@"lat fail");
                }
            }
        }
        
        
        ShapeCompactSegment *compact = segment.compact;
        
        
        if (self.currentPlacemark.path.segments.count > 0 && !_gitHubRouteShapes)
        {
            if (![compact isEqual:self.currentPlacemark.path.segments.lastObject])
            {
                [self.currentPlacemark.path.segments addObject:compact];
            }
            else
            {
                same++;
            }
        }
        else
        {
            [self.currentPlacemark.path.segments addObject:compact];
        }
        
        
        self.contentOfCurrentProperty = nil;
    }
}

- (NSString*)fullAddressForQuery:(NSString *)query
{
    if (_gitHubRouteShapes)
    {
        return [NSString stringWithFormat:@"https://raw.githubusercontent.com/teleportaloo/TriMetTestData/master/tm_routes_v3.kml"];
    }
    else
    {
        return [NSString stringWithFormat:@"https://developer.trimet.org/gis/data/tm_routes.kml" ];
    }
}

- (void)fetch
{
    if (!self.cached)
    {
        // Maybe only do this on wifi
        
        bool fetch = YES;
        
        if ([UserPrefs sharedInstance].kmlWifiOnly)
        {
        
            Reachability *reachability = [Reachability reachabilityForInternetConnection];
            [reachability startNotifier];
        
            NetworkStatus status = [reachability currentReachabilityStatus];
            
            fetch = (status == ReachableViaWiFi);
        }
        
        
        if (fetch)
        {
             [self startParsing:@"" cacheAction:TriMetXMLNoCaching];
        }
        else
        {
            _hasData = NO;
            [self clearItems];
        }
    }
}

- (bool)cached
{
    return [self lineCoordsForRoute:@"100" direction:@"0"]!=nil;
}

- (ShapeRoutePath *)lineCoordsForKey:(NSString *)key
{
    kmlCache.ageOutDays = [UserPrefs sharedInstance].kmlAgeOut;
    NSArray *archive = [kmlCache getCachedQuery:key];
    if (archive)
    {
        return [NSKeyedUnarchiver unarchiveObjectWithData:archive[kCacheData]];
    }
    return nil;
}

- (ShapeRoutePath *)lineCoordsForRoute:(NSString *)route direction:(NSString *)dir
{
    return  [self lineCoordsForKey:kKmlkey(route, dir)];
}

@end
