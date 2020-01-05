
//
//  TriMetXML.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetXML.h"
#import "TriMetTypes.h"
#ifndef PDXBUS_WATCH
#import <SystemConfiguration/SystemConfiguration.h>
#endif
#include "DebugLogging.h"
#include "QueryCacheManager.h"
#include "UserPrefs.h"
#include "StopNameCacheManager.h"
#include "TriMetAppId.h"

#define kShortTermCacheAge  (20 * 60) // 15 mins


@implementation NSDictionary (TriMetCaseInsensitive)

- (id)objectForCaseInsensitiveKey:(NSString *)key
{
    // Most cases will be a match and this is a hash based search so very
    // fast, so only do the simplistic case insensitive search if we didn't
    // find it.
    
    __block NSObject *result = self[key];
    
    if (result == nil)
    {        
        [self enumerateKeysAndObjectsUsingBlock: ^void (NSString* dictionaryKey, NSString* val, BOOL *stop)
         {
             if( [key caseInsensitiveCompare:dictionaryKey]==NSOrderedSame)
             {
                 *stop= YES;
                 result = val;
             }
         }];
    }
    
    return result;
}

- (NSString *)nullOrSafeValueForKey:(NSString *)key
{
    NSString *val = [self objectForCaseInsensitiveKey:key];
    
    if (val == nil || ![val isKindOfClass:[NSString class]])
    {
        val = nil;
    }
    
    if (val.length == 0)
    {
        return nil;
    }
    
    return val;
}


- (NSNumber *)nullOrSafeNumForKey:(NSString *)key
{
    NSString *val = [self objectForCaseInsensitiveKey:key];
    
    if (val == nil || ![val isKindOfClass:[NSString class]])
    {
        val = nil;
    }
    
    return @(val.integerValue);
}

- (NSInteger)zeroOrSafeIntForKey:(NSString *)key
{
    NSString *val = [self objectForCaseInsensitiveKey:key];
    
    if (val == nil || ![val isKindOfClass:[NSString class]])
    {
        return 0;
    }
    
    return [val integerValue];
}


- (NSString *)safeValueForKey:(NSString *)key
{
    NSString *val = [self objectForCaseInsensitiveKey:key];
    
    if (val == nil || ![val isKindOfClass:[NSString class]])
    {
        val = @"?";
    }
    
    return val;
}

- (TriMetTime)getTimeForKey:(NSString *)key
{
    NSString * val = [self safeValueForKey:key];
    return (TriMetTime)val.longLongValue;
}

- (NSDate *)getDateForKey:(NSString *)key
{
    NSString * val = [self objectForCaseInsensitiveKey:key];
    
    if (val == nil || val.length == 0 || val.integerValue ==0)
    {
        return nil;
    }
    
    return TriMetToNSDate((TriMetTime)val.longLongValue);
}

- (NSInteger)getNSIntegerForKey:(NSString *)key
{
    NSString * val = [self safeValueForKey:key];
    return val.integerValue;
}

- (TriMetDistance)getDistanceForKey:(NSString *)key
{
    NSString * val = [self safeValueForKey:key];
    return val.longLongValue;
}

- (double)getDoubleForKey:(NSString *)key
{
    NSString * val = [self safeValueForKey:key];
    return val.doubleValue;
}

- (bool)getBoolForKey:(NSString *)key
{
    NSString * val = [self safeValueForKey:key];
    return ([val compare:@"true" options:NSCaseInsensitiveSearch]==NSOrderedSame);
}

@end

@implementation TriMetXML

#pragma mark Cache

static QueryCacheManager *routeCache = nil;
static QueryCacheManager *shortTermCache = nil;
static StopNameCacheManager *stopNameCache = nil;


+ (instancetype)xml
{
    return [[[self class] alloc] init];
}

+ (void)initCaches
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        routeCache = [QueryCacheManager cacheWithFileName:@"queryCache.plist"];
        routeCache.maxSize = 25;
        
        shortTermCache = [QueryCacheManager cacheWithFileName:@"shortTermCache.plist"];
        shortTermCache.maxSize = [UserPrefs sharedInstance].maxRecentStops;
        
        stopNameCache = [StopNameCacheManager cache];
    
    });
}

