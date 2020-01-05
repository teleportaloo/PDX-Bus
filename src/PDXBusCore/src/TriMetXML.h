//
//  TriMetXML.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import "TriMetTypes.h"
#import "StoppableFetcher.h"
#import "DebugLogging.h"

@class UserPrefs;
@class StopNameCacheManager;
@class QueryCacheManager;


@interface NSDictionary (TriMetCaseInsensitive)

- (NSString *_Nullable)nullOrSafeValueForKey:(NSString *_Nonnull)key;
- (id _Nullable)objectForCaseInsensitiveKey:(NSString *_Nonnull)key;
- (NSNumber *_Nullable)nullOrSafeNumForKey:(NSString *_Nonnull)key;
- (NSString *_Nonnull)safeValueForKey:(NSString *_Nonnull)key;
- (TriMetDistance)getDistanceForKey:(NSString *_Nonnull)key;
- (NSDate *_Nullable)getDateForKey:(NSString *_Nonnull)key;
- (NSInteger)zeroOrSafeIntForKey:(NSString *_Nonnull)key;
- (NSInteger)getNSIntegerForKey:(NSString *_Nonnull)key;
- (TriMetTime)getTimeForKey:(NSString *_Nonnull)key;
- (double)getDoubleForKey:(NSString *_Nonnull)key;
- (bool)getBoolForKey:(NSString *_Nonnull)key;

@end

typedef enum  {
    TriMetXMLCheckCache,
    TriMetXMLForceFetchAndUpdateCache,
    TrIMetXMLCacheReadOrFetch,
    TriMetXMLNoCaching,
    TriMetXMLUseShortTermCache
} CacheAction;

#define XML_SHORT_SELECTORS 1

#ifdef XML_SHORT_SELECTORS

#define XML_START_SELECTOR                      @"startX%@:"
#define XML_START_ELEMENT(typeName)             - (void)startX##typeName:(NSDictionary *)attributeDict
#define CALL_XML_START_ELEMENT_ON(X, typeName)  [X startX##typeName:attributeDict]

#define XML_END_SELECTOR                        @"endX%@"
#define XML_END_ELEMENT(typeName)               - (void)endX##typeName
#define CALL_XML_END_ELEMENT_ON(X,typeName)     [X endX##typeName]

#else

#define XML_START_SELECTOR                      @"parser:didStartX%@:namespaceURI:qualifiedName:attributes:"
#define XML_START_ELEMENT(typeName)             - (void)parser:(NSXMLParser *)parser didStartX##typeName:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
#define CALL_XML_START_ELEMENT_ON(X, typeName)  [X parser:parser didStartX##typeName:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict]

#define XML_END_SELECTOR                        @"parser:didEndX%@:namespaceURI:qualifiedName:"
#define XML_END_ELEMENT(typeName)               - (void)parser:(NSXMLParser *)parser didEndX##typeName:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
#define CALL_XML_END_ELEMENT_ON(X,typeName)     [X parser:parser didEndX##typeName:elementName namespaceURI:namespaceURI qualifiedName:qName]

#endif

#define CALL_XML_END_ELEMENT(typeName)          CALL_XML_END_ELEMENT_ON(self,typeName)
#define CALL_XML_START_ELEMENT(typeName)        CALL_XML_START_ELEMENT_ON(self,typeName)

#define ELTYPE(typeName) (NSOrderedSame == [elementName caseInsensitiveCompare:@#typeName])
#define NATRSTR(attr)    ([attributeDict nullOrSafeValueForKey:@#attr])
#define NATRNUM(attr)    ([attributeDict nullOrSafeNumForKey:@#attr])
#define ZATRINT(attr)    ([attributeDict zeroOrSafeIntForKey:@#attr])
#define ATRSTR(attr)     ([attributeDict safeValueForKey:@#attr])
#define ATRTIM(attr)     ([attributeDict getTimeForKey:@#attr])
#define ATRDAT(attr)     ([attributeDict getDateForKey:@#attr])
#define ATRINT(attr)     ([attributeDict getNSIntegerForKey:@#attr])
#define ATRBOOL(attr)    ([attributeDict getBoolForKey:@#attr])
#define ATRCOORD(attr)   ([attributeDict getDoubleForKey:@#attr])
#define ATRLOC(lt, lg)   [CLLocation withLat:ATRCOORD(lt) lng:ATRCOORD(lg)]
#define ATRDIST(attr)    ([attributeDict getDistanceForKey:@#attr])
#define ATREQ(attr, val) ([attr caseInsensitiveCompare:val] == NSOrderedSame)



