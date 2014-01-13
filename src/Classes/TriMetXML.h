//
//  TriMetXML.h
//  TriMetTimes
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import <UIKit/UIKit.h>
#import "TriMetTypes.h"
#import "StoppableFetcher.h"

@class UserPrefs;

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
+ (BOOL)isDataSourceAvailable:(BOOL)forceCheck;
- (int)safeItemCount;
- (id)itemAtIndex:(int)index;
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




@property (nonatomic) bool itemFromCache;
@property (nonatomic, retain) NSMutableArray  *itemArray;
@property (nonatomic, retain) NSMutableString *contentOfCurrentProperty;
@property (nonatomic, retain) NSData *htmlError;
@property (nonatomic, retain) NSDate *cacheTime;
@property (nonatomic, retain) NSString *fullQuery;

@end