+ (StopNameCacheManager *)getStopNameCacheManager
{
    [TriMetXML initCaches];
    return stopNameCache;
}

+ (bool)deleteCacheFile
{
    [TriMetXML initCaches];
    
    [routeCache deleteCacheFile];
    [shortTermCache deleteCacheFile];
    [stopNameCache deleteCacheFile];
    
    return YES;
}



#ifdef PDXBUS_WATCH
- (id)init
{
    if (self = [super init])
    {
        self.giveUp = 30.0;
        [self setTestData];
    }
    
    return self;
}
#else

- (id)init
{
    if (self = [super init])
    {
        [self setTestData];
    }
    
    return self;
}

#endif

#if defined XML_TEST_DATA

static NSMutableDictionary<NSString*, NSNumber*> *testDataIndex = nil;

- (void)setTestData
{
    NSString *name = NSStringFromClass([self class]);
    static NSDictionary *testData = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *allTestData = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"TestData" ofType:@"plist"]];
        testData = allTestData[@XML_TEST_DATA];
        testDataIndex = [NSMutableDictionary dictionary];
    });
    self.testURLs = testData[name];
    
    if (testDataIndex[name]==nil)
    {
        testDataIndex[name] = @(0);
    }
    
    DEBUG_LOGS(name);
    DEBUG_LOGO(self.testURLs);
}

- (NSString *)nextTestUrl:(NSString *)str
{
    if (self.testURLs != nil)
    {
        NSString *name = NSStringFromClass([self class]);
        NSNumber *next = testDataIndex[name];
        if (next.intValue < self.testURLs.count)
        {
            str = self.testURLs[next.intValue];
        }
        next = @((next.intValue+1) % self.testURLs.count);
        testDataIndex[name] = next;
        DEBUG_LOGS(str);
    }
    
    return str;
}

#else
- (void)setTestData
{

}

- (NSString *)nextTestUrl:(NSString *)str
{
    return str;
}
#endif


#pragma mark Data checks

