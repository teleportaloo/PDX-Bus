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
#import "BackgroundDownloader.h"
#import "DebugLogging.h"
#import "NSDictionary+Types.h"
#import "QueryCacheManager.h"
#import "Reachability.h"
#import "SelImpCache.h"
#import "ShapeMutableSegment.h"
#import "ShapeRoutePath.h"
#import "TaskDispatch.h"
#import "TriMetInfo.h"
#import "TriMetXMLSelectors.h"
#import <ctype.h>
#import <xlocale.h> // for strtod_l

#define kQuery @""

#define kProbeKey kKmlkey(@"100", @"0")
#define kLastAttemptKey @"lastAttempt"

@interface KMLRoutes () {
    SelImpPair _currentSelImp;
}

@property(nonatomic, strong) KMLPlacemark *currentPlacemark;
@property(nonatomic, copy) NSString *currentAttribute;
@property(nonatomic, strong)
    NSMutableDictionary<NSString *, KMLPlacemark *> *routes;

@property(nonatomic, strong) SelImpCache selImpCache;

@end

@implementation KMLRoutes

@dynamic keyEnumerator;

static QueryCacheManager *kmlCache = nil;

- (instancetype)init {
    if (self = [super init]) {
        [KMLRoutes initCaches];
        self.selImpCache = NSMutableDictionary.dictionary;
        self.giveUp = 90;
    }

    return self;
}

