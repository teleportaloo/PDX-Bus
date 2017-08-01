//
//  TriMetXML.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TriMetTypes.h"
#import "StoppableFetcher.h"

@class UserPrefs;
@class StopNameCacheManager;


@interface NSDictionary (TriMetCaseInsensitive)

- (id)objectForCaseInsensitiveKey:(NSString *)key;

- (NSString *)safeValueForKey:(NSString *)key;
- (TriMetTime)getTimeForKey:(NSString *)key;
- (NSInteger)getNSIntegerForKey:(NSString *)key;
- (TriMetDistance)getDistanceForKey:(NSString *)key;
- (double)getDoubleForKey:(NSString *)key;
- (bool)getBoolForKey:(NSString *)key;

@end

typedef enum  {
	TriMetXMLCheckCache,
	TriMetXMLForceFetchAndUpdateCache,
    TrIMetXMLCacheReadOrFetch,
	TriMetXMLNoCaching,
    TriMetXMLUseShortTermCache
} CacheAction;

#define START_ELEMENT(typeName) - (void)parser:(NSXMLParser *)parser didStartX##typeName:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
#define END_ELEMENT(typeName)   - (void)parser:(NSXMLParser *)parser didEndX##typeName:(NSString *)  elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName

#define ELTYPE(typeName) (NSOrderedSame == [elementName caseInsensitiveCompare:@#typeName])
#define ATRVAL(attr)     ([attributeDict safeValueForKey:@#attr])
#define ATRTIM(attr)     ([attributeDict getTimeForKey:@#attr])
#define ATRINT(attr)     ([attributeDict getNSIntegerForKey:@#attr])
#define ATRBOOL(attr)    ([attributeDict getBoolForKey:@#attr])
#define ATRCOORD(attr)   ([attributeDict getDoubleForKey:@#attr])
#define ATRDIST(attr)    ([attributeDict getDistanceForKey:@#attr])
#define ATREQ(attr, val) ([attr caseInsensitiveCompare:val] == NSOrderedSame)



@class TriMetXML;

@protocol TriMetXMLDelegate<NSObject>

- (void)TriMetXML:(TriMetXML*)xml startedFetchingData:(bool)fromCache;
- (void)TriMetXML:(TriMetXML*)xml finishedFetchingData:(bool)fromCache;
- (void)TriMetXML:(TriMetXML*)xml startedParsingData:(NSUInteger)size;
- (void)TriMetXML:(TriMetXML*)xml finishedParsingData:(NSUInteger)size;

@end

@interface TriMetXML<ObjectType> : StoppableFetcher <NSXMLParserDelegate, NSFastEnumeration> {
	NSMutableString *               _contentOfCurrentProperty;
	NSMutableArray<ObjectType>  *   _itemArray;
	bool                            _hasData;
	NSData *                        _htmlError;
	NSDate *                        _cacheTime;
    bool                            _itemFromCache;
    NSString *                      _fullQuery;
    id<TriMetXMLDelegate>           _oneTimeDelegate;
    NSMutableDictionary<NSString *, NSValue *> *_startSelectors;
    NSMutableDictionary<NSString *, NSValue *> *_endSelectors;
}



- (BOOL)startParsing:(NSString *)query;
- (BOOL)startParsing:(NSString *)query cacheAction:(CacheAction)cacheAction;

+ (BOOL)isDataSourceAvailable:(BOOL)forceCheck;
@property (nonatomic, readonly) NSInteger count;
- (ObjectType)objectAtIndexedSubscript:(NSInteger)index;
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id [])buffer count:(NSUInteger)len;
- (void)addItem:(ObjectType)item;
- (void)clearArray;
- (void)initArray;
- (NSString *)replaceXMLcodes:(NSString *)string;
- (NSString *)insertXMLcodes:(NSString *)string;
@property (nonatomic, readonly) bool gotData;
+ (bool)deleteCacheFile;
- (NSString*)displayTriMetDate:(TriMetTime)time;
- (NSString*)displayDate:(NSDate *)date;
- (void)clearRawData;
- (bool)parseRawData:(NSError **)error;
- (void)appendQueryAndData:(NSMutableData *)buffer;
+ (StopNameCacheManager *)getStopNameCacheManager;
- (NSString*)fullAddressForQuery:(NSString *)query;

+ (instancetype)xml;


@property (nonatomic) bool itemFromCache;
@property (nonatomic, retain) NSMutableArray  *itemArray;
@property (nonatomic, retain) NSMutableString *contentOfCurrentProperty;
@property (nonatomic, retain) NSData *htmlError;
@property (nonatomic, retain) NSDate *cacheTime;
@property (nonatomic, copy)   NSString *fullQuery;
@property (nonatomic, retain) id<TriMetXMLDelegate> oneTimeDelegate;
@property (nonatomic, retain) NSMutableDictionary<NSString *, NSValue *> *startSelectors;
@property (nonatomic, retain) NSMutableDictionary<NSString *, NSValue *> *endSelectors;

@end

