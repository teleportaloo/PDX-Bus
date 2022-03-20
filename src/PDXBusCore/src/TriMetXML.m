
//
//  TriMetXML.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogXML

#ifndef DEBUGLOGGING
#pragma clang diagnostic ignored "-Wunreachable-code"
#endif

#import "TriMetXML.h"
#import "TriMetTypes.h"
#ifndef PDXBUS_WATCH
#import <SystemConfiguration/SystemConfiguration.h>
#endif
#import "DebugLogging.h"
#import "QueryCacheManager.h"
#import "Settings.h"
#import "StopNameCacheManager.h"
#import "TriMetAppId.h"
#import "TriMetXMLSelectors.h"
#import <objc/runtime.h>
#import "SessionSingleton.h"
#import "NSHTTPURLResponse+Headers.h"

#define kShortTermCacheAge (20 * 60)  // 15 mins

#ifdef DEBUGLOGGING
#define DEBUG_XML(s, ...) if (DEBUG_ON_FOR_FILE) { NSLog(@"XML: %@ %@", NSStringFromClass([self class]), [NSString stringWithFormat:(s), ## __VA_ARGS__]); }
#else
#define DEBUG_XML(s, ...)
#endif

@interface TriMetXML<ItemType>() {
    
}

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSValue *> *_Nullable startSels;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSValue *> *_Nullable endSels;
@property (nonatomic) CacheAction currentCacheAction;

@end


#pragma mark Cache

static StopNameCacheManager *stopNameCache = nil;
static NSMutableData *staticParseSyncObject = nil;

@implementation TriMetXML

+ (NSObject *)parseSyncObject
{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        staticParseSyncObject = [[NSMutableData alloc] initWithLength:1];
    });
    
    return staticParseSyncObject;
}


+ (instancetype)xml {
    return [[[self class] alloc] init];
}

+ (instancetype _Nonnull)xmlWithOneTimeDelegate:(id<TriMetXMLDelegate> _Nonnull)delegate
{
    TriMetXML *xml = [[[self class] alloc] init];
    xml.oneTimeDelegate = delegate;
    return xml;
}

+ (void)initCaches {
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        stopNameCache = [StopNameCacheManager cache];
        
        // Old caches.
        [SharedFile removeFileWithName: @"queryCache.plist"];
        [SharedFile removeFileWithName: @"shortTermCache.plist"];
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
    
    DEBUG_LOGL(httpCacheSize);
    DEBUG_LOGL(stopNameCacheSize);

    return httpCacheSize + stopNameCacheSize;
 }

#ifdef PDXBUS_WATCH
- (id)init {
    if (self = [super init]) {
        self.giveUp = 30.0;
        [self setTestData];
        
        self.queryBlock = ^(TriMetXML *xml, NSString *query) {
            return [xml fullAddressForQuery:query];
        };
    }
    
    return self;
}

#else

- (id)init {
    if (self = [super init]) {
        [self setTestData];
        
        self.queryBlock = ^(TriMetXML *xml, NSString *query) {
            return [xml fullAddressForQuery:query];
        };
    }
    
    return self;
}

#endif

#if defined XML_TEST_DATA

static NSMutableDictionary<NSString *, NSNumber *> *testDataIndex = nil;

- (void)setTestData {
    NSString *name = NSStringFromClass([self class]);
    static NSDictionary *testData = nil;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSDictionary *allTestData = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"TestData" ofType:@"plist"]];
        testData = allTestData[@XML_TEST_DATA];
        testDataIndex = [NSMutableDictionary dictionary];
    });
    self.testURLs = testData[name];
    
    if (testDataIndex[name] == nil) {
        testDataIndex[name] = @(0);
    }
    
    DEBUG_LOGS(name);
    DEBUG_LOGO(self.testURLs);
}

- (NSString *)nextTestUrl:(NSString *)str {
    if (self.testURLs != nil) {
        NSString *name = NSStringFromClass([self class]);
        NSNumber *next = testDataIndex[name];
        
        if (next.intValue < self.testURLs.count) {
            str = self.testURLs[next.intValue];
        }
        
        next = @((next.intValue + 1) % self.testURLs.count);
        testDataIndex[name] = next;
        DEBUG_LOGS(str);
    }
    
    return str;
}

#else // if defined XML_TEST_DATA
- (void)setTestData {
}

- (NSString *)nextTestUrl:(NSString *)str {
    return str;
}

#endif // if defined XML_TEST_DATA


#pragma mark Data checks

