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

@implementation TriMetXML

@synthesize contentOfCurrentProperty = _contentOfCurrentProperty;
@synthesize itemArray = _itemArray;
@synthesize htmlError = _htmlError;
@synthesize cacheTime = _cacheTime;


#pragma mark Cache

static NSMutableDictionary *queryCache = nil;
static NSString *queryCacheFile= nil;

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

+ (void)initCacheFileName
{
	if (queryCacheFile == nil)
	{
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
	
		queryCacheFile = [[documentsDirectory stringByAppendingPathComponent:@"queryCache.plist"] retain];
	}
}
+ (bool)deleteCacheFile
{
	[TriMetXML initCacheFileName];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	bool ret = [fileManager removeItemAtPath:queryCacheFile error:nil];
	
	if (queryCache != nil)
	{
		[queryCache release];
		queryCache = nil;
	}
	return ret;
}

#define kCacheDateAndTime 0
#define kCacheData		1

- (BOOL)startParsing:(NSString *)query parseError:(NSError **)error cacheAction:(CacheAction)cacheAction
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	TriMetTimesAppDelegate *appDelegate = (TriMetTimesAppDelegate *)[[UIApplication sharedApplication] delegate];
	int tries = 2;
	BOOL succeeded = NO;
	BOOL itemFromCache = NO;
	int days = appDelegate.prefs.routeCacheDays;
	
	hasData = NO;
	[self clearArray];
	
	NSString *str = [self fullAddressForQuery:query];
	NSMutableString *cacheKey = nil;
	
	DEBUG_LOG(@"Query: %@\n", str);
	
	if (cacheAction == TriMetXMLOnlyReadFromCache)
	{
		tries = 1;
	}
	
	while(!hasData && tries > 0 && ![NSThread currentThread].isCancelled)
	{
	
		if ([TriMetXML isDataSourceAvailable:NO] == YES && ![NSThread currentThread].isCancelled) 
		{
			self.rawData = nil;
			if (cacheAction != TriMetXMLNoCaching)
			{
				if (queryCache == nil)
				{
					// Check for cache in Documents directory. 
					NSFileManager *fileManager = [NSFileManager defaultManager];
					
									
					
					[TriMetXML initCacheFileName];
					
					if (days > 0 && [fileManager fileExistsAtPath:queryCacheFile] == YES)
					{
						queryCache = [[NSMutableDictionary alloc] initWithContentsOfFile:queryCacheFile];
					}
					
					if (queryCache == nil)
					{
						queryCache = [[NSMutableDictionary alloc] init];
					}
										
					
				}
				
				//
				// Don't put the app id into the cache - we can use the rest of the URL as 
				// the key.
				//
				cacheKey = [[[NSMutableString alloc] initWithString:str] autorelease];
				
				[cacheKey replaceOccurrencesOfString:TRIMET_APP_ID 
											withString:@"" 
											   options:NSCaseInsensitiveSearch 
												 range:NSMakeRange(0, [cacheKey length])];
				
				NSArray *cachedArray = [queryCache objectForKey:cacheKey];
				
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
						itemFromCache	= YES;
						self.cacheTime	= itemDate;
					}
					else
					{
						[queryCache removeObjectForKey:cacheKey]; 
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
	else if (![NSThread currentThread].isCancelled && cacheAction != TriMetXMLNoCaching && !itemFromCache)
	{
		NSMutableArray *arrayToCache = [[[NSMutableArray alloc] init] autorelease];
		
		[arrayToCache insertObject:[NSDate date] atIndex:kCacheDateAndTime];
		[arrayToCache insertObject:self.rawData atIndex:kCacheData];

		[queryCache setObject:arrayToCache forKey:cacheKey];
		
		if (days > 0)
		{
			[queryCache writeToFile:queryCacheFile atomically:YES];
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
	self.rawData = nil;
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

- (NSString *)replaceXMLcodes:(NSString *)string
{
	static XMLreplacementsNSStrings *replacementsNsString;	
	XMLreplacementsNSStrings *j;
	

	if (replacementsNsString == nil)
	{
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

@end