+ (BOOL)isDataSourceAvailable:(BOOL)forceCheck
{
#ifndef PDXBUS_WATCH
    static BOOL checkNetwork = YES;
    static BOOL isDataSourceAvailable = NO;
    

    // if (checkNetwork || forceCheck) { // Since checking the reachability of a host can be expensive, cache the result and perform the reachability check once.
    if (forceCheck)
    {
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

- (bool)gotData
{
    return _hasData;
}

#pragma mark Item array


- (id)objectAtIndexedSubscript:(NSInteger)index
{
    // Let an exception occur
    // if (self.items != nil)
    //{
        return self.items[index];
    //}
    // return nil;
}

- (void)addItem:(id)item
{
    [self.items addObject:item];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer count:(NSUInteger)len
{
    return [self.items countByEnumeratingWithState:state objects:buffer count:len];
}

- (void)clearItems
{
    self.items = nil;
}

- (void)initItems
{
    self.items = [NSMutableArray array];
}


- (NSInteger)count
{
    if (_items !=nil)
    {
        return _items.count;
    }
    return 0;
}

#pragma mark Attribute Dictionary helpers

- (NSString *)displayTriMetDate:(TriMetTime)time
{
    return [self displayDate:TriMetToNSDate(time)];
}

- (NSString *)displayDate:(NSDate *)queryTime
{
    return [NSString stringWithFormat:NSLocalizedString(@"Updated: %@", @"updated time"),
            [NSDateFormatter localizedStringFromDate:queryTime dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterMediumStyle]];
}

// 25 character TriMet app ID is stored at rest in an encoded way to make it hard to find
// These macros encode it in a static way using the compiler to encode it and a small
// amount of code to decode it.
#define ENC(A,B,J)      (((A)^((B))) | (0x##J << 4))  // EOR with previous digit and add some junk fo the top digit
#define SEED            0xA
#define DE_ENC(E,B)     (((E) & 0xF)^((B)))
#define APP_ID_SIZE     (25)

#define ENCODED_APPID(L01,L02,L03,L04,L05,L06,L07,L08,L09,L10,L11,L12,L13,L14,L15,L16,L17,L18,L19,L20,L21,L22,L23,L24,L25) \
             {  (ENC(0x##L01,SEED   ,2)),(ENC(0x##L02,0x##L01,4)),(ENC(0x##L03,0x##L02,3)),(ENC(0x##L04,0x##L03,F)),(ENC(0x##L05,0x##L04,6)),  \
                (ENC(0x##L06,0x##L05,A)),(ENC(0x##L07,0x##L06,8)),(ENC(0x##L08,0x##L07,8)),(ENC(0x##L09,0x##L08,8)),(ENC(0x##L10,0x##L09,5)),  \
                (ENC(0x##L11,0x##L10,A)),(ENC(0x##L12,0x##L11,3)),(ENC(0x##L13,0x##L12,0)),(ENC(0x##L14,0x##L13,8)),(ENC(0x##L15,0x##L14,D)),  \
                (ENC(0x##L16,0x##L15,3)),(ENC(0x##L17,0x##L16,1)),(ENC(0x##L18,0x##L17,3)),(ENC(0x##L19,0x##L18,1)),(ENC(0x##L20,0x##L19,9)),  \
                (ENC(0x##L21,0x##L20,8)),(ENC(0x##L22,0x##L21,A)),(ENC(0x##L23,0x##L22,2)),(ENC(0x##L24,0x##L23,E)),(ENC(0x##L25,0x##L24,0)) }

+ (NSString*)appId
{
    static NSMutableString *appId;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        appId = [NSMutableString string];
        static char raw[APP_ID_SIZE] = TRIMET_APP_ID;
        char p = SEED;
        char c;
        char *r = raw;
        for(int i=0; i<APP_ID_SIZE; i++)
        {
            c= DE_ENC(*r,p);
            p = c;
            [appId appendFormat:@"%c", c > 9 ? c+'A'-10 : c+'0'];
            r++;
        }
    });
    
    return appId;
}


#pragma mark Parsing init

- (NSString*)fullAddressForQuery:(NSString *)query
{
    NSString *str = nil;
    
    if ([query characterAtIndex:query.length-1] == '&')
    {
        str = [NSString stringWithFormat:@"https://developer.trimet.org/ws/V1/%@&appID=%@",
               query, [TriMetXML appId]];
    }
    else
    {
        str = [NSString stringWithFormat:@"https://developer.trimet.org/ws/V1/%@/appID/%@",
               query, [TriMetXML appId]];
    }
    
    return str;
    
}

- (BOOL)startParsing:(NSString *)query
{
    return [self startParsing:query cacheAction:TriMetXMLNoCaching];
}

- (BOOL)startParsing:(NSString *)query cacheAction:(CacheAction)cacheAction
{
    @autoreleasepool {
        NSError *parseError = nil;
        int tries = 2;
        BOOL succeeded = NO;
        self.itemFromCache = NO;
        
        _hasData = NO;
        [self clearItems];
        
        NSString *str = [self fullAddressForQuery:query];
        NSString *cacheKey = [QueryCacheManager getCacheKey:str];
        
        [TriMetXML initCaches];
        
        DEBUG_LOG(@"Query: %@\n", str);
        
        if (([UserPrefs sharedInstance].debugXML))
        {
            self.fullQuery = str;
        }
        
        if (cacheAction == TriMetXMLCheckCache)
        {
            tries = 1;
        }
        
        while(!_hasData && tries > 0 && ![NSThread currentThread].isCancelled)
        {
            if ([TriMetXML isDataSourceAvailable:NO] == YES && ![NSThread currentThread].isCancelled)
            {
                self.rawData = nil;
                if (cacheAction != TriMetXMLNoCaching && cacheAction != TriMetXMLUseShortTermCache)
                {
                    routeCache.ageOutDays = cacheAction == TriMetXMLForceFetchAndUpdateCache ? kAlwaysAgeOut : [UserPrefs sharedInstance].routeCacheDays;
                    NSArray *cachedArray = [routeCache getCachedQuery:cacheKey];
                    
                    if (cachedArray)
                    {
                        self.rawData            = cachedArray[kCacheData];
                        self.itemFromCache      = YES;
                        self.cacheTime          = cachedArray[kCacheDateAndTime];
                    }
                    
                    if (self.rawData == nil && cacheAction!=TriMetXMLCheckCache)
                    {
                        self.cacheTime = [NSDate date];
                        if (self.oneTimeDelegate)
                        {
                            [self.oneTimeDelegate TriMetXML:self startedFetchingData:FALSE];
                        }
                        
#if defined XML_TEST_DATA
                        str = [self nextTestUrl:str];
#endif
                        [self fetchDataByPolling:str];
                        
                        if (self.oneTimeDelegate)
                        {
                            [self.oneTimeDelegate TriMetXML:self finishedFetchingData:FALSE];
                        }
                        
                    }
                    else
                    {
                        if (self.oneTimeDelegate)
                        {
                            [self.oneTimeDelegate TriMetXML:self finishedFetchingData:TRUE];
                        }
                    }
                    
                }
                else {
                    self.cacheTime = [NSDate date];
                    
                    if (self.oneTimeDelegate)
                    {
                        [self.oneTimeDelegate TriMetXML:self startedFetchingData:FALSE];
                    }
                    
#if defined XML_TEST_DATA
                    str = [self nextTestUrl:str];
#endif
                    [self fetchDataByPolling:str];
                    
                    if (self.oneTimeDelegate)
                    {
                        [self.oneTimeDelegate TriMetXML:self finishedFetchingData:FALSE];
                    }
                    
                }
                
                if (self.rawData !=nil)
                {
                    if (self.oneTimeDelegate)
                    {
                        [self.oneTimeDelegate TriMetXML:self startedParsingData:self.rawData.length fromCache:self.itemFromCache];
                    }
                    
                    succeeded = [self parseRawData:&parseError];
                    LOG_PARSE_ERROR(parseError);
                    
                    if (self.oneTimeDelegate)
                    {
                        [self.oneTimeDelegate TriMetXML:self finishedParsingData:self.rawData.length fromCache:self.itemFromCache];
                    }
                    
                }
            }
            tries --;
        }
        
        if (!_hasData && cacheAction == TriMetXMLUseShortTermCache)
        {
            NSArray *cachedArray = [shortTermCache getCachedQuery:cacheKey];
            
            if (cachedArray != nil)
            {
                NSDate *itemDate = cachedArray[kCacheDateAndTime];
                
                NSTimeInterval cacheAge = itemDate.timeIntervalSinceNow;
                
                if ((-cacheAge) < kShortTermCacheAge)
                {
                    self.rawData    = cachedArray[kCacheData];
                    self.itemFromCache    = YES;
                    self.cacheTime    = itemDate;
                    parseError      = nil;
                    succeeded       = [self parseRawData:&parseError];
                    LOG_PARSE_ERROR(parseError);
                }
                else
                {
                    [shortTermCache removeFromCache:cacheKey];
                }
            }
        }
        
        if (!_hasData && ![NSThread currentThread].isCancelled)
        {
            self.htmlError = self.rawData;
            
#ifdef DEBUG 
            if (self.htmlError !=nil)
            {
                NSString *debug = [[NSString alloc] initWithBytes:[self.htmlError bytes] length:[self.htmlError length] encoding:NSUTF8StringEncoding];
                DEBUG_PRINTF("HTML: %s\n", [debug cStringUsingEncoding:NSUTF8StringEncoding]);
            }
#endif
            
        }
        else if (![NSThread currentThread].isCancelled && cacheAction != TriMetXMLNoCaching && !self.itemFromCache)
        {
            if (cacheAction == TriMetXMLUseShortTermCache)
            {
                [shortTermCache addToCache:cacheKey item:self.rawData write:YES];
            }
            else
            {
                [routeCache addToCache:cacheKey     item:self.rawData write:(routeCache.ageOutDays > 0)];
                
            }
        }
        
        [self clearRawData];
        
        self.oneTimeDelegate = nil;
        
        return succeeded;
    }
}

- (bool)cacheSelectors
{
#ifdef XMLLOGGING
    return YES;
#else
    return NO;
#endif
}

- (void)initSelectors
{
    static NSMutableDictionary *allStartSelectors = nil;
    static NSMutableDictionary *allEndSelectors = nil;
    
    NSString *name = NSStringFromClass([self class]);
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allStartSelectors = [NSMutableDictionary dictionary];
        allEndSelectors = [NSMutableDictionary dictionary];
    });
    
    if (self.cacheSelectors)
    {
        self.startSels = allStartSelectors[name];
        if (self.startSels == nil)
        {
            self.startSels = [NSMutableDictionary dictionary];
            allStartSelectors[name] = self.startSels;
        }
    
        self.endSels = allEndSelectors[name];
        if (self.endSels == nil)
        {
            self.endSels = [NSMutableDictionary dictionary];
            allEndSelectors[name] = self.endSels;
        }
    }
    else
    {
        self.startSels = [NSMutableDictionary dictionary];
        self.endSels   = [NSMutableDictionary dictionary];
    }
}

- (bool)parseRawData:(NSError **)error
{
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
    if (parseError && error && ![NSThread currentThread].isCancelled) {
        *error = parseError;
    }
    if (parseError==nil)
    {
        succeeded = YES;
    }
    
    
#ifdef XMLLOGGING
    [self.startSels enumerateKeysAndObjectsUsingBlock: ^void (NSString* element, NSValue* sel, BOOL *stop)
     {
         DEBUG_LOG_RAW(@"start element %@ %p", element, sel.pointerValue);
     }];
    
    [self.endSels enumerateKeysAndObjectsUsingBlock: ^void (NSString* element, NSValue* sel, BOOL *stop)
     {
         DEBUG_LOG_RAW(@"end element %@ %p", element, sel.pointerValue);
     }];
#endif
    
    return succeeded;
    
}

-(void)clearRawData
{
    if (!self.keepRawData && ![UserPrefs sharedInstance].debugXML)
    {
        self.rawData = nil;
    }
}

-(void)appendQueryAndData:(NSMutableData *)buffer
{
    NSString *start = nil;
    if (self.fullQuery)
    {
        start = [NSString stringWithFormat:@"<query url=\"%@\">", [TriMetXML insertXMLcodes:self.fullQuery] ];
    }
    else
    {
        start = [NSString stringWithFormat:@"<query>"];
    }
    
    [buffer appendData:[start dataUsingEncoding:NSUTF8StringEncoding]];
    if (self.rawData)
    {
        [buffer appendData:self.rawData];
    }
    
    [buffer appendData:[@"</query>" dataUsingEncoding:NSUTF8StringEncoding]];
    
}

#pragma mark Parser callbacks

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if ([NSThread currentThread].isCancelled)
    {
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

+ (void)makeReplacements
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        replacements = @{ @"<"     : @"&lt;",
                          @">"     : @"&gt;",
                          @"\""    : @"&quot;",
                          @"'"     : @"&apos;",
                          @" "     : @"&nbsp;"
                          };
    });
}

+ (NSString *)insertXMLcodes:(NSString *)string
{
    [TriMetXML makeReplacements];
    
    NSMutableString *ms = [NSMutableString string];
    [ms appendString:string];
    
    // Ampersand must be done first as it could change the others
    [ms replaceOccurrencesOfString:@"&"
                        withString:@"&amp;"
                           options:NSLiteralSearch
                             range:NSMakeRange(0, ms.length)];
    
    [replacements enumerateKeysAndObjectsUsingBlock: ^void (NSString* dictionaryKey, NSString* val, BOOL *stop)
     {
         [ms replaceOccurrencesOfString:dictionaryKey
                             withString:val
                                options:NSLiteralSearch
                                  range:NSMakeRange(0, ms.length)];
     }];
    
    return ms;
    
}

+ (NSString *)replaceXMLcodes:(NSString *)string
{
    [TriMetXML makeReplacements];

    NSMutableString *ms = [NSMutableString string];
    [ms appendString:string];
    
    [replacements enumerateKeysAndObjectsUsingBlock: ^void (NSString* dictionaryKey, NSString* val, BOOL *stop)
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

-(SEL)selectorForElement:(NSString*)elementName format:(NSString*)format cache:(NSMutableDictionary<NSString *, NSValue*> *)cache debug:(NSString*)debug
{
    // PROFILING_ENTER_FUNCTION;
    
    NSString *lowerElName   = [elementName lowercaseString];
    NSValue *selValue       = [cache objectForKey:lowerElName];
    SEL elementSelector     = nil;
    
    if (selValue == nil)
    {
        NSString *selName = [NSString stringWithFormat:format, lowerElName];
        elementSelector = NSSelectorFromString(selName);
        
        if (![self respondsToSelector:elementSelector])
        {
            elementSelector = nil;
#ifdef XMLLOGGING
            DEBUG_LOG_RAW(@"XML:%@ <- not %@\n", debug, elementName);
#endif
        }
#ifdef XMLLOGGING
        else
        {
            DEBUG_LOG_RAW(@"XML:%@ <-     %@\n", debug, elementName);
        }
#endif
        [cache setObject:[NSValue valueWithPointer:elementSelector] forKey:lowerElName];
    }
    else if (selValue.pointerValue != nil)
    {
        elementSelector = selValue.pointerValue;
#ifdef XMLLOGGING
        DEBUG_LOG_RAW(@"XML:%@ ->    %@\n", debug, elementName);
#endif
    }
#ifdef XMLLOGGING
    else
    {
        DEBUG_LOG_RAW(@"XML:%@ -> not %@\n", debug, elementName);
    }
#endif
    
    // PROFILING_EXIT_FUNCTION;
    
    return elementSelector;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([NSThread currentThread].isCancelled)
    {
        [parser abortParsing];
        return;
    }
    
    if (qName) {
        elementName = qName;
    }
    
#ifdef XMLLOGGING
    DEBUG_LOG_RAW(@"XML: %@",elementName);
    
    NSEnumerator *i = attributeDict.keyEnumerator;
    NSString *key = nil;
    
    
    while ((key = i.nextObject))
    {
        DEBUG_LOG_RAW(@"XML:  %@ = %@\n", key, attributeDict[key]);
    }
#endif
    
    SEL elementSelector = [self selectorForElement:elementName format:XML_START_SELECTOR cache:self.startSels debug:@"start"];
    if (elementSelector != nil)
    {
#ifdef XML_SHORT_SELECTORS
        IMP imp = [self methodForSelector:elementSelector];
        void (*func)(id, SEL, NSDictionary*) = (void *)imp;
        func(self, elementSelector, attributeDict);
        
        // [self performSelector:elementSelector withObject:attributeDict];
#else
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:elementSelector]];
        [inv setSelector:elementSelector];
        [inv setTarget:self];
        [inv setArgument:&(parser) atIndex:2]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        [inv setArgument:&(elementName) atIndex:3]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        [inv setArgument:&(namespaceURI) atIndex:4]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        [inv setArgument:&(qName) atIndex:5]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        [inv setArgument:&(attributeDict) atIndex:6]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        
        [inv invoke];
#endif
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([NSThread currentThread].isCancelled)
    {
        [parser abortParsing];
        return;
    }
    
    if (qName) {
        elementName = qName;
    }
    
#ifdef XMLLOGGING
    if (self.contentOfCurrentProperty != nil)
    {
        DEBUG_LOG_RAW(@"  Content: %@\n", self.contentOfCurrentProperty);
    }
#endif
    
    SEL elementSelector = [self selectorForElement:elementName format:XML_END_SELECTOR cache:self.endSels debug:@"end  "];
    
    if (elementSelector != nil)
    {
        
#ifdef XML_SHORT_SELECTORS
        IMP imp = [self methodForSelector:elementSelector];
        void (*func)(id, SEL) = (void *)imp;
        func(self, elementSelector);
        // [self performSelector:elementSelector];
#else
        NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:elementSelector]];
        [inv setSelector:elementSelector];
        [inv setTarget:self];
        [inv setArgument:&(parser) atIndex:2]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        [inv setArgument:&(elementName) atIndex:3]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        [inv setArgument:&(namespaceURI) atIndex:4]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        [inv setArgument:&(qName) atIndex:5]; //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
        
        [inv invoke];
#endif
    }
}

- (void)expectedSize:(long long)expected
{
    if (self.oneTimeDelegate)
    {
        [self.oneTimeDelegate TriMetXML:self expectedSize:expected];
    }
}
- (void)progressed:(long long)progress
{
    if (self.oneTimeDelegate)
    {
        [self.oneTimeDelegate TriMetXML:self progress:progress of:_expected];
    }
}
@end