@class TriMetXML;

@protocol TriMetXMLDelegate<NSObject>

- (void)TriMetXML:(TriMetXML*_Nonnull)xml finishedParsingData:(NSUInteger)size fromCache:(bool)fromCache;
- (void)TriMetXML:(TriMetXML*_Nonnull)xml startedParsingData:(NSUInteger)size fromCache:(bool)fromCache;
- (void)TriMetXML:(TriMetXML*_Nonnull)xml startedFetchingData:(bool)fromCache;
- (void)TriMetXML:(TriMetXML*_Nonnull)xml finishedFetchingData:(bool)fromCache;
- (void)TriMetXML:(TriMetXML*_Nonnull)xml expectedSize:(long long)expected;
- (void)TriMetXML:(TriMetXML*_Nonnull)xml progress:(long long)progress of:(long long)expected;

@end

@interface TriMetXML<ItemType> : StoppableFetcher <NSXMLParserDelegate, NSFastEnumeration> {
    bool                            _hasData;
}

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSValue *> *_Nullable startSels;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSValue *> *_Nullable endSels;
@property (nonatomic, strong) NSMutableString *_Nullable contentOfCurrentProperty;
@property (nonatomic, strong) id<TriMetXMLDelegate> _Nullable oneTimeDelegate;
@property (nonatomic, strong) NSMutableArray<ItemType> *_Nullable items;
@property (nonatomic, strong) NSData *_Nullable htmlError;
@property (nonatomic, strong) NSDate *_Nullable cacheTime;
@property (nonatomic, copy) NSString *_Nullable fullQuery;
@property (nonatomic, readonly) NSInteger count;
@property (nonatomic, readonly) bool gotData;
@property (nonatomic) bool itemFromCache;
@property (nonatomic) bool keepRawData;

#if defined XML_TEST_DATA
@property (nonatomic, retain)     NSArray<NSString *> *testURLs;
#endif

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *_Nonnull)state objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer count:(NSUInteger)len;
- (BOOL)startParsing:(NSString *_Nonnull)query cacheAction:(CacheAction)cacheAction;
- (ItemType _Nonnull)objectAtIndexedSubscript:(NSInteger)index;
- (void)appendQueryAndData:(NSMutableData *_Nonnull)buffer;
- (NSString*_Nonnull)fullAddressForQuery:(NSString *_Nonnull)query;
- (NSString*_Nonnull)displayTriMetDate:(TriMetTime)time;
- (NSString*_Nonnull)displayDate:(NSDate *_Nonnull)date;
- (BOOL)startParsing:(NSString *_Nonnull)query;
- (bool)parseRawData:(NSError * _Nullable * _Nullable)error;
- (void)addItem:(ItemType _Nonnull)item;
- (void)clearRawData;
- (void)clearItems;
- (void)initItems;

// Subclass may override to make static tables
- (bool)cacheSelectors;

+ (StopNameCacheManager *_Nonnull)getStopNameCacheManager;
+ (NSString *_Nonnull)replaceXMLcodes:(NSString *_Nonnull)string;
+ (NSString *_Nonnull)insertXMLcodes:(NSString *_Nonnull)string;
+ (BOOL)isDataSourceAvailable:(BOOL)forceCheck;
+ (bool)deleteCacheFile;
+ (instancetype _Nonnull)xml;
+ (NSString*_Nonnull)appId;

@end

