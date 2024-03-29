//
//  KMLRoutes.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/4/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "KMLRoutes.h"
#import "DebugLogging.h"
#import "ShapeRoutePath.h"
#import "TriMetInfo.h"
#import "MapAnnotationImageFactory.h"
#import "QueryCacheManager.h"
#import "Reachability.h"
#import "ShapeMutableSegment.h"
#import "NSDictionary+Types.h"
#import "TriMetXMLSelectors.h"
#import "BackgroundDownloader.h"

#define kQuery @""

#define kProbeKey kKmlkey(@"100", @"0")
#define kLastAttemptKey     @"lastAttempt"

@interface KMLRoutes () {
    SEL _currentSelector;
}

@property (nonatomic, strong) KMLPlacemark *currentPlacemark;
@property (nonatomic, copy) NSString *currentAttribute;
@property (nonatomic, strong) NSMutableDictionary <NSString *, KMLPlacemark *> *routes;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSValue *> *selsForProps;


@end

@implementation KMLRoutes

@dynamic keyEnumerator;

static QueryCacheManager *kmlCache = nil;

- (instancetype)init {
    if (self = [super init]) {
        [KMLRoutes initCaches];
        self.selsForProps = [NSMutableDictionary dictionary];
        self.giveUp = 90;
    }
    
    return self;
}

+ (void)initCaches {
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        kmlCache = [QueryCacheManager cacheWithFileName:@"kmlCache.plist"];
        kmlCache.setAgedOutFlagIfOld = YES;
        kmlCache.maxSize = INT_MAX;
        kmlCache.ageOutDays = Settings.kmlAgeOut;
    });
}

+ (void)deleteCacheFile {
    [KMLRoutes initCaches];
    [kmlCache deleteCacheFile];
}

- (int)daysToAutoload {
    return [kmlCache daysLeftInCacheIncludingToday:kProbeKey];
}

- (int)cacheAgeInDays {
    return [kmlCache cacheAgeInDays:kProbeKey];
}

- (NSDate *)cacheDate
{
    return [kmlCache cacheDate:kProbeKey];
}

- (NSUInteger)sizeInBytes {
    return [kmlCache sizeInBytes];
}

- (NSEnumerator<NSString *> *)keyEnumerator {
    return [kmlCache keyEnumerator];
}

XML_START_ELEMENT(Document) {
    self.routes = [NSMutableDictionary dictionary];
    _hasData = YES;
}

XML_END_ELEMENT(Document) {
    [self.routes enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, KMLPlacemark *_Nonnull obj, BOOL *_Nonnull stop) {

        NSError *error = nil;
        NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:obj.path requiringSecureCoding:NO error:&error];
        LOG_NSERROR(error);

        [kmlCache addToCache:key item:archive write:NO];
                
    }];
    
    self.routes = nil;
}

XML_START_ELEMENT(Placemark) {
    self.currentPlacemark = [KMLPlacemark new];
    self.currentPlacemark.path = [ShapeRoutePath new];
}

XML_END_ELEMENT(Placemark) {
    NSString *route = self.currentPlacemark.strInternalRouteNumber;
    NSString *direction = self.currentPlacemark.dir;
    
    if (route && direction && self.currentPlacemark.path.segments && self.currentPlacemark.path.segments.count > 0) {
        NSString *key = kKmlkey(route, direction);
        KMLPlacemark *item = self.routes[key];
        
        if (item == nil) {
            [self.routes setObject:self.currentPlacemark forKey:key];
            self.currentPlacemark.path.route = self.currentPlacemark.internalRouteNumber;
            
            NSString *publicRoute = self.currentPlacemark.displayRouteNumber;
            
            if (publicRoute == nil || [publicRoute isEqualToString:kKmlNoRouteNumber]) {
                self.currentPlacemark.path.desc = self.currentPlacemark.routeDescription;
            } else {
                self.currentPlacemark.path.desc = [NSString stringWithFormat:@"%@ %@", self.currentPlacemark.displayRouteNumber, self.currentPlacemark.routeDescription];
            }
            
            self.currentPlacemark.path.dirDesc = self.currentPlacemark.dirDesc;
        } else {
            [item.path.segments addObjectsFromArray:self.currentPlacemark.path.segments];
        }
    }
    
    self.currentPlacemark = nil;
}

XML_START_ELEMENT(Data) {
    self.currentAttribute = XML_NON_NULL_ATR_STR(@"name");
}

XML_END_ELEMENT(Data) {
    self.currentAttribute = nil;
}

- (SEL)selForProp:(NSString *)elementName {
    NSValue *cache = self.selsForProps[elementName];
    
    if (cache == nil) {
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"setXml_%@:", elementName]);
        self.selsForProps[elementName] = [NSValue valueWithPointer:selector];
        return selector;
    }
    
    return cache.pointerValue;
}

XML_START_ELEMENT(value) {
    _currentSelector = [self selForProp:self.currentAttribute];
    
    if (_currentSelector != nil && [self.currentPlacemark respondsToSelector:_currentSelector]) {
        self.contentOfCurrentProperty = [NSMutableString string];
    }
}

XML_END_ELEMENT(value) {
    if (self.contentOfCurrentProperty) {
        if (_currentSelector != nil) {
            void (*setter)(id, SEL, NSString *) = (void *)[self.currentPlacemark methodForSelector:_currentSelector];
            setter(self.currentPlacemark, _currentSelector, self.contentOfCurrentProperty);
            // [self.currentPlacemark performSelector:_currentSelector withObject:self.contentOfCurrentProperty];
        }
        
        self.contentOfCurrentProperty = nil;
        _currentSelector = nil;
    }
}

