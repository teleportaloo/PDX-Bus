//
//  TriMetXML.m
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

#import "TriMetXML.h"
#import "TriMetTypes.h"
#import <SystemConfiguration/SystemConfiguration.h>
#include "debug.h"
#include "TriMetTimesAppDelegate.h"
#include "AppDelegateMethods.h"
#include "QueryCacheManager.h"
#include "UserPrefs.h"

@implementation TriMetXML

@synthesize contentOfCurrentProperty = _contentOfCurrentProperty;
@synthesize itemArray = _itemArray;
@synthesize htmlError = _htmlError;
@synthesize cacheTime = _cacheTime;
@synthesize itemFromCache = _itemFromCache;
@synthesize fullQuery = _fullQuery;


#pragma mark Cache

static QueryCacheManager *routeCache = nil;
static QueryCacheManager *shortTermCache = nil;


+ (void)initCaches
{
   if (routeCache == nil)
   {
       routeCache = [[QueryCacheManager alloc] initWithFileName:@"queryCache.plist"];
   }
    
   if (shortTermCache == nil)
   {
       shortTermCache = [[QueryCacheManager alloc] initWithFileName:@"shortTermCache.plist"];
       shortTermCache.maxSize = [UserPrefs getSingleton].maxRecentStops;
   }
}

+ (bool)deleteCacheFile
{
    [TriMetXML initCaches];
    
    [routeCache deleteCacheFile];
    [shortTermCache deleteCacheFile];
    
    return YES;
}


- (void)dealloc {
	self.contentOfCurrentProperty = nil;
	self.itemArray = nil;
	self.htmlError = nil;
	self.cacheTime = nil;
	[super dealloc];
}

#pragma mark Data checks

+ (BOOL)isDataSourceAvailable:(BOOL)forceCheck
{
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
    return YES;
}

- (bool)gotData
{
	return hasData;
}

#pragma mark Item array


- (id)itemAtIndex:(int)index
{
	if (self.itemArray != nil)
	{
		return [self.itemArray objectAtIndex:index];
	}
	return nil;
}

- (void)addItem:(id)item
{
	[self.itemArray addObject:item];
}

- (void)clearArray
{
	self.itemArray = nil;
}

- (void)initArray
{
	self.itemArray = [[[ NSMutableArray alloc ] init] autorelease];
}


- (int)safeItemCount
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
	NSDate *queryTime = [NSDate dateWithTimeIntervalSince1970: TriMetToUnixTime(time)]; 
	return [self displayDate:queryTime];
}

- (NSString *)displayDate:(NSDate *)queryTime
{
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
	return [NSString stringWithFormat:@"Updated: %@", 
			[dateFormatter stringFromDate:queryTime]];
}


- (NSString *)safeValueFromDict:(NSDictionary *)dict valueForKey:(NSString *)key
{
	NSString *val = [dict valueForKey:key];
	
	if (val == nil)
	{
		val = @"?";
	}
	
	return val;
}

- (TriMetTime)getTimeFromAttribute:(NSDictionary *)dict valueForKey:(NSString *)key
{
	TriMetTime qT = 0;
	NSString * val = [self safeValueFromDict:dict valueForKey:key];
	if (val)
	{
		NSScanner *scanner = [NSScanner scannerWithString:val];	
		[scanner scanLongLong: &qT];
	}
	return qT;
}


- (TriMetDistance)getDistanceFromAttribute:(NSDictionary *)dict valueForKey:(NSString *)key
{
	NSString * val = [self safeValueFromDict:dict valueForKey:key];
	NSScanner *scanner = [NSScanner scannerWithString:val];	
	int dist;
	[scanner scanInt: &dist];
	return dist;
}

- (double)getCoordFromAttribute:(NSDictionary *)dict valueForKey:(NSString *)key
{
	NSString * val = [self safeValueFromDict:dict valueForKey:key];
	NSScanner *scanner = [NSScanner scannerWithString:val];	
	double coord;
	[scanner scanDouble: &coord];
	return coord;
	
}

#pragma mark Parsing init