+ (void)initCaches {
    DoOnce(^{
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

- (NSDate *)cacheDate {
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
    if (self.routes.count > 0 && ![NSThread currentThread].isCancelled) {
        [KMLRoutes deleteCacheFile];
        [self.routes enumerateKeysAndObjectsUsingBlock:^(
                         NSString *_Nonnull key, KMLPlacemark *_Nonnull obj,
                         BOOL *_Nonnull stop) {
          NSError *error = nil;
          NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:obj.path
                                                  requiringSecureCoding:NO
                                                                  error:&error];
          LOG_NSError(error);

          [kmlCache addToCache:key item:archive write:NO];
        }];
        [kmlCache writeCache];
    }

    self.routes = nil;
}

XML_START_ELEMENT(Placemark) {
    self.currentPlacemark = [KMLPlacemark new];
    self.currentPlacemark.path = [ShapeRoutePath new];
}

XML_END_ELEMENT(Placemark) {
    NSString *route = self.currentPlacemark.strInternalRouteNumber;
    NSString *direction = self.currentPlacemark.dir;

    if (route && direction && self.currentPlacemark.path.segments &&
        self.currentPlacemark.path.segments.count > 0) {
        NSString *key = kKmlkey(route, direction);
        KMLPlacemark *item = self.routes[key];

        if (item == nil) {
            [self.routes setObject:self.currentPlacemark forKey:key];
            self.currentPlacemark.path.route =
                self.currentPlacemark.internalRouteNumber;

            NSString *publicRoute = self.currentPlacemark.displayRouteNumber;

            if (publicRoute == nil ||
                [publicRoute isEqualToString:kKmlNoRouteNumber]) {
                self.currentPlacemark.path.desc =
                    self.currentPlacemark.routeDescription;
            } else {
                self.currentPlacemark.path.desc = [NSString
                    stringWithFormat:@"%@ %@",
                                     self.currentPlacemark.displayRouteNumber,
                                     self.currentPlacemark.routeDescription];
            }

            self.currentPlacemark.path.dirDesc = self.currentPlacemark.dirDesc;
            self.currentPlacemark.path.frequent =
                ([self.currentPlacemark.frequent
                     caseInsensitiveCompare:@"true"] == NSOrderedSame);
        } else {
            [item.path.segments
                addObjectsFromArray:self.currentPlacemark.path.segments];
        }
    }

    self.currentPlacemark = nil;
}

XML_START_ELEMENT(Data) {
    self.currentAttribute = XML_NON_NULL_ATR_STR(@"name");
}

XML_END_ELEMENT(Data) { self.currentAttribute = nil; }

XML_START_ELEMENT(value) {
    _currentSelImp = [self.selImpCache selImpForElement:self.currentAttribute
                                                selName:XML_PROP_SETTER_NAME
                                                    obj:self.currentPlacemark
                                                  debug:XML_PROP_DEBUG];

    if (_currentSelImp.imp != nil) {
        self.contentOfCurrentProperty = [NSMutableString string];
    }
}

XML_END_ELEMENT(value) {
    if (self.contentOfCurrentProperty) {
        if (_currentSelImp.imp != nil) {
            XML_PROP_SETTER_IMP setter = (void *)_currentSelImp.imp;
            setter(self.currentPlacemark, _currentSelImp.sel,
                   self.contentOfCurrentProperty);
            _currentSelImp.imp = nil;
            _currentSelImp.sel = nil;
        }
        self.contentOfCurrentProperty = nil;
    }
}

XML_START_ELEMENT(coordinates) {
    self.contentOfCurrentProperty = [NSMutableString string];
}

XML_END_ELEMENT(coordinates) {
    if (self.contentOfCurrentProperty) {
        ShapeMutableSegment *segment = [[ShapeMutableSegment alloc] init];

        [self parseLonLatTriplesIntoSegment:segment];

        ShapeCompactSegment *compact = segment.compact;

        [self.currentPlacemark.path.segments addObject:compact];

        self.contentOfCurrentProperty = nil;
    }
}

static inline void skipDelims(const char **p) {
    // Skip spaces, tabs, commas
    while (**p == ',' || isspace((unsigned char)**p)) {
        (*p)++;
    }
}

static BOOL scanDoubleFast(const char **p, locale_t loc, double *out) {
    skipDelims(p);
    const char *start = *p;
    char *endptr = NULL;
    errno = 0;
    double v = strtod_l(start, &endptr, loc); // C-locale: '.' decimal
    if (endptr == start) {
        return NO;
    } // no parse
    if (!isfinite(v) || errno == ERANGE) {
        *p = endptr;
        return NO;
    }
    *p = endptr;
    *out = v;
    return YES;
}

- (void)parseLonLatTriplesIntoSegment:(ShapeMutableSegment *)segment {
    const char *s = [self.contentOfCurrentProperty UTF8String];
    if (!s)
        return;
    const char *p = s;

    // Force numeric parsing to C locale (dot decimal), independent of user
    // locale
    locale_t cLoc = newlocale(LC_NUMERIC_MASK, "C", NULL);
    if (!cLoc)
        cLoc = uselocale(NULL); // fallback: current locale

    while (*p) {
        double lon, lat;

        if (!scanDoubleFast(&p, cLoc, &lon)) { // couldn't read first number →
                                               // skip one char and continue
            p++;
            continue;
        }
        // Expect delimiter(s) then second number
        if (!scanDoubleFast(&p, cLoc, &lat)) {
            // second number missing → give up on this token, continue scanning
            continue;
        }

        // Optionally skip the 3rd (alt) if present; ignore its value
        const char *save = p;
        double throwawayAlt;
        if (!scanDoubleFast(&p, cLoc, &throwawayAlt)) {
            // Not a fatal problem; we just didn’t have an alt here.
            p = save;
        }

        // Validate ranges; skip bad pairs
        if (lat >= -90.0 && lat <= 90.0 && lon >= -180.0 && lon <= 180.0) {
            ShapeCoord *coord = [[ShapeCoord alloc] init];
            coord.latitude = lat; // NOTE: input is lon,lat
            coord.longitude = lon;
            [segment.coords addObject:coord];
        }

        // Move to next group separator (space/newline/etc.)
        while (*p && !isspace((unsigned char)*p)) {
            if (*p == ',') {
                p++;
                continue;
            }
            // If there are other separators in your data, handle here.
            p++;
        }
        // Skip whitespace before next token
        while (isspace((unsigned char)*p)) {
            p++;
        }
    }

    if (cLoc && cLoc != uselocale(NULL)) {
        freelocale(cLoc);
    }
}

- (NSString *)fullAddressForQuery:(NSString *)query {
    return
        [NSString stringWithFormat:
                      @"https://developer.trimet.org/gis/data/tm_routes.kml"];
}

- (bool)parseRawData {
    [kmlCache addToCache:kLastAttemptKey item:[NSData new] write:NO];
    bool result = [super parseRawData];
    [kmlCache writeCache];
    return result;
}

- (void)createCacheFromBackground {
    @synchronized(kmlCache) {
        self.oneTimeDelegate = nil;
        [self parseRawData];
    }
}

- (bool)backgroundFetching {
    BackgroundDownloader *downloader = [BackgroundDownloader sharedInstance];

    NSString *query = self.queryTransformer(self, kQuery);

    return [downloader isFetching:query];
}

- (void)fetchInBackgroundForced:(bool)always {
    @synchronized(kmlCache) {

        // If the file is missing or corrupt don't keep trying, we actually put
        // an item in the cache to say when the last attempt was.  Try once a
        // day.

        int lastTriedDaysAgo = [kmlCache cacheAgeInDays:kLastAttemptKey];

        if ((!self.cached &&
             (lastTriedDaysAgo >= 1 || lastTriedDaysAgo == kNoCache)) ||
            always) {
            BackgroundDownloader *downloader =
                [BackgroundDownloader sharedInstance];

            [downloader
                startFetchInBackground:self
                                 query:kQuery
                            completion:^(
                                TriMetXML *xml,
                                BackgroundFinalCompletion completionHandler) {
                              WorkerTask(^{
                                KMLRoutes *kml = (KMLRoutes *)xml;
                                [kml createCacheFromBackground];
                                completionHandler();
                              });
                            }];
        }
    }
}

- (NSString *)downloadProgress {
    NSString *downloadProgress = nil;
    NSString *kmlQuery = self.queryTransformer(self, kQuery);

    BackgroundDownloader *downloader = [BackgroundDownloader sharedInstance];

    if ([downloader isFetching:kmlQuery]) {
        downloadProgress = [downloader progess:kmlQuery];
    }

    return downloadProgress;
}

- (void)cancelBackgroundFetch {
    @synchronized(kmlCache) {
        NSString *kmlQuery = self.queryTransformer(self, kQuery);

        BackgroundDownloader *downloader =
            [BackgroundDownloader sharedInstance];

        if ([downloader isFetching:kmlQuery]) {
            [downloader cancel:kmlQuery];
        }
    }
}

- (void)fetchNowForced:(bool)always {
    @synchronized(kmlCache) {
        if ((!self.cached || always) && !self.backgroundFetching) {
            // Maybe only do this on wifi

            bool fetch = YES;

            if (Settings.kmlWifiOnly && !always) {
                Reachability *reachability =
                    [Reachability reachabilityForInternetConnection];
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
    if ([self lineCoordsForKey:kProbeKey] == nil || kmlCache.agedOut) {
        return NO;
    }

    return YES;
}

- (ShapeRoutePath *)lineCoordsForKey:(NSString *)key {
    @synchronized(kmlCache) {

        kmlCache.ageOutDays = Settings.kmlAgeOut;
        NSArray<NSData *> *archive = [kmlCache getCachedQuery:key];

        if (archive) {
            NSError *error = nil;

            if (archive[kCacheData] && archive[kCacheData].length != 0) {
                ShapeRoutePath *path = (ShapeRoutePath *)[NSKeyedUnarchiver
                    unarchivedObjectOfClass:[ShapeRoutePath class]
                                   fromData:archive[kCacheData]
                                      error:&error];
                LOG_NSError(error);
                return path;
            }
            return nil;
        }

        return nil;
    }
}

- (ShapeRoutePath *)lineCoordsForRoute:(NSString *)route
                             direction:(NSString *)dir {
    return [self lineCoordsForKey:kKmlkey(route, dir)];
}

@end
