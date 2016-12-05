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

@synthesize contentOfCurrentProperty = _contentOfCurrentProperty;
@synthesize itemArray = _itemArray;
@synthesize htmlError = _htmlError;
@synthesize cacheTime = _cacheTime;
@synthesize itemFromCache = _itemFromCache;
@synthesize fullQuery = _fullQuery;
@synthesize oneTimeDelegate = oneTimeDelegate;


#pragma mark Cache

static QueryCacheManager *routeCache = nil;
static QueryCacheManager *shortTermCache = nil;
static StopNameCacheManager *stopNameCache = nil;


+ (instancetype)xml
{
    return [[[[self class] alloc] init] autorelease];
}

+ (void)initCaches
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        routeCache = [[QueryCacheManager alloc] initWithFileName:@"queryCache.plist"];
        
        shortTermCache = [[QueryCacheManager alloc] initWithFileName:@"shortTermCache.plist"];
        shortTermCache.maxSize = [UserPrefs singleton].maxRecentStops;
        
        stopNameCache = [[StopNameCacheManager alloc] init];
    
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


- (void)dealloc {
	self.contentOfCurrentProperty = nil;
	self.itemArray = nil;
	self.htmlError = nil;
	self.cacheTime = nil;
    self.oneTimeDelegate = nil;
    self.fullQuery   = nil;
	[super dealloc];
}

#ifdef PDXBUS_WATCH
- (id)init
{
    if (self = [super init])
    {
        self.giveUp = 30.0;
    }
    
    return self;
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
	if (self.itemArray != nil)
	{
		return self.itemArray[index];
	}
	return nil;
}

- (void)addItem:(id)item
{
	[self.itemArray addObject:item];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id [])buffer count:(NSUInteger)len
{
    return [self.itemArray countByEnumeratingWithState:state objects:buffer count:len];
}

- (void)clearArray
{
	self.itemArray = nil;
}

- (void)initArray
{
    self.itemArray = [NSMutableArray array];
}


- (NSInteger)count
{
	if (_itemArray !=nil)
	{
		return _itemArray.count;
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




#pragma mark Parsing init

- (NSString*)fullAddressForQuery:(NSString *)query
{
	NSString *str = nil;
	
	if ([query characterAtIndex:query.length-1] == '&')
	{
		str = [NSString stringWithFormat:@"%@://developer.trimet.org/ws/V1/%@&appID=%@",
               [UserPrefs singleton].triMetProtocol,
               query, TRIMET_APP_ID];
	}
	else
	{
		str = [NSString stringWithFormat:@"%@://developer.trimet.org/ws/V1/%@/appID/%@",
               [UserPrefs singleton].triMetProtocol,
               query, TRIMET_APP_ID];
	}
	
	return str;
	
}

- (BOOL)startParsing:(NSString *)query
{
	return [self startParsing:query cacheAction:TriMetXMLNoCaching];
}

- (BOOL)startParsing:(NSString *)query cacheAction:(CacheAction)cacheAction
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSError *parseError = nil;
	int tries = 2;
	BOOL succeeded = NO;
    self.itemFromCache = NO;
	int days = [UserPrefs singleton].routeCacheDays;
	
	_hasData = NO;
	[self clearArray];
	
	NSString *str = [self fullAddressForQuery:query];
    NSString *cacheKey = [QueryCacheManager getCacheKey:str];
    
    [TriMetXML initCaches];
	
	DEBUG_LOG(@"Query: %@\n", str);
    
    if (([UserPrefs singleton].debugXML))
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
				
                NSArray *cachedArray = [routeCache getCachedQuery:cacheKey];
				
				if (cachedArray != nil)
				{
					NSDate *itemDate = cachedArray[kCacheDateAndTime];
					NSCalendar *cal = [NSCalendar currentCalendar];
#ifdef PDXBUS_WATCH
					int units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekOfYear;
#else
                    int units = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekCalendarUnit;
#endif
					NSDateComponents *itemDateComponents = [cal components:units fromDate:itemDate];
					NSDateComponents *nowDateComponents =  [cal components:units fromDate:[NSDate date]];
                    
#define DEBUG_DATE(X) DEBUG_LOG(@"%@ %ld %ld\n", @#X,(long)itemDateComponents.X,(long)nowDateComponents.X)
                    
                    DEBUG_DATE(year);
                    DEBUG_DATE(month);
                    DEBUG_DATE(day);
#ifdef PDXBUS_WATCH
                    DEBUG_DATE(weekOfYear);
#else
                    DEBUG_DATE(week);
#endif
                    
                    
                     
					
					/* This code is just to confirm that weeks change on Sunday! */
					/*
					DEBUG_LOG(@"Cached week %d\n", itemDateComponents.week);
					DEBUG_LOG(@"week now %d\n",    nowDateComponents.week);
					
					NSDateComponents *testDateComponents1 = [[[NSDateComponents alloc] init] autorelease];
					testDateComponents1.day = 12; // Saturday
					testDateComponents1.month = 6;
					testDateComponents1.year = 2010;
					
					NSDate *testDate1 = [cal dateFromComponents:testDateComponents1];
					testDateComponents1 = [cal components:NSWeekCalendarUnit fromDate:testDate1];
					DEBUG_LOG(@"week 1 %d\n",    testDateComponents1.week);

					
					testDateComponents1 = [[[NSDateComponents alloc] init] autorelease];
					
					testDateComponents1.day = 13;    // Sunday
					testDateComponents1.month = 6;
					testDateComponents1.year = 2010;
					
					testDate1 = [cal dateFromComponents:testDateComponents1];
					testDateComponents1 = [cal components:NSWeekCalendarUnit fromDate:testDate1];
					DEBUG_LOG(@"week 2 %d\n",    testDateComponents1.week);
					*/
					
					//
					// The cache expires at the end of the current calendar day, or at the end
					// of the current week. Weeks end on Satuday, and the above code proves that
					// the weeks in the calendar also end on Saturdays.
					// This conincides with when TriMet updates the routes, which is at 12am Sunday,
					// or occasionally 12am mid meek.
					//
                    
#ifdef PDXBUS_WATCH
                    int itemWeek = itemDateComponents.weekOfYear;
                    int nowWeek  = nowDateComponents.weekOfYear;
#else
                    int itemWeek = (int)itemDateComponents.week;
                    int nowWeek  = (int)nowDateComponents.week;
#endif
					
					if (
						(cacheAction != TriMetXMLForceFetchAndUpdateCache)
						&&
						 (
							(days == 1 && (		itemDateComponents.year  == nowDateComponents.year 
										   &&	itemDateComponents.month == nowDateComponents.month 
									       &&	itemDateComponents.day   == nowDateComponents.day))
						 ||
							(days == 7 && (		itemDateComponents.year  == nowDateComponents.year
										   &&	itemWeek                 == nowWeek))
						 ||
						    (days == 0)
						 )
					    )
					{
						self.rawData	= cachedArray[kCacheData];
						self.itemFromCache	= YES;
						self.cacheTime	= itemDate;
					}
					else
					{
						[routeCache removeFromCache:cacheKey]; 
					}
				}
				
				if (self.rawData == nil && cacheAction!=TriMetXMLCheckCache)
				{
					self.cacheTime = [NSDate date];
                    if (self.oneTimeDelegate)
                    {
                        [self.oneTimeDelegate TriMetXML:self startedFetchingData:FALSE];
                    }
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
                    [self.oneTimeDelegate TriMetXML:self startedParsingData:self.rawData.length];
                }
                
				succeeded = [self parseRawData:&parseError];
                LOG_PARSE_ERROR(parseError);
                
                if (self.oneTimeDelegate)
                {
                    [self.oneTimeDelegate TriMetXML:self finishedParsingData:self.rawData.length];
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
                self.rawData	= cachedArray[kCacheData];
                self.itemFromCache	= YES;
                self.cacheTime	= itemDate;
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
			NSString *debug = [[[NSString alloc] initWithBytes:[self.htmlError bytes] length:[self.htmlError length] encoding:NSUTF8StringEncoding] autorelease];
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
            [routeCache addToCache:cacheKey     item:self.rawData write:(days > 0)];
		
        }
    }
	
	[self clearRawData];
    
    self.oneTimeDelegate = nil;
	
	[ pool release ];
	return succeeded;
}

