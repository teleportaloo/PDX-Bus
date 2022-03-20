//
//  TriMetXML.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetTypes.h"
#import "StoppableFetcher.h"
#import "DebugLogging.h"

@class Settings;
@class StopNameCacheManager;
@class QueryCacheManager;

typedef enum CacheActionEnum {
    TriMetXMLCheckRouteCache,
    TriMetXMLForceFetchAndUpdateRouteCache,
    TrIMetXMLRouteCacheReadOrFetch,
    TriMetXMLNoCaching,
    TriMetXMLUseShortTermCache
} CacheAction;


#define XmlParseSync() @synchronized(TriMetXML.parseSyncObject)

@class TriMetXML;

typedef NSString * _Nonnull (^XMLQueryBlock) (TriMetXML *_Nonnull xml, NSString * _Nonnull query);

@protocol TriMetXMLDelegate<NSObject>

- (void)triMetXML:(TriMetXML *_Nonnull)xml startedFetchingData:(bool)fromCache;
- (void)triMetXML:(TriMetXML *_Nonnull)xml finishedFetchingData:(bool)fromCache;
- (void)triMetXML:(TriMetXML *_Nonnull)xml incrementalBytes:(long long)incremental;

@end

@interface TriMetXML<ItemType> : StoppableFetcher <NSXMLParserDelegate, NSFastEnumeration> {
    bool _hasData;
}

@property (nonatomic, copy) XMLQueryBlock _Nonnull queryBlock;
@property (nonatomic, strong) NSMutableString *_Nullable contentOfCurrentProperty;
@property (nonatomic, weak) id<TriMetXMLDelegate> _Nullable oneTimeDelegate;
@property (nonatomic, strong) NSMutableArray<ItemType> *_Nullable items;
@property (nonatomic, strong) NSError *_Nullable parseError;
@property (nonatomic, strong) NSData *_Nullable htmlError;
@property (nonatomic, strong) NSDate *_Nullable cacheTime;
@property (nonatomic, strong) NSDate *_Nullable httpDate;
@property (nonatomic, copy) NSString *_Nullable fullQuery;
@property (nonatomic, readonly) NSInteger count;
@property (nonatomic, readonly) bool gotData;
@property (nonatomic) bool itemFromCache;
@property (nonatomic) bool keepRawData;


#if defined XML_TEST_DATA
@property (nonatomic, retain)     NSArray<NSString *> *testURLs;
#endif

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *_Nonnull)state objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer count:(NSUInteger)len;
- (ItemType _Nonnull)objectAtIndexedSubscript:(NSInteger)index;



- (BOOL)startParsing:(NSString *_Nonnull)query cacheAction:(CacheAction)cacheAction;
- (void)appendQueryAndData:(NSMutableData *_Nonnull)buffer;
- (NSString *_Nonnull)fullAddressForQuery:(NSString *_Nonnull)query;
- (NSString *_Nonnull)displayTriMetDate:(TriMetTime)time;
- (NSString *_Nonnull)displayDate:(NSDate *_Nonnull)date;
- (BOOL)startParsing:(NSString *_Nonnull)query;
- (bool)parseRawData;
- (void)addItem:(ItemType _Nonnull)item;
- (void)clearRawData;
- (void)clearItems;
- (void)initItems;

- (NSTimeInterval)secondsUntilEndOfServiceSunday:(NSDate * _Nonnull)date;

// Subclass may override to make static tables
- (bool)cacheSelectors;

+ (StopNameCacheManager *_Nonnull)getStopNameCacheManager;
+ (NSString *_Nonnull)replaceXMLcodes:(NSString *_Nonnull)string;
+ (NSString *_Nonnull)insertXMLcodes:(NSString *_Nonnull)string;
+ (BOOL)isDataSourceAvailable:(BOOL)forceCheck;
+ (bool)deleteCacheFile;
+ (NSUInteger)cacheSizeInBytes;
+ (instancetype _Nonnull)xml;
+ (instancetype _Nonnull)xmlWithOneTimeDelegate:(id<TriMetXMLDelegate> _Nonnull)delegate;
+ (NSObject * _Nonnull)parseSyncObject;

+ (NSString *_Nonnull)appId;

@end