- (NSString*)fullAddressForQuery:(NSString *)query
{
	NSString *str = nil;
	
	if ([query characterAtIndex:[query length]-1] == '&')
	{
		str = [NSString stringWithFormat:@"http://developer.trimet.org/ws/V1/%@&appID=%@", query, TRIMET_APP_ID];
	}
	else
	{
		str = [NSString stringWithFormat:@"http://developer.trimet.org/ws/V1/%@/appID/%@", query, TRIMET_APP_ID];
	}
	
	return str;
	
}

- (BOOL)startParsing:(NSString *)query parseError:(NSError **)error
{
	return [self startParsing:query parseError:error cacheAction:TriMetXMLNoCaching];
}

- (BOOL)startParsing:(NSString *)query parseError:(NSError **)error cacheAction:(CacheAction)cacheAction
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int tries = 2;
	BOOL succeeded = NO;
    self.itemFromCache = NO;
	int days = [UserPrefs getSingleton].routeCacheDays;
	
	hasData = NO;
	[self clearArray];
	
	NSString *str = [self fullAddressForQuery:query];
    NSString *cacheKey = [QueryCacheManager getCacheKey:str];
    
    [TriMetXML initCaches];
	
	DEBUG_LOG(@"Query: %@\n", str);
    
    if (([UserPrefs getSingleton].debugXML))
    {
        self.fullQuery = str;
    }
	
	if (cacheAction == TriMetXMLOnlyReadFromCache)
	{
		tries = 1;
	}
	
	while(!hasData && tries > 0 && ![NSThread currentThread].isCancelled)
	{
	
		if ([TriMetXML isDataSourceAvailable:NO] == YES && ![NSThread currentThread].isCancelled) 
		{
			self.rawData = nil;
			if (cacheAction != TriMetXMLNoCaching && cacheAction != TriMetXMLUseShortCache)
			{
				
                NSArray *cachedArray = [routeCache getCachedQuery:cacheKey];
				
				if (cachedArray != nil)
				{
					NSDate *itemDate = [cachedArray objectAtIndex:kCacheDateAndTime];
					NSCalendar *cal = [NSCalendar currentCalendar];
					int units = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSWeekCalendarUnit;
					NSDateComponents *itemDateComponents = [cal components:units fromDate:itemDate];
					NSDateComponents *nowDateComponents =  [cal components:units fromDate:[NSDate date]];
					
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
					
					if (
						cacheAction != TriMetXMLUpdateCache
						&&
						 (
							(days == 1 && (		itemDateComponents.year  == nowDateComponents.year 
										   &&	itemDateComponents.month == nowDateComponents.month 
									       &&	itemDateComponents.day   == nowDateComponents.day))
						 ||
							(days == 7 && (		itemDateComponents.year  == nowDateComponents.year
										   &&	itemDateComponents.week  == nowDateComponents.week))
						 ||
						    (days == 0)
						 )
					    )
					{
						self.rawData	= [cachedArray objectAtIndex:kCacheData];
						self.itemFromCache	= YES;
						self.cacheTime	= itemDate;
					}
					else
					{
						[routeCache removeFromCache:cacheKey]; 
					}
				}
				
				if (self.rawData == nil && cacheAction!=TriMetXMLOnlyReadFromCache)
				{
					self.cacheTime = [NSDate date];
					[self fetchDataAsynchronously:str];
				}

			}
			else {
				self.cacheTime = [NSDate date];
				[self fetchDataAsynchronously:str];
			}

			if (self.rawData !=nil)
			{
				succeeded = [self parseRawData:error];
			}
		}
		tries --;
	}
    
    if (!hasData && cacheAction == TriMetXMLUseShortCache)
    {
        NSArray *cachedArray = [shortTermCache getCachedQuery:cacheKey];
        
        if (cachedArray != nil)
        {
            NSDate *itemDate = [cachedArray objectAtIndex:kCacheDateAndTime];
          
            NSTimeInterval cacheAge = [itemDate timeIntervalSinceNow];
            
            if ((-cacheAge) < 2 * 60 * 60)
            {
                self.rawData	= [cachedArray objectAtIndex:kCacheData];
                self.itemFromCache	= YES;
                self.cacheTime	= itemDate;
                succeeded       = [self parseRawData:error];
            }
            else
            {
                [shortTermCache removeFromCache:cacheKey]; 
            }
        }
    }
	
	if (!hasData && ![NSThread currentThread].isCancelled)
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
        if (cacheAction == TriMetXMLUseShortCache)
        {
            [shortTermCache addToCache:cacheKey item:self.rawData write:YES];
        }
        else
        {
            [routeCache addToCache:cacheKey     item:self.rawData write:(days > 0)];
		
        }
    }
	
	[self clearRawData];
	
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
	[parser setDelegate:self];
	// Depending on the XML document you're parsing, you may want to enable these features of NSXMLParser.
	[parser setShouldProcessNamespaces:NO];
	[parser setShouldReportNamespacePrefixes:NO];
	[parser setShouldResolveExternalEntities:NO];
	
	[self clearArray];
	
	[parser parse];
	
	NSError *parseError = [parser parserError];
	if (parseError && error) {
		*error = parseError;
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
    if (![UserPrefs getSingleton].debugXML)
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

typedef struct {
	char * code;
	char * replacement;
} XMLreplacements;

typedef struct
{
	NSString *code;
	NSString *replacement;
} XMLreplacementsNSStrings;

static XMLreplacements replacements[] =
{
{ "&amp;", "&" },
{ "&lt;", "<" },
{ "&gt;", ">" },
{ "&quot;", "\""},
{ "&apos;","'"},
{ "&nbsp;", " "},
{ NULL, NULL }
	
};

static XMLreplacementsNSStrings *replacementsNsString = nil;

- (void)makeReplacementArray
{
	if (replacementsNsString == nil)
	{
        
        XMLreplacementsNSStrings *j;
        
		XMLreplacements *i;
		
		replacementsNsString = malloc(sizeof(XMLreplacementsNSStrings) * (sizeof(replacements) / sizeof(XMLreplacements)));
		
		for (i=replacements, j=replacementsNsString ; i->code !=NULL; i++, j++)
		{
			j->replacement = [[NSString stringWithUTF8String:i->replacement] retain];
			j->code        = [[NSString stringWithUTF8String:i->code] retain];
		}
		j->code = nil;
		j->replacement = nil;
	}
}


- (NSString *)insertXMLcodes:(NSString *)string
{
	
	XMLreplacementsNSStrings *j;
	
    
    [self makeReplacementArray];
	
	NSMutableString *ms = [[[NSMutableString alloc] init] autorelease];
	[ms appendString:string];
	
	for (j=replacementsNsString; j->code !=NULL; j++)
	{
		[ms replaceOccurrencesOfString:j->replacement
							withString:j->code
                               options:NSLiteralSearch
                                 range:NSMakeRange(0, [ms length])];
		
        //- (NSUInteger)replaceOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(NSStringCompareOptions)options range:(NSRange)searchRange;
	}
	return ms;
	
}

- (NSString *)replaceXMLcodes:(NSString *)string
{
    XMLreplacementsNSStrings *j;

	[self makeReplacementArray];

	NSMutableString *ms = [[[NSMutableString alloc] init] autorelease];
	[ms appendString:string];
	
	for (j=replacementsNsString; j->code !=NULL; j++)
	{
		[ms replaceOccurrencesOfString:j->code 
							withString:j->replacement 
							options:NSLiteralSearch 
							range:NSMakeRange(0, [ms length])]; 
		
	//- (NSUInteger)replaceOccurrencesOfString:(NSString *)target withString:(NSString *)replacement options:(NSStringCompareOptions)options range:(NSRange)searchRange;
	}
	return ms;
	
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
#ifdef DEBUGLOGGING
    if (qName) {
        elementName = qName;
    }
    
    DEBUG_LOG(@"Element: %@\n", elementName);
    
    NSEnumerator *i = attributeDict.keyEnumerator;
    NSString *key = nil;
    
    
    while ((key = i.nextObject))
    {
        DEBUG_LOG(@"  %@ = %@\n", key, [attributeDict objectForKey:key]);
    }
#endif
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
#ifdef DEBUGLOGGING
    if (self.contentOfCurrentProperty != nil)
    {
        DEBUG_LOG(@"  Content: %@\n", self.contentOfCurrentProperty);
    }
#endif
}
@end