-(bool)parseRawData:(NSError **)error
{
	bool succeeded = NO;
	// DEBUG_LOG(@"Results:\n%@\n", [[[NSString alloc] initWithData:self.rawData encoding: NSUTF8StringEncoding] autorelease]); 
	
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
	
	[self clearArray];
	
	[parser parse];
	
    NSError *parseError = parser.parserError;
	if (parseError && error && ![NSThread currentThread].isCancelled) {
        *error = parseError.retain.autorelease;
	}
	if (parseError==nil)
	{
		succeeded = YES;
	}
	
	[parser release];
	
	return succeeded;
	
}

-(void)clearRawData
{
    if (![UserPrefs singleton].debugXML)
    {
        self.rawData = nil;
    }
}

-(void)appendQueryAndData:(NSMutableData *)buffer
{
    NSString *start = nil;
    if (self.fullQuery)
    {
        start = [NSString stringWithFormat:@"<query url=\"%@\">", [self insertXMLcodes:self.fullQuery] ];
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

- (void)makeReplacements
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        replacements = @{ @"<"     : @"&lt;",
                          @">"     : @"&gt;",
                          @"\""    : @"&quot;",
                          @"'"     : @"&apos;",
                          @" "     : @"&nbsp;"
                          }.retain;
    });
}

- (NSString *)insertXMLcodes:(NSString *)string
{
    [self makeReplacements];
    
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

- (NSString *)replaceXMLcodes:(NSString *)string
{
    [self makeReplacements];

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

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
#ifdef XMLLOGGING
    if (qName) {
        elementName = qName;
    }
    
    DEBUG_LOG_RAW(@"XML: %@",elementName);
    
    NSEnumerator *i = attributeDict.keyEnumerator;
    NSString *key = nil;
    
    
    while ((key = i.nextObject))
    {
        DEBUG_LOG_RAW(@"XML:  %@ = %@\n", key, attributeDict[key]);
    }
#endif
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
#ifdef XMLLOGGING
    if (self.contentOfCurrentProperty != nil)
    {
        DEBUG_LOG(@"  Content: %@\n", self.contentOfCurrentProperty);
    }
#endif
}
@end