+ (BOOL)isDataSourceAvailable:(BOOL)forceCheck {
#ifndef PDXBUS_WATCH
    static BOOL checkNetwork = YES;
    static BOOL isDataSourceAvailable = NO;
    
    // if (checkNetwork || forceCheck) { // Since checking the reachability of a host can be expensive, cache the result and perform the reachability check once.
    if (forceCheck) {
        Boolean success;
        const char *host_name = "developer.trimet.org";
        
        SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, host_name);
        SCNetworkReachabilityFlags flags;
        success = SCNetworkReachabilityGetFlags(reachability, &flags);
        isDataSourceAvailable = success && (flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired);
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

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer count:(NSUInteger)len {
    return [self.items countByEnumeratingWithState:state objects:buffer count:len];
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
    return [NSString stringWithFormat:NSLocalizedString(@"Updated: %@", @"updated time"),
            [NSDateFormatter localizedStringFromDate:queryTime dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle]];
}

// 25 character TriMet app ID is stored at rest in an encoded way to make it hard to find
// These macros encode it in a static way using the compiler to encode it and a small
// amount of code to decode it.
#define ENC(A, B, J) (char)(((A) ^ ((B))) | (0x ## J << 4)) // EOR with previous digit and add some junk fo the top digit
#define SEED         0xA
#define DE_ENC(E, B) (((E) & 0xF) ^ ((B)))
#define APP_ID_SIZE  (25)

#define ENCODED_APPID(L01, L02, L03, L04, L05, L06, L07, L08, L09, L10, L11, L12, L13, L14, L15, L16, L17, L18, L19, L20, L21, L22, L23, L24, L25) \
{  (ENC(0x ## L01, SEED, 2)),      (ENC(0x ## L02, 0x ## L01, 4)), (ENC(0x ## L03, 0x ## L02, 3)), (ENC(0x ## L04, 0x ## L03, F)), (ENC(0x ## L05, 0x ## L04, 6)),  \
(ENC(0x ## L06, 0x ## L05, A)), (ENC(0x ## L07, 0x ## L06, 8)), (ENC(0x ## L08, 0x ## L07, 8)), (ENC(0x ## L09, 0x ## L08, 8)), (ENC(0x ## L10, 0x ## L09, 5)),  \
(ENC(0x ## L11, 0x ## L10, A)), (ENC(0x ## L12, 0x ## L11, 3)), (ENC(0x ## L13, 0x ## L12, 0)), (ENC(0x ## L14, 0x ## L13, 8)), (ENC(0x ## L15, 0x ## L14, D)),  \
(ENC(0x ## L16, 0x ## L15, 3)), (ENC(0x ## L17, 0x ## L16, 1)), (ENC(0x ## L18, 0x ## L17, 3)), (ENC(0x ## L19, 0x ## L18, 1)), (ENC(0x ## L20, 0x ## L19, 9)),  \
(ENC(0x ## L21, 0x ## L20, 8)), (ENC(0x ## L22, 0x ## L21, A)), (ENC(0x ## L23, 0x ## L22, 2)), (ENC(0x ## L24, 0x ## L23, E)), (ENC(0x ## L25, 0x ## L24, 0)) }

+ (NSString *)appId {
    static NSMutableString *appId;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        appId = [NSMutableString string];
        static char raw[APP_ID_SIZE] = TRIMET_APP_ID;
        char *pRaw = raw;
        char previous = SEED;
        char current;
        
        for (int i = 0; i < APP_ID_SIZE; i++) {
            current = DE_ENC(*pRaw, previous);
            previous = current;
            [appId appendFormat:@"%c", current > 9 ? current + 'A' - 10 : current + '0'];
            pRaw++;
        }
    });
    
    return appId;
}

#pragma mark Parsing init

- (NSString *)fullAddressForQuery:(NSString *)query {
    NSString *str = nil;
    
    if ([query characterAtIndex:query.length - 1] == '&') {
        str = [NSString stringWithFormat:@"https://developer.trimet.org/ws/V1/%@&appID=%@",
               query, [TriMetXML appId]];
    } else {
        str = [NSString stringWithFormat:@"https://developer.trimet.org/ws/V1/%@/appID/%@",
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
    
#if defined XML_TEST_DATA
    str = [self nextTestUrl:str];
#endif
    [self fetchDataByPolling:str cachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    
    if (self.oneTimeDelegate) {
        [self.oneTimeDelegate triMetXML:self finishedFetchingData:FALSE];
    }
}

- (void)makeRouteCacheRequest:(NSString *)cacheKey {
    [self fetchDataByPolling:cacheKey cachePolicy:NSURLRequestReturnCacheDataDontLoad];
    self.itemFromCache = YES;
    self.cacheTime = self.httpDate;
}

- (bool)makeShortTermCacheRequest:(NSString *)cacheKey  {
    [self fetchDataByPolling:cacheKey cachePolicy:NSURLRequestReturnCacheDataDontLoad];
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
        
        NSString *str = self.queryBlock(self, query);
        NSString *cacheKey = str;
        
        [TriMetXML initCaches];
        
        DEBUG_LOG(@"%@ Query: %@\n", NSStringFromClass([self class]), str);
        
        if ((Settings.debugXML)) {
            self.fullQuery = str;
        }
        
        switch (cacheAction)
        {
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
        
        while (!_hasData && tries > 0 && ![NSThread currentThread].isCancelled) {
            if ([TriMetXML isDataSourceAvailable:NO] == YES && ![NSThread currentThread].isCancelled) {
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
                NSString *debug = [[NSString alloc] initWithBytes:[self.htmlError bytes] length:[self.htmlError length] encoding:NSUTF8StringEncoding];
                DEBUG_PRINTF("HTML: %s\n", [debug cStringUsingEncoding:NSUTF8StringEncoding]);
            }
            
#endif
        } else if (![NSThread currentThread].isCancelled && !self.itemFromCache) {
            
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
    static NSMutableDictionary *allStartSelectors = nil;
    static NSMutableDictionary *allEndSelectors = nil;
    
    NSString *name = NSStringFromClass([self class]);
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        allStartSelectors = [NSMutableDictionary dictionary];
        allEndSelectors = [NSMutableDictionary dictionary];
    });
    
    if (self.cacheSelectors) {
        self.startSels = allStartSelectors[name];
        
        if (self.startSels == nil) {
            self.startSels = [NSMutableDictionary dictionary];
            allStartSelectors[name] = self.startSels;
        }
        
        self.endSels = allEndSelectors[name];
        
        if (self.endSels == nil) {
            self.endSels = [NSMutableDictionary dictionary];
            allEndSelectors[name] = self.endSels;
        }
    } else {
        self.startSels = [NSMutableDictionary dictionary];
        self.endSels = [NSMutableDictionary dictionary];
    }
}

- (bool)parseRawData {
    XmlParseSync() {
        
        bool succeeded = NO;
        
        // Moved from synchronous to asyncronous calls
        // NSURL *URL = [NSURL URLWithString:str];
        // NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:URL];
        // Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.rawData];
        
        parser.delegate = self;
        // Depending on the XML document you're parsing, you may want to enable these features of NSXMLParser.
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
        
        
        if (DEBUG_ON_FOR_FILE)
        {
            [self.startSels enumerateKeysAndObjectsUsingBlock: ^void (NSString *element, NSValue *sel, BOOL *stop)
             {
                DEBUG_XML(@"start element %@ %p", element, sel.pointerValue);
            }];
            
            [self.endSels enumerateKeysAndObjectsUsingBlock: ^void (NSString *element, NSValue *sel, BOOL *stop)
             {
                DEBUG_XML(@"end element %@ %p", element, sel.pointerValue);
            }];
        }
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
        start = [NSString stringWithFormat:@"<query url=\"%@\">", [TriMetXML insertXMLcodes:self.fullQuery] ];
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
    
    if (self.contentOfCurrentProperty) {
        // If the current element is one whose content we care about, append 'string'
        // to the property that holds the content of the current element.
        [self.contentOfCurrentProperty appendString:string];
    }
}

#pragma mark Replace HTML sequences

static NSDictionary *replacements = nil;

+ (void)makeReplacements {
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        replacements = @{ @"<": @"&lt;",
                          @">": @"&gt;",
                          @"\"": @"&quot;",
                          @"'": @"&apos;",
                          @" ": @"&nbsp;" };
    });
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
    
    [replacements enumerateKeysAndObjectsUsingBlock: ^void (NSString *dictionaryKey, NSString *val, BOOL *stop)
     {
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
    
    [replacements enumerateKeysAndObjectsUsingBlock: ^void (NSString *dictionaryKey, NSString *val, BOOL *stop)
     {
        [ms replaceOccurrencesOfString:val
                            withString:dictionaryKey
                               options:NSLiteralSearch
                                 range:NSMakeRange(0, ms.length)];
    }];
    
    // Ampersand is not in the list as it can cause recursion if it is not done first
    [ms replaceOccurrencesOfString:@"&amp;"
                        withString:@"&"
                           options:NSLiteralSearch
                             range:NSMakeRange(0, ms.length)];
    
    return ms;
}

// Profiling shows that using the cache here is twice as fast, but still the time is very small.

- (SEL)selectorForElement:(NSString *)elementName format:(NSString *)format cache:(NSMutableDictionary<NSString *, NSValue *> *)cache debug:(NSString *)debug {
    // PROFILING_ENTER_FUNCTION;
    NSValue *selValue = [cache objectForKey:elementName];
    SEL elementSelector = nil;
    
    if (selValue == nil) {
        NSString *selName = [NSString stringWithFormat:format, elementName];
        elementSelector = NSSelectorFromString(selName);
        
        if (![self respondsToSelector:elementSelector]) {
            elementSelector = nil;
            if (DEBUG_ON_FOR_FILE) {
                DEBUG_XML(@"%@ <- not %@\n", debug, elementName);
            }
        } else if (DEBUG_ON_FOR_FILE) {
            DEBUG_XML(@"%@ <-     %@\n", debug, elementName);
        }
        [cache setObject:[NSValue valueWithPointer:elementSelector] forKey:elementName];
    } else if (selValue.pointerValue != nil) {
        elementSelector = selValue.pointerValue;
        
        if (DEBUG_ON_FOR_FILE) {
            DEBUG_XML(@"%@ ->    %@\n", debug, elementName);
        }
    } else if (DEBUG_ON_FOR_FILE) {
        DEBUG_XML(@"%@ -> not %@\n", debug, elementName);
    }
    
    
    // PROFILING_EXIT_FUNCTION;
    return elementSelector;
}

- (void) parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
   namespaceURI:(NSString *)namespaceURI
  qualifiedName:(NSString *)qName
     attributes:(NSDictionary *)attributeDict {
    if ([NSThread currentThread].isCancelled) {
        [parser abortParsing];
        return;
    }
    
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
    
    SEL elementSelector = [self selectorForElement:elementName format:XML_START_SELECTOR cache:self.startSels debug:@"start"];
    
    if (elementSelector != nil) {
#ifdef XML_SHORT_SELECTORS
        void (*processStartElement)(id, SEL, NSDictionary *) = (void *)[self methodForSelector:elementSelector];
        processStartElement(self, elementSelector, attributeDict);
#else
        void (*processStartElement)(id, SEL, NSXMLParser *, NSString *, NSString *, NSString *, NSDictionary *) = (void *)[self methodForSelector:elementSelector];
        processStartElement(self, elementSelector, parser, elementName, namespaceURI, qName, attributeDict);
#endif
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([NSThread currentThread].isCancelled) {
        [parser abortParsing];
        return;
    }
    
    if (qName) {
        elementName = qName;
    }
    
    if (DEBUG_ON_FOR_FILE && self.contentOfCurrentProperty != nil) {
        DEBUG_LOG_RAW(@"  Content: %@\n", self.contentOfCurrentProperty);
    }
    
    SEL elementSelector = [self selectorForElement:elementName format:XML_END_SELECTOR cache:self.endSels debug:@"end  "];
    
    if (elementSelector != nil) {
#ifdef XML_SHORT_SELECTORS
        void (*processEndElement)(id, SEL) = (void *)[self methodForSelector:elementSelector];
        processEndElement(self, elementSelector);
#else
        void (*processEndElement)(id, SEL, NSXMLParser *, NSString *, NSString *, NSString *) = (void *)[self methodForSelector:elementSelector];
        processEndElement(self, elementSelector, parser, elementName, namespaceURI, qName);
#endif
    }
}

- (void)incrementalBytes:(long long)incremental {
    if (self.oneTimeDelegate) {
        [self.oneTimeDelegate triMetXML:self incrementalBytes:incremental];
    }
}

- (NSTimeInterval)secondsUntilEndOfServiceSunday:(NSDate *)date {
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    int units = NSCalendarUnitWeekOfYear  | NSCalendarUnitYearForWeekOfYear | NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    
    NSDateComponents *nowDateComponents = [cal components:units fromDate:date];

    DEBUG_LOGL(nowDateComponents.yearForWeekOfYear);
    DEBUG_LOGL(nowDateComponents.weekOfYear);
    nowDateComponents.weekOfYear++;
    
    nowDateComponents.weekday = 1;
    nowDateComponents.hour = 3;
    nowDateComponents.minute = 30;
    nowDateComponents.second = 0;
    
    NSDate *sunday = [cal dateFromComponents:nowDateComponents];
    
    DEBUG_LOGDATE(sunday);
    DEBUG_LOGF([sunday timeIntervalSinceDate:date]);
    
    return [sunday timeIntervalSinceDate:date];
}


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
                                  willCacheResponse:(NSCachedURLResponse *)proposedResponse
                                  completionHandler:(void (^)(NSCachedURLResponse * _Nullable cachedResponse))completionHandler {
    if ([proposedResponse.response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)proposedResponse.response;
        self.httpDate = httpResponse.headerDate;
    
        switch (self.currentCacheAction)
        {
            case TriMetXMLCheckRouteCache:
            case TriMetXMLForceFetchAndUpdateRouteCache:
            case TrIMetXMLRouteCacheReadOrFetch:
                if (httpResponse.hasMaxAge) {
                    completionHandler(proposedResponse);
                } else {
                    completionHandler([SessionSingleton response:proposedResponse withExpirationDuration:[self secondsUntilEndOfServiceSunday:self.httpDate]]);
                }
                break;
            case TriMetXMLNoCaching:
                completionHandler(nil);
                break;
            case TriMetXMLUseShortTermCache:
                completionHandler([SessionSingleton response:proposedResponse withExpirationDuration:15 * 60]);
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
