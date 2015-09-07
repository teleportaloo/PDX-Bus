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

typedef enum  {
	TriMetXMLOnlyReadFromCache,
	TriMetXMLUpdateCache,
	TriMetXMLNoCaching,
    TriMetXMLUseShortCache
} CacheAction;

@interface TriMetXML : StoppableFetcher <NSXMLParserDelegate> {
	NSMutableString *_contentOfCurrentProperty;	
	NSMutableArray  *_itemArray;
	bool hasData;
	NSData *_htmlError;
	NSDate *_cacheTime;
    bool    _itemFromCache;
    NSString *_fullQuery;
}



- (NSString *)safeValueFromDict:(NSDictionary *)dict valueForKey:(NSString *)key;
- (BOOL)startParsing:(NSString *)query parseError:(NSError **)error;
- (BOOL)startParsing:(NSString *)query parseError:(NSError **)error cacheAction:(CacheAction)cacheAction;
- (TriMetTime)getTimeFromAttribute:(NSDictionary *)dict valueForKey:(NSString *)key;
- (TriMetDistance)getDistanceFromAttribute:(NSDictionary *)dict valueForKey:(NSString *)key;
- (double)getCoordFromAttribute:(NSDictionary *)dict valueForKey:(NSString *)key;
- (bool)getBoolFromAttribute:(NSDictionary *)dict valueForKey:(NSString *)key;
+ (BOOL)isDataSourceAvailable:(BOOL)forceCheck;
- (NSInteger)safeItemCount;
- (id)itemAtIndex:(NSInteger)index;
- (void)addItem:(id)item;
- (void)clearArray;
- (void)initArray;
- (NSString *)replaceXMLcodes:(NSString *)string;
- (NSString *)insertXMLcodes:(NSString *)string;
- (bool)gotData;
+ (bool)deleteCacheFile;
- (NSString*)displayTriMetDate:(TriMetTime)time;
- (NSString*)displayDate:(NSDate *)date;
- (void)clearRawData;
- (bool)parseRawData:(NSError **)error;
- (void)appendQueryAndData:(NSMutableData *)buffer;
+ (StopNameCacheManager *)getStopNameCacheManager;
- (NSString*)fullAddressForQuery:(NSString *)query;




@property (nonatomic) bool itemFromCache;
@property (nonatomic, retain) NSMutableArray  *itemArray;
@property (nonatomic, retain) NSMutableString *contentOfCurrentProperty;
@property (nonatomic, retain) NSData *htmlError;
@property (nonatomic, retain) NSDate *cacheTime;
@property (nonatomic, retain) NSString *fullQuery;

@end
