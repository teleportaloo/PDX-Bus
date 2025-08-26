
//
//  TriMetXML.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogXML

#ifndef DEBUGLOGGING
#pragma clang diagnostic ignored "-Wunreachable-code"
#endif

#import "TriMetXML.h"
#import "TriMetTypes.h"
#ifndef PDXBUS_WATCH
#import <SystemConfiguration/SystemConfiguration.h>
#endif
#import "DebugLogging.h"
#import "NSHTTPURLResponse+Headers.h"
#import "QueryCacheManager.h"
#import "SelImpCache.h"
#import "SessionSingleton.h"
#import "Settings.h"
#import "StopNameCacheManager.h"
#import "TaskDispatch.h"
#import "TriMetAppId.h"
#import "TriMetXMLSelectors.h"
#import <objc/runtime.h>

#define kShortTermCacheAge (20 * 60) // 15 mins

#ifdef DEBUGLOGGING
#define DEBUG_XML(s, ...)                                                      \
    if (DEBUG_ON_FOR_FILE) {                                                   \
        NSLog(@"<%-12s: %@> %@", CommonDebugLogStr(DEBUG_LEVEL_FOR_FILE),      \
              NSStringFromClass([self class]),                                 \
              [NSString stringWithFormat:(s), ##__VA_ARGS__]);                 \
    }
#else
#define DEBUG_XML(s, ...)
#endif

@interface TriMetXML <ItemType>() {
}

@property(nonatomic, strong) SelImpCache _Nullable startSels;
@property(nonatomic, strong) SelImpCache _Nullable endSels;
@property(nonatomic) CacheAction currentCacheAction;

@end

#pragma mark Cache

static StopNameCacheManager *stopNameCache = nil;
static NSMutableData *staticParseSyncObject = nil;
static XMLQueryTransformer globalQueryTransformer;

@implementation TriMetXML
+ (void)initialize {
    
}

+ (NSObject *)parseSyncObject {
    DoOnce(^{
      staticParseSyncObject = [[NSMutableData alloc] initWithLength:1];
    });

    return staticParseSyncObject;
}

+ (instancetype)xml {
    return [[[self class] alloc] init];
}

+ (instancetype _Nonnull)xmlWithOneTimeDelegate:
    (id<TriMetXMLDelegate> _Nonnull)delegate {
    TriMetXML *xml = [[[self class] alloc] init];
    xml.oneTimeDelegate = delegate;
    return xml;
}

+ (void)initCaches {
    DoOnce(^{
      stopNameCache = [StopNameCacheManager cache];

      // Old caches.
      [SharedFile removeFileWithName:@"queryCache.plist"];
      [SharedFile removeFileWithName:@"shortTermCache.plist"];
    });
}

+ (StopNameCacheManager *)getStopNameCacheManager {
    [TriMetXML initCaches];
    return stopNameCache;
}

+ (bool)deleteCacheFile {
    [TriMetXML initCaches];

    [SessionSingleton clearCache];
    [stopNameCache deleteCacheFile];

    return YES;
}

+ (NSUInteger)cacheSizeInBytes {
    [TriMetXML initCaches];

    NSUInteger httpCacheSize = [SessionSingleton cacheSizeInBytes];
    NSUInteger stopNameCacheSize = stopNameCache.sizeInBytes;

    DEBUG_LOG_long(httpCacheSize);
    DEBUG_LOG_long(stopNameCacheSize);

    return httpCacheSize + stopNameCacheSize;
}

- (id)init {
    if (self = [super init]) {
#ifdef PDXBUS_WATCH
        self.giveUp = 30.0;
#endif
        self.queryTransformer = TriMetXML.globalQueryTransformer;
    }

    return self;
}


+ (XMLQueryTransformer) globalQueryTransformer {
    return globalQueryTransformer;
}

+ (void)setGlobalQueryTransformer:(XMLQueryTransformer) block {
    globalQueryTransformer = block;
}


#pragma mark Data checks

+ (BOOL)isDataSourceAvailable:(BOOL)forceCheck {
#ifndef PDXBUS_WATCH
    static BOOL checkNetwork = YES;
    static BOOL isDataSourceAvailable = NO;

    // if (checkNetwork || forceCheck) { // Since checking the reachability of a
    // host can be expensive, cache the result and perform the reachability
    // check once.
    if (forceCheck) {
        Boolean success;
        const char *host_name = "developer.trimet.org";

        SCNetworkReachabilityRef reachability =
            SCNetworkReachabilityCreateWithName(NULL, host_name);
        SCNetworkReachabilityFlags flags;
        success = SCNetworkReachabilityGetFlags(reachability, &flags);
        isDataSourceAvailable = success && (flags & kSCNetworkFlagsReachable) &&
                                !(flags & kSCNetworkFlagsConnectionRequired);
        CFRelease(reachability);
        checkNetwork = !isDataSourceAvailable;
        return isDataSourceAvailable;
    }

#endif
    return YES;
}

- (bool)gotData {
    return _hasData;
}

#pragma mark Item array

- (id)objectAtIndexedSubscript:(NSInteger)index {
    // Let an exception occur
    // if (self.items != nil)
    //{
    return self.items[index];
    //}
    // return nil;
}

- (void)addItem:(id)item {
    [self.items addObject:item];
}

- (NSUInteger)
    countByEnumeratingWithState:(NSFastEnumerationState *)state
                        objects:
                            (id __unsafe_unretained _Nullable[_Nonnull])buffer
                          count:(NSUInteger)len {
    return [self.items countByEnumeratingWithState:state
                                           objects:buffer
                                             count:len];
}

- (void)clearItems {
    self.items = nil;
}

- (void)initItems {
    self.items = [NSMutableArray array];
}

- (NSInteger)count {
    if (_items != nil) {
        return _items.count;
    }

    return 0;
}

#pragma mark Attribute Dictionary helpers

- (NSString *)displayTriMetDate:(TriMetTime)time {
    return [self displayDate:TriMetToNSDate(time)];
}

- (NSString *)displayDate:(NSDate *)queryTime {
    return
        [NSString stringWithFormat:
                      NSLocalizedString(@"Updated: %@", @"updated time"),
                      [NSDateFormatter
                          localizedStringFromDate:queryTime
                                        dateStyle:NSDateFormatterShortStyle
                                        timeStyle:NSDateFormatterMediumStyle]];
}

// 25 character TriMet app ID is stored at rest in an encoded way to make it
// hard to find These macros encode it in a static way using the compiler to
// encode it and a small amount of code to decode it.
#define ENC(A, B, J)                                                           \
    (char)(((A) ^ ((B))) | (0x##J << 4)) // EOR with previous digit and add some
                                         // junk fo the top digit
#define SEED 0xA
#define DE_ENC(E, B) (((E) & 0xF) ^ ((B)))
#define APP_ID_SIZE (25)

#define ENCODED_APPID(L01, L02, L03, L04, L05, L06, L07, L08, L09, L10, L11,   \
                      L12, L13, L14, L15, L16, L17, L18, L19, L20, L21, L22,   \
                      L23, L24, L25)                                           \
    {(ENC(0x##L01, SEED, 2)),    (ENC(0x##L02, 0x##L01, 4)),                   \
     (ENC(0x##L03, 0x##L02, 3)), (ENC(0x##L04, 0x##L03, F)),                   \
     (ENC(0x##L05, 0x##L04, 6)), (ENC(0x##L06, 0x##L05, A)),                   \
     (ENC(0x##L07, 0x##L06, 8)), (ENC(0x##L08, 0x##L07, 8)),                   \
     (ENC(0x##L09, 0x##L08, 8)), (ENC(0x##L10, 0x##L09, 5)),                   \
     (ENC(0x##L11, 0x##L10, A)), (ENC(0x##L12, 0x##L11, 3)),                   \
     (ENC(0x##L13, 0x##L12, 0)), (ENC(0x##L14, 0x##L13, 8)),                   \
     (ENC(0x##L15, 0x##L14, D)), (ENC(0x##L16, 0x##L15, 3)),                   \
     (ENC(0x##L17, 0x##L16, 1)), (ENC(0x##L18, 0x##L17, 3)),                   \
     (ENC(0x##L19, 0x##L18, 1)), (ENC(0x##L20, 0x##L19, 9)),                   \
     (ENC(0x##L21, 0x##L20, 8)), (ENC(0x##L22, 0x##L21, A)),                   \
     (ENC(0x##L23, 0x##L22, 2)), (ENC(0x##L24, 0x##L23, E)),                   \
     (ENC(0x##L25, 0x##L24, 0))}

+ (NSString *)appId {
    static NSMutableString *appId;

    DoOnce((^{
      appId = [NSMutableString string];
      static char raw[APP_ID_SIZE] = TRIMET_APP_ID;
      char *pRaw = raw;
      char previous = SEED;
      char current;

      for (int i = 0; i < APP_ID_SIZE; i++) {
          current = DE_ENC(*pRaw, previous);
          previous = current;
          [appId appendFormat:@"%c",
                              current > 9 ? current + 'A' - 10 : current + '0'];
          pRaw++;
      }
    }));

    return appId;
}

#pragma mark Parsing init

- (NSString *)fullAddressForQuery:(NSString *)query {
    NSString *str = nil;

    if ([query characterAtIndex:query.length - 1] == '&') {
        str = [NSString
            stringWithFormat:@"https://developer.trimet.org/ws/V1/%@&appID=%@",
                             query, [TriMetXML appId]];
    } else {
        str = [NSString
            stringWithFormat:@"https://developer.trimet.org/ws/V1/%@/appID/%@",
                             query, [TriMetXML appId]];
    }

    return str;
}

- (BOOL)startParsing:(NSString *)query {
    return [self startParsing:query cacheAction:TriMetXMLNoCaching];
}

- (void)makeServerRequest:(NSString *)str {
    self.cacheTime = [NSDate date];

    if (self.oneTimeDelegate) {
        [self.oneTimeDelegate triMetXML:self startedFetchingData:FALSE];
    }

    [self fetchDataByPolling:str
                 cachePolicy:NSURLRequestReloadIgnoringLocalCacheData];

    if (self.oneTimeDelegate) {
        [self.oneTimeDelegate triMetXML:self finishedFetchingData:FALSE];
    }
}

- (void)makeRouteCacheRequest:(NSString *)cacheKey {
    [self fetchDataByPolling:cacheKey
                 cachePolicy:NSURLRequestReturnCacheDataDontLoad];
    self.itemFromCache = YES;
    self.cacheTime = self.httpDate;
}

- (bool)makeShortTermCacheRequest:(NSString *)cacheKey {
    [self fetchDataByPolling:cacheKey
                 cachePolicy:NSURLRequestReturnCacheDataDontLoad];
    self.itemFromCache = YES;
    return self.rawData != nil;
}

- (bool)parseWithProgress {
    bool succeeded = NO;
    if (self.oneTimeDelegate) {
        [self.oneTimeDelegate triMetXML:self finishedFetchingData:TRUE];
    }

    succeeded = [self parseRawData];

    return succeeded;
}

- (BOOL)startParsing:(NSString *)query cacheAction:(CacheAction)cacheAction {
    @autoreleasepool {
        int tries = 2;
        BOOL succeeded = NO;
        self.itemFromCache = NO;

        _hasData = NO;
        self.currentCacheAction = cacheAction;
        [self clearItems];

        NSString *str = self.queryTransformer(self, query);
        NSString *cacheKey = str;

        [TriMetXML initCaches];

        DEBUG_LOG(@"%@ Query: %@\n", NSStringFromClass([self class]), str);

        if ((Settings.debugXML)) {
            self.fullQuery = str;
        }

        switch (cacheAction) {
        default:
        case TriMetXMLNoCaching:
        case TriMetXMLUseShortTermCache:
            break;
        case TriMetXMLCheckRouteCache:
            tries = 0;
            // pass through

        case TrIMetXMLRouteCacheReadOrFetch:
            [self makeRouteCacheRequest:cacheKey];

            if (self.rawData != nil) {
                succeeded = [self parseWithProgress];
            }
            break;
        case TriMetXMLForceFetchAndUpdateRouteCache:
            break;
        }

        while (!_hasData && tries > 0 &&
               ![NSThread currentThread].isCancelled) {
            if ([TriMetXML isDataSourceAvailable:NO] == YES &&
                ![NSThread currentThread].isCancelled) {
                self.rawData = nil;

                [self makeServerRequest:str];

                if (self.rawData != nil) {
                    succeeded = [self parseWithProgress];
                }
            }

            tries--;
        }

        if (!_hasData && cacheAction == TriMetXMLUseShortTermCache) {
            if ([self makeShortTermCacheRequest:cacheKey]) {
                succeeded = [self parseWithProgress];
            }
        }

        if (!_hasData && ![NSThread currentThread].isCancelled) {
            self.htmlError = self.rawData;

#ifdef DEBUG

            if (self.htmlError != nil) {
                NSString *debug =
                    [[NSString alloc] initWithBytes:[self.htmlError bytes]
                                             length:[self.htmlError length]
                                           encoding:NSUTF8StringEncoding];
                DEBUG_PRINTF("HTML: %s\n",
                             [debug cStringUsingEncoding:NSUTF8StringEncoding]);
            }

#endif
        } else if (![NSThread currentThread].isCancelled &&
                   !self.itemFromCache) {
        }

        [self clearRawData];

        self.oneTimeDelegate = nil;

        return succeeded;
    }
}

- (bool)cacheSelectors {
#ifdef DEBUGLOGGING
    return DEBUG_ON_FOR_FILE;
#else
    return NO;
#endif
}

- (void)initSelectors {
    static SelImpClassCache allStartSelectors = nil;
    static SelImpClassCache allEndSelectors = nil;

    Class cls = self.class;

    DoOnce(^{
      allStartSelectors = [NSMapTable strongToStrongObjectsMapTable];
      allEndSelectors = [NSMapTable strongToStrongObjectsMapTable];
    });

    if (self.cacheSelectors) {
        self.startSels = [allStartSelectors cacheForClass:cls];
        self.endSels = [allEndSelectors cacheForClass:cls];
    } else {
        self.startSels = [NSMutableDictionary new];
        self.endSels = [NSMutableDictionary new];
    }
}

- (bool)parseRawData {
    XmlParseSync() {

        bool succeeded = NO;

        // Moved from synchronous to asyncronous calls
        // NSURL *URL = [NSURL URLWithString:str];
        // NSXMLParser *parser = [[NSXMLParser alloc]
        // initWithContentsOfURL:URL]; Set self as the delegate of the parser so
        // that it will receive the parser delegate methods callbacks.
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.rawData];

        parser.delegate = self;
        // Depending on the XML document you're parsing, you may want to enable
        // these features of NSXMLParser.
        [parser setShouldProcessNamespaces:NO];
        [parser setShouldReportNamespacePrefixes:NO];
        [parser setShouldResolveExternalEntities:NO];

        [self clearItems];

        [self initSelectors];

        [parser parse];

        NSError *parseError = parser.parserError;

        if (parseError && ![NSThread currentThread].isCancelled) {
            self.parseError = parseError;
        }

        LOG_PARSE_ERROR(parser.parserError);

        if (parseError == nil) {
            succeeded = YES;
        }

        DEBUG_XML(@"start element %@", self.startSels);
        DEBUG_XML(@"start element %@", self.endSels);
        return succeeded;
    }
}

- (void)clearRawData {
    if (!self.keepRawData && !Settings.debugXML) {
        self.rawData = nil;
    }
}

- (void)appendQueryAndData:(NSMutableData *)buffer {
    NSString *start = nil;

    if (self.fullQuery) {
        start = [NSString
            stringWithFormat:@"<query url=\"%@\">",
                             [TriMetXML insertXMLcodes:self.fullQuery]];
    } else {
        start = [NSString stringWithFormat:@"<query>"];
    }

    [buffer appendData:[start dataUsingEncoding:NSUTF8StringEncoding]];

    if (self.rawData) {
        [buffer appendData:self.rawData];
    }

    [buffer appendData:[@"</query>" dataUsingEncoding:NSUTF8StringEncoding]];
}

#pragma mark Parser callbacks

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if ([NSThread currentThread].isCancelled) {
        [parser abortParsing];
    }
    @autoreleasepool {
        if (self.contentOfCurrentProperty) {
            // If the current element is one whose content we care about, append
            // 'string' to the property that holds the content of the current
            // element.
            [self.contentOfCurrentProperty appendString:string];
        }
    }
}

#pragma mark Replace HTML sequences

static NSDictionary *replacements = nil;

+ (void)makeReplacements {
    DoOnce((^{
      replacements = @{
          @"<" : @"&lt;",
          @">" : @"&gt;",
          @"\"" : @"&quot;",
          @"'" : @"&apos;",
          @" " : @"&nbsp;"
      };
    }));
}

+ (NSString *)insertXMLcodes:(NSString *)string {
    [TriMetXML makeReplacements];

    NSMutableString *ms = [NSMutableString string];

    [ms appendString:string];

    // Ampersand must be done first as it could change the others
    [ms replaceOccurrencesOfString:@"&"
                        withString:@"&amp;"
                           options:NSLiteralSearch
                             range:NSMakeRange(0, ms.length)];

    [replacements enumerateKeysAndObjectsUsingBlock:^void(
                      NSString *dictionaryKey, NSString *val, BOOL *stop) {
      [ms replaceOccurrencesOfString:dictionaryKey
                          withString:val
                             options:NSLiteralSearch
                               range:NSMakeRange(0, ms.length)];
    }];

    return ms;
}

+ (NSString *)replaceXMLcodes:(NSString *)string {
    [TriMetXML makeReplacements];

    NSMutableString *ms = [NSMutableString string];

    [ms appendString:string];

    [replacements enumerateKeysAndObjectsUsingBlock:^void(
                      NSString *dictionaryKey, NSString *val, BOOL *stop) {
      [ms replaceOccurrencesOfString:val
                          withString:dictionaryKey
                             options:NSLiteralSearch
                               range:NSMakeRange(0, ms.length)];
    }];

    // Ampersand is not in the list as it can cause recursion if it is not done
    // first
    [ms replaceOccurrencesOfString:@"&amp;"
                        withString:@"&"
                           options:NSLiteralSearch
                             range:NSMakeRange(0, ms.length)];

    return ms;
}

// Profiling shows that using the cache here is twice as fast, but still the
// time is very small.

- (void)parser:(NSXMLParser *)parser
    didStartElement:(NSString *)elementName
       namespaceURI:(NSString *)namespaceURI
      qualifiedName:(NSString *)qName
         attributes:(NSDictionary *)attributeDict {
    if ([NSThread currentThread].isCancelled) {
        [parser abortParsing];
        return;
    }

    @autoreleasepool {
        if (qName) {
            elementName = qName;
        }

        if (DEBUG_ON_FOR_FILE) {
            DEBUG_XML(@" %@", elementName);

            NSEnumerator *i = attributeDict.keyEnumerator;
            NSString *key = nil;

            while ((key = i.nextObject)) {
                DEBUG_XML(@"  %@ = %@\n", key, attributeDict[key]);
            }
        }

        SelImpPair elSelImp =
            [self.startSels selImpForElement:elementName
                                     selName:XML_START_SELECTOR_NAME
                                         obj:self
                                       debug:XML_START_DEBUG];

        if (elSelImp.imp != nil) {
            XML_START_ELEMENT_IMP startElementFunc = (void *)elSelImp.imp;
            startElementFunc(self, elSelImp.sel, attributeDict);
        }
    }
}

- (void)parser:(NSXMLParser *)parser
    didEndElement:(NSString *)elementName
     namespaceURI:(NSString *)namespaceURI
    qualifiedName:(NSString *)qName {
    if ([NSThread currentThread].isCancelled) {
        [parser abortParsing];
        return;
    }

    @autoreleasepool {
        if (qName) {
            elementName = qName;
        }

        if (DEBUG_ON_FOR_FILE && self.contentOfCurrentProperty != nil) {
            DEBUG_XML(@"  content: %@\n", self.contentOfCurrentProperty);
        }

        SelImpPair elSelImp =
            [self.endSels selImpForElement:elementName
                                   selName:XML_END_SELECTOR_NAME
                                       obj:self
                                     debug:XML_END_DEBUG];

        if (elSelImp.imp != nil) {
            XML_END_ELEMENT_IMP endElementFunc = (void *)elSelImp.imp;
            endElementFunc(self, elSelImp.sel);
        }
    }
}

- (void)incrementalBytes:(long long)incremental {
    if (self.oneTimeDelegate) {
        [self.oneTimeDelegate triMetXML:self incrementalBytes:incremental];
    }
}

- (NSTimeInterval)secondsUntilEndOfServiceSunday:(NSDate *)date {

    NSCalendar *cal = [NSCalendar currentCalendar];
    int units = NSCalendarUnitWeekOfYear | NSCalendarUnitYearForWeekOfYear |
                NSCalendarUnitWeekday | NSCalendarUnitHour |
                NSCalendarUnitMinute | NSCalendarUnitSecond;

    NSDateComponents *nowDateComponents = [cal components:units fromDate:date];

    DEBUG_LOG_long(nowDateComponents.yearForWeekOfYear);
    DEBUG_LOG_long(nowDateComponents.weekOfYear);
    nowDateComponents.weekOfYear++;

    nowDateComponents.weekday = 1;
    nowDateComponents.hour = 3;
    nowDateComponents.minute = 30;
    nowDateComponents.second = 0;

    NSDate *sunday = [cal dateFromComponents:nowDateComponents];

    DEBUG_LOG_NSDate(sunday);
    DEBUG_LOG_double([sunday timeIntervalSinceDate:date]);

    return [sunday timeIntervalSinceDate:date];
}

- (void)URLSession:(NSURLSession *)session
             dataTask:(NSURLSessionDataTask *)dataTask
    willCacheResponse:(NSCachedURLResponse *)proposedResponse
    completionHandler:(void (^)(NSCachedURLResponse *_Nullable cachedResponse))
                          completionHandler {
    if ([proposedResponse.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse =
            (NSHTTPURLResponse *)proposedResponse.response;
        self.httpDate = httpResponse.headerDate;

        switch (self.currentCacheAction) {
        case TriMetXMLCheckRouteCache:
        case TriMetXMLForceFetchAndUpdateRouteCache:
        case TrIMetXMLRouteCacheReadOrFetch:
            if (httpResponse.hasMaxAge) {
                completionHandler(proposedResponse);
            } else {
                completionHandler([SessionSingleton
                                  response:proposedResponse
                    withExpirationDuration:
                        [self secondsUntilEndOfServiceSunday:self.httpDate]]);
            }
            break;
        case TriMetXMLNoCaching:
            completionHandler(nil);
            break;
        case TriMetXMLUseShortTermCache:
            completionHandler([SessionSingleton response:proposedResponse
                                  withExpirationDuration:15 * 60]);
            break;
        default:
            completionHandler(proposedResponse);
            break;
        }

    } else {
        self.httpDate = nil;
        completionHandler(nil);
    }
}

@end