XML_START_ELEMENT(coordinates) {
    self.contentOfCurrentProperty = [NSMutableString string];
}

XML_END_ELEMENT(coordinates) {
    if (self.contentOfCurrentProperty) {
        NSScanner *scanner = [NSScanner scannerWithString:self.contentOfCurrentProperty];
        
        double lat;
        double lng;
              
        ShapeMutableSegment *segment = [[ShapeMutableSegment alloc] init];
        
        while (!scanner.isAtEnd) {
            @autoreleasepool {
                if ([scanner scanDouble:&lng]) {
                    if (!scanner.isAtEnd) {
                        scanner.scanLocation++;
                        
                        if (!scanner.isAtEnd) {
                            if ([scanner scanDouble:&lat]) {
                                ShapeCoord *coord = [[ShapeCoord alloc] init];
                                coord.latitude = lat;
                                coord.longitude = lng;
                                [segment.coords addObject:coord];
                                
                                while (!scanner.isAtEnd && [self.contentOfCurrentProperty characterAtIndex:scanner.scanLocation]!=' ')
                                {
                                    scanner.scanLocation++;
                                }
                            } else {
                                ERROR_LOG(@"lng fail");
                            }
                        }
                    }
                } else {
                    ERROR_LOG(@"lat fail");
                }
            }
        }
        
        ShapeCompactSegment *compact = segment.compact;
        
        [self.currentPlacemark.path.segments addObject:compact];
        
        self.contentOfCurrentProperty = nil;
    }
}

- (NSString *)fullAddressForQuery:(NSString *)query {
    return [NSString stringWithFormat:@"https://developer.trimet.org/gis/data/tm_routes.kml" ];
}

- (bool)parseRawData {
    [kmlCache addToCache:kLastAttemptKey item:[NSData new] write:NO];
    bool result = [super parseRawData];
    [kmlCache writeCache];
    return result;
}


- (void)createCacheFromBackground
{
    @synchronized (kmlCache) {
        self.oneTimeDelegate = nil;
        [self parseRawData];
    }
}

- (bool)backgroundFetching
{
    BackgroundDownloader *downloader = [BackgroundDownloader sharedInstance];
    
    NSString *query = [self fullAddressForQuery:kQuery];
    
    return [downloader isFetching:query];
}

- (void)fetchInBackgroundForced:(bool)always
{
    @synchronized (kmlCache) {
        
        // If the file is missing or corrupt don't keep trying, we actually put an item in the cache
        // to say when the last attempt was.  Try once a day.
        
        int lastTriedDaysAgo = [kmlCache cacheAgeInDays:kLastAttemptKey];
        
        if ((!self.cached && (lastTriedDaysAgo >= 1 || lastTriedDaysAgo == kNoCache)) || always) {
            BackgroundDownloader *downloader = [BackgroundDownloader sharedInstance];
    
            [downloader startFetchInBackground:self query:kQuery completion:^(TriMetXML *xml, BackgroundFinalCompletion completionHandler) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    KMLRoutes *kml = (KMLRoutes *)xml;
                    [kml createCacheFromBackground];
                    completionHandler();
                });
            }];
        }
    }
}

- (NSString *)downloadProgress
{
    NSString *downloadProgress = nil;
    NSString *kmlQuery = [self fullAddressForQuery:kQuery];
    
    BackgroundDownloader *downloader = [BackgroundDownloader sharedInstance];
    
    if ([downloader isFetching:kmlQuery]) {
        downloadProgress = [downloader progess:kmlQuery];
    }
    
    return downloadProgress;
}

- (void)cancelBackgroundFetch
{
    @synchronized (kmlCache) {
        NSString *kmlQuery = [self fullAddressForQuery:kQuery];
        
        BackgroundDownloader *downloader = [BackgroundDownloader sharedInstance];
        
        if ([downloader isFetching:kmlQuery])
        {
            [downloader cancel:kmlQuery];
            
        }
    }
}

- (void)fetchNowForced:(bool)always {
    @synchronized (kmlCache) {
        if ((!self.cached || always) && !self.backgroundFetching) {
            // Maybe only do this on wifi
            
            bool fetch = YES;
            
            if (Settings.kmlWifiOnly && !always) {
                Reachability *reachability = [Reachability reachabilityForInternetConnection];
                [reachability startNotifier];
                
                NetworkStatus status = [reachability currentReachabilityStatus];
                
                fetch = (status == ReachableViaWiFi);
            }
            
            if (fetch) {
                [self startParsing:kQuery cacheAction:TriMetXMLNoCaching];
            } else {
                _hasData = NO;
                [self clearItems];
            }
        }
        
    }
}

- (bool)cached {
    if ([self lineCoordsForKey:kProbeKey] == nil || kmlCache.agedOut)
    {
        return NO;
    }
    
    return YES;
}

- (ShapeRoutePath *)lineCoordsForKey:(NSString *)key {
    @synchronized (kmlCache) {

        kmlCache.ageOutDays = Settings.kmlAgeOut;
        NSArray *archive = [kmlCache getCachedQuery:key];
    
        if (archive) {
            NSError *error = nil;
            ShapeRoutePath *path = (ShapeRoutePath *) [NSKeyedUnarchiver unarchivedObjectOfClass:[ShapeRoutePath class]
                                                                                        fromData:archive[kCacheData]
                                                                                    error:&error];
            LOG_NSERROR(error);
            return path;
                
        }
    
        return nil;
    }
}

- (ShapeRoutePath *)lineCoordsForRoute:(NSString *)route direction:(NSString *)dir {
    return [self lineCoordsForKey:kKmlkey(route, dir)];
}

@end
