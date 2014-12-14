//
//  DepartureTimes.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DepartureTimesView.h"
#import "Departure.h"
#import "XMLDepartures.h"
#import "DepartureDetailView.h"
#import "EditBookMarkView.h"
#import "WebViewController.h"
#import "StopDistance.h"

#import "MapViewController.h"
#import "SimpleAnnotation.h"
#import "DepartureTimesByBus.h"
#import "DepartureSortTableView.h"
#import "UserFaves.h"
#import "XMLLocateStops.h"
#import "AlarmTaskList.h"
#import "TripPlannerSummaryView.h"
#import "ProcessQRCodeString.h"
#import "DebugLogging.h"
#import "XMLStops.h"
#import "Vehicle.h"
#import "AlignedBarItemButton.h"
#import "FindByLocationView.h"


#define kSectionDistance	0
#define kSectionTitle		1
#define kSectionTimes		2
#define kSectionTrip		3
#define kSectionFilter		4
#define kSectionProximity	5
#define kSectionNearby		6
#define kSectionOneStop		7
#define kSectionMapOne      8
#define kSectionInfo        9
#define kSectionAccuracy	10
#define kSectionXML         11
#define kSectionStatic		12


#define kDistanceRows		1

#define kTripRows			2
#define kTripRowFrom		0
#define kTripRowTo			1

#define kActionCellId		@"Action"
#define kTitleCellId		@"Title"
#define kAlarmCellId		@"Alarm"
#define kDistanceCellId		@"Distance"
#define kDistanceCellId2	@"Distance2"
#define kStatusCellId		@"Status"

#define kGettingArrivals	@"getting arrivals"
#define kGettingStop        @"getting stop ID";

#define kDictLocation		@"loc"
#define kDictBlock			@"block"
#define kDictNames			@"names"
#define kDictBookmark		@"bookmark"
#define kDictDir            @"dir"
#define kDictRoute          @"route"

#define kRefreshText        NSLocalizedString(@"Refresh", @"Refresh arrivals button")

#define kShowAllStopsOnMap  (-1)

#define DISTANCE_TAG 1
#define ACCURACY_TAG 2

static int depthCount = 0;
#define kMaxDepth 4
 
@implementation DepartureTimesView
@synthesize displayName			= _displayName;
@synthesize visibleDataArray	= _visibleDataArray;
@synthesize	originalDataArray	= _originalDataArray;
@synthesize locationsDb			= _locationsDb;
@synthesize stops				= _stops;
@synthesize refreshTimer		= _refreshTimer;
@synthesize blockSort			= _blockSort;
@synthesize refreshButton		= _refreshButton;
@synthesize lastRefresh			= _lastRefresh;
@synthesize streetcarLocations	= _streetcarLocations;
@synthesize bookmarkLoc			= _bookmarkLoc;
@synthesize bookmarkDesc		= _bookmarkDesc;
@synthesize actionItem			= _actionItem;
@synthesize savedBlock			= _savedBlock;
@synthesize allowSort           = _allowSort;
@synthesize refreshText         = _refreshText;


#define kNonDepartureHeight 35.0

#define kRefreshInterval 60

#define MAX_STOPS 8

- (void)dealloc {
    [self stopTimer];
	self.displayName			= nil;
	self.visibleDataArray		= nil;
	self.locationsDb			= nil;
	self.originalDataArray		= nil;
	self.streetcarLocations		= nil;
	depthCount--;
	self.stops = nil;
	self.refreshButton			= nil;
	self.lastRefresh			= nil;
	self.bookmarkLoc			= nil;
	self.bookmarkDesc			= nil;
	self.actionItem				= nil;
	self.savedBlock				= nil;
    self.vehicleStops           = nil;
    self.refreshText            = nil;
	free(_sectionExpanded);
    
	
	[self clearSections];
	[super dealloc];
}


- (id)init {
	if ((self = [super init]))
	{
		_sectionRows = NULL;
		_sectionExpanded = nil;
		self.title = @"Arrivals";
		self.originalDataArray = [[[NSMutableArray alloc] init] autorelease];
		self.visibleDataArray = self.originalDataArray;
		self.locationsDb = [StopLocations getDatabase];
		depthCount++;
        _timerPaused = NO;
	}
	return self;
}

- (CGFloat) heightOffset
{
    if (self.iOS7style && (LargeScreenStyle([self screenWidth]) || (self.screenWidth >= WidthiPhone6)))
    {
        return -[UIApplication sharedApplication].statusBarFrame.size.height;
    }
	return 0.0;
}

#pragma mark Data sorting and manipulation

- (id<DepartureTimesDataProvider>)departureData:(NSInteger)i
{
	return [self.visibleDataArray objectAtIndex:i];
}

- (bool)validStop:(unsigned long) i
{
	id<DepartureTimesDataProvider> dd = [self departureData:i];
	return ([dd DTDataGetSectionHeader]!=nil 
			&&	([dd DTDataGetSafeItemCount] == 0 
				 ||  ([dd DTDataGetSafeItemCount] > 0 && [[dd DTDataGetDeparture:0] errorMessage]==nil)));
}

- (void)sortByBus
{
	if ([self.originalDataArray count] == 0)
	{
		return;
	}
	
	if (!self.blockSort)
	{
		self.visibleDataArray = self.originalDataArray;
		return;
	}
	
	self.visibleDataArray = [[[NSMutableArray alloc] init] autorelease];
	
	int stop;
	int bus;
	int search;
	int insert;
	BOOL found;
	Departure *itemToInsert;
	Departure *firstItemForBus;
	Departure *existingItem;
	DepartureTimesByBus *busRoute;
	XMLDepartures *dd;
	
	for (stop = 0; stop < [self.originalDataArray count]; stop++)
	{
		dd = [self.originalDataArray objectAtIndex:stop];
		for (bus = 0; bus < [dd safeItemCount]; bus++)
		{
			itemToInsert = [dd itemAtIndex:bus];
			found = NO;
			for (search = 0; search < [self.visibleDataArray count]; search ++)
			{
				busRoute = [self.visibleDataArray objectAtIndex:search];
				firstItemForBus = [busRoute DTDataGetDeparture:0];
				
				if (itemToInsert.block !=nil && [firstItemForBus.block isEqualToString:itemToInsert.block])
				{
					for (insert = 0; insert < [busRoute.departureItems count]; insert++)
					{
						existingItem = [busRoute DTDataGetDeparture:insert];
						
						if (existingItem.departureTime > itemToInsert.departureTime)
						{
							[busRoute.departureItems insertObject:itemToInsert atIndex:insert];
							found = YES;
							break;
						}
					}
					if (!found)
					{
						[busRoute.departureItems addObject:itemToInsert];
						found = YES;
					}
					
					break;
				}
			}
			
			if (!found)
			{
				DepartureTimesByBus * newBus = [[DepartureTimesByBus alloc] init];
				[newBus.departureItems addObject:itemToInsert];
				[self.visibleDataArray addObject:newBus];
				[newBus release];
			}
		}
	}
}

+ (BOOL)canGoDeeper
{
	return depthCount < kMaxDepth;
}

- (void)resort
{
	if (self.blockSort)
	{
		self.blockSort = YES;
		[self sortByBus];			
	}
	else {
		self.blockSort = NO;
		self.visibleDataArray = self.originalDataArray;
	}
	
	[self clearSections];
	
	[self reloadData];
}

#pragma Cache warning

- (void)cacheWarningRefresh:(bool)refresh
{
    DEBUG_LOG(@"cacheWarningRefresh %d\n", refresh);

    if (self.originalDataArray.count > 0)
    {
       
        XMLDepartures *first = nil;
        
        for (XMLDepartures *item in self.originalDataArray)
        {
            if (item.itemFromCache)
            {
                first = item;
                break;
            }
        }
        
        if (first && first.itemFromCache)
        {
            self.navigationItem.prompt = kCacheWarning;
        }
        else
        {
            self.navigationItem.prompt = nil;
        }
        
        XMLDepartures *item0 = [self.originalDataArray objectAtIndex:0];
        
        if (item0 && [item0 DTDataQueryTime] > 0)
        {
            NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
            [dateFormatter setDateStyle:kCFDateFormatterNoStyle];
            [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
            NSDate *queryTime = [NSDate dateWithTimeIntervalSince1970: TriMetToUnixTime([item0 DTDataQueryTime])];
            self.secondLine = [NSString stringWithFormat:NSLocalizedString(@"Last updated: %@", @"pull to refresh text"), [dateFormatter stringFromDate:queryTime]];
        }
        else
        {
             self.secondLine = @"";
        }
    }
    else
    {
        self.secondLine = @"";
        self.navigationItem.prompt = nil;
    }
    
    DEBUG_LOG(@"Frame x=%f y=%f w=%f h=%f\n", self.table.frame.origin.x, self.table.frame.origin.y, self.table.frame.size.width, self.table.frame.size.height);
}


#pragma mark Refresh timer

- (void)setRefreshtextColor
{
    if (self.refreshText)
    {
        self.refreshText.textColor = self.navigationController.navigationBar.tintColor;
    }
}

- (void)setRefreshButtonText:(NSString*)text
{
    if (self.refreshText)
    {
        self.refreshText.text = text;
    }
    else
    {
        self.refreshButton.title = text;
    }
}

- (void)startTimer
{
	if ([UserPrefs getSingleton].autoRefresh)
	{
		self.lastRefresh = [NSDate date];
		NSDate *oneSecondFromNow = [NSDate dateWithTimeIntervalSinceNow:0];
		self.refreshTimer = [[[NSTimer alloc] initWithFireDate:oneSecondFromNow interval:1 target:self selector:@selector(countDownAction:) userInfo:nil repeats:YES] autorelease];
		[[NSRunLoop currentRunLoop] addTimer:self.refreshTimer forMode:NSDefaultRunLoopMode];
	}
}

-(void)stopTimer
{
	if (self.refreshTimer !=nil)
	{
		[self.refreshTimer invalidate];
		self.refreshTimer = nil;
        [self setRefreshButtonText:kRefreshText];
    }
}

- (void)didEnterBackground {
	if (self.refreshTimer !=nil)
	{
		[self.refreshTimer invalidate];
		self.refreshTimer = nil;
        _timerPaused = YES;
    }
}


- (void)didBecomeActive {
    DEBUG_LOG(@"didBecomeActive\n");
	if ([UserPrefs getSingleton].autoRefresh && _timerPaused)
	{
        DEBUG_LOG(@"restarting timer\n");
		self.refreshTimer = [[[NSTimer alloc] initWithFireDate:[NSDate date] interval:1 target:self selector:@selector(countDownAction:) userInfo:nil repeats:YES] autorelease];
		[[NSRunLoop currentRunLoop] addTimer:self.refreshTimer forMode:NSDefaultRunLoopMode];
        _timerPaused = NO;
	}
}

- (void) countDownAction:(NSTimer *)timer
{
	if (self.refreshTimer !=nil && self.refreshTimer)
	{
		NSTimeInterval sinceRefresh = [self.lastRefresh timeIntervalSinceNow];
        
        // If we detect that the app was backgrounded while this timer
        // was expiring we go around one more time - this is to enable a commuter
        // bookmark time to be processed.
        
        bool updateTimeOnButton = YES;
        if (sinceRefresh <= -kRefreshInterval)
		{
			[self refreshAction:timer];
			[self setRefreshButtonText: NSLocalizedString(@"Refreshing", @"Refresh button text")];
            updateTimeOnButton = NO;
		}
        
        if (updateTimeOnButton)
        {
            int secs = (1+kRefreshInterval+sinceRefresh);
            
            if (secs < 0) secs = 0;
            
            [self setRefreshButtonText:[NSString stringWithFormat:NSLocalizedString(@"Refresh in %d", @"Refresh button text {number of seconds}"), secs] ];
        }
	}
}

#pragma mark Section calculations

- (void)clearSections
{
	free(_sectionRows);
	_sectionRows= NULL;
}

-(SECTIONROWS *)calcSubsections:(NSInteger)section
{
	if (_sectionRows == NULL)
	{
		_sectionRows = malloc(sizeof(SECTIONROWS) * [self.visibleDataArray count]);
		
		for (NSInteger i=0; i< [self.visibleDataArray count]; i++)
		{
			_sectionRows[i].row[0] = kSectionRowInit;
		}
	}
	
	if (_sectionExpanded == nil)
	{
		_sectionExpanded = malloc(sizeof(bool) * self.originalDataArray.count);
		
		if (self.originalDataArray.count == 1)
		{
			_sectionExpanded[0] = YES;
		}
		else 
		{
			for (int i=0; i< self.originalDataArray.count; i++)
			{
				_sectionExpanded[i] = NO;
			}
		}	
	}
	
	SECTIONROWS *sr = _sectionRows + section;
#ifndef __clang_analyzer__
    // The analyiser can't tell that this is a static variable that is initialized once.
    
	if (sr->row[0] == kSectionRowInit)
	{
		bool expanded = !_blockSort && _sectionExpanded[section];
		id<DepartureTimesDataProvider> dd = [self departureData:section];
		
		int next = 0;
		
		// kSectionDistance
		if ([dd DTDataDistance] != nil)
		{
			next ++;
			
		}
		sr->row[kSectionDistance] = next;
		
		// kSectionTitle
		if ([dd DTDataGetSectionTitle] != nil)
		{
			next ++;
			
		}
		sr->row[kSectionTitle] = next;
		
		
		// kSectionTimes
		NSInteger itemCount = [dd DTDataGetSafeItemCount];
		
		if (itemCount==0)
		{
			itemCount = 1;
		}
		
		next += itemCount;
		sr->row[kSectionTimes] = next;
		
		// kSectionTrip
		if ([dd DTDataLocLat]!=nil && expanded)
		{
			next += kTripRows;
		}
		sr->row[kSectionTrip] = next;
		
		// kSectionFilter
		if (_blockFilter && expanded)
		{
			next ++;
		}
		sr->row[kSectionFilter] = next;
		
		// kSectionProximity
		if ([dd DTDataLocLat]!=nil && expanded && [AlarmTaskList proximitySupported])
		{
			next ++;
		}
		sr->row[kSectionProximity] = next;
		
		// kSectionNearby
		if ([dd DTDataLocLat]!=nil && depthCount < kMaxDepth && expanded)
		{
			next ++;
		}
		sr->row[kSectionNearby] = next;
		
		// kSectionOneStop
		if ([dd DTDataLocLat]!=nil && depthCount < kMaxDepth && expanded && self.visibleDataArray.count>1)
		{
			next ++;
		}
		sr->row[kSectionOneStop] = next;
        
        // kSectionOneStop
		if ([dd DTDataLocLat]!=nil && expanded)
		{
			next ++;
		}
		sr->row[kSectionMapOne] = next;
		
		
        // kSectionInfo
		if (expanded)
		{
			next ++;
		}
		sr->row[kSectionInfo] = next;
        
        
        
		// kSectionAccuracy
		if (expanded && [UserPrefs getSingleton].showTransitTracker)
		{
			next ++;
		}
        sr->row[kSectionAccuracy] = next;

        
        // kSectionXML
		if (expanded && [UserPrefs getSingleton].debugXML)
		{
			next ++;
		}
		sr->row[kSectionXML] = next;
		    
		// kSectionStatic
		next++;
		sr->row[kSectionStatic] = next;
		
		// final placeholder
		sr->row[kSectionsPerStop] = next;
		
		
	}
    
#endif
	return sr;
}

- (NSIndexPath *)subsection:(NSIndexPath*)indexPath;
{
	NSIndexPath *newIndexPath = nil;

#ifndef __clang_analyzer__
	int prevrow = 0;
	SECTIONROWS *sr = [self calcSubsections: (int)indexPath.section];
	
	for (int i=0; i < kSectionsPerStop; i++)
	{
		if (indexPath.row < sr->row[i])
		{
			newIndexPath = 
				[NSIndexPath 
					indexPathForRow:indexPath.row - prevrow
					inSection:i];
			break;
		}
		prevrow = sr->row[i];
	}
//	printf("Old %d %d new %d %d\n",(int)indexPath.section,(int)indexPath.row, (int)newIndexPath.section, (int)newIndexPath.row);
#endif
	return newIndexPath;
}

#pragma mark Data fetchers

- (void)fetchTimesForBlockVargs:(NSArray *)args;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	
	NSThread *thread = [NSThread currentThread];
	
	[self.backgroundTask.callbackWhenFetching backgroundThread:thread];
	
	NSString *block = [args objectAtIndex:0];
	NSString *start = [args objectAtIndex:1];
	NSString *stop =  [args objectAtIndex:2];
	
	[self.backgroundTask.callbackWhenFetching backgroundStart:2 title:kGettingArrivals];
	
	[self clearSections];
	[XMLDepartures clearCache];
	self.streetcarLocations = nil;
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	NSError *parseError = nil;	
	XMLDepartures *deps = [[ XMLDepartures alloc ] init];
	
	[self.originalDataArray addObject:deps];
	[deps setBlockFilter:block];
	[self.backgroundTask.callbackWhenFetching backgroundSubtext:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), start]];
	[deps getDeparturesForLocation:start parseError:&parseError];
	deps.sectionTitle = NSLocalizedString(@"Departure", @"");
	[deps release];
	[self.backgroundTask.callbackWhenFetching backgroundItemsDone:1];
	
	if(![thread isCancelled])
	{
		deps = [[ XMLDepartures alloc ] init];
	
		[self.originalDataArray addObject:deps];
		[deps setBlockFilter:block];
		[self.backgroundTask.callbackWhenFetching backgroundSubtext:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), stop]];
		[deps getDeparturesForLocation:stop parseError:&parseError];
		deps.sectionTitle = NSLocalizedString(@"Arrival", @"");
		[deps release];
		[self.backgroundTask.callbackWhenFetching backgroundItemsDone:2];
	}
	
	_blockFilter = true;
	self.title = NSLocalizedString(@"Trip", @"");
	
	[self sortByBus];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	
	[pool release];
}

- (void)fetchTimesForLocations:(NSArray*) stops
{
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSThread *thread = [NSThread currentThread];
	
	[self.backgroundTask.callbackWhenFetching backgroundThread:thread];

	
	[self clearSections];
	[XMLDepartures clearCache];
	self.streetcarLocations = nil;
	
	[self.backgroundTask.callbackWhenFetching backgroundStart:(int)[stops count] title:kGettingArrivals];
	
	
	NSMutableString * stopsstr = [[[NSMutableString alloc] init] autorelease];
	self.stops = stopsstr;
	int i;
	NSError *parseError = nil;	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	for (i=0; i< [stops count] && ![thread isCancelled]; i++)
	{
		XMLDepartures *deps = [[ XMLDepartures alloc ] init];
		StopDistance *sd = [stops objectAtIndex:i];
		
		[self.originalDataArray addObject:deps];
		[self.backgroundTask.callbackWhenFetching backgroundSubtext:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), sd.locid]];
		[deps getDeparturesForLocation:sd.locid parseError:&parseError];
		if (i==0)
		{
			[stopsstr appendFormat:@"%@",sd.locid];
		}
		else
		{
			[stopsstr appendFormat:@",%@",sd.locid];
		}
		deps.distance = sd;
		[deps release];
		
		
		[self.backgroundTask.callbackWhenFetching backgroundItemsDone:i+1];
	}
	
	if ([self.originalDataArray count] > 0)
	{	
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		
		_blockFilter = false;
		[self sortByBus];
	}
	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];	
	
	[pool release];
}

- (void)fetchTimesViaQrCodeRedirect:(NSString *)url
{
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [[url retain] autorelease];
	
	NSThread *thread = [NSThread currentThread];

	
	[self.backgroundTask.callbackWhenFetching backgroundThread:thread];
    
    [self.backgroundTask.callbackWhenFetching backgroundStart:2 title:kGettingArrivals];

    [self.backgroundTask.callbackWhenFetching backgroundSubtext:NSLocalizedString(@"getting stop ID", @"progress message")];
    
    
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    ProcessQRCodeString *qrCode = [[[ProcessQRCodeString alloc] init] autorelease];
    NSString *stopId = [qrCode extractStopId:url]; 
    
    [self.backgroundTask.callbackWhenFetching backgroundItemsDone:1];
    
    [self clearSections];
	[XMLDepartures clearCache];
	self.streetcarLocations = nil;
	self.stops = stopId;
	NSError *parseError = nil;	
	
    static NSString *streetcar = @"www.portlandstreetcar.org";
    
    if (!thread.isCancelled && stopId)
    {
        XMLDepartures *deps = [[ XMLDepartures alloc ] init];
		
        [self.originalDataArray addObject:deps];
        [self.backgroundTask.callbackWhenFetching backgroundSubtext:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), stopId]];
        [deps getDeparturesForLocation:stopId parseError:&parseError];
        [deps release];
        [self.backgroundTask.callbackWhenFetching backgroundItemsDone:2];
	}
    else if (url.length >= streetcar.length && [[url substringToIndex:streetcar.length] isEqualToString:streetcar])
    {
        [thread cancel];
        [self.backgroundTask.callbackWhenFetching backgroundSetErrorMsg:NSLocalizedString(@"That QR Code is for the Portland Streetcar web site - there should be another QR code close by that has the stop ID.",
                                                                                          @"error message")];
    }
    else
    {
        [thread cancel];
        [self.backgroundTask.callbackWhenFetching backgroundSetErrorMsg:NSLocalizedString(@"The QR Code is not for a TriMet stop.", @"error message")];
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		
    _blockFilter = false;
    [self sortByBus];
    [self.backgroundTask.callbackWhenFetching backgroundCompleted:self];	
	
	[pool release];
}



- (void)fetchTimesForNearestStops:(XMLLocateStops*) locator
{
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSThread *thread = [NSThread currentThread];
	
	[self.backgroundTask.callbackWhenFetching backgroundThread:thread];
	
	
	[self clearSections];
	[XMLDepartures clearCache];
	self.streetcarLocations = nil;
	
	
	
	[self.backgroundTask.callbackWhenFetching backgroundStart:locator.maxToFind+1 title:kGettingArrivals];
	
	[self.backgroundTask.callbackWhenFetching backgroundSubtext:NSLocalizedString(@"getting locations", @"progress message")];
	
	[locator findNearestStops];
	
	[self.backgroundTask.callbackWhenFetching backgroundItemsDone:1];
	
    AlertViewCancelsTask *canceller = [[[AlertViewCancelsTask alloc] init] autorelease];
	canceller.caller            = self;
    canceller.backgroundTask    = self.backgroundTask;
    
    
    if (![locator displayErrorIfNoneFound:self.backgroundTask.callbackWhenFetching])
	{
		NSMutableString * stopsstr = [[[NSMutableString alloc] init] autorelease];
		self.stops = stopsstr;
		int i;
		NSError *parseError = nil;	
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		for (i=0; i< [locator safeItemCount] && i<locator.maxToFind && ![thread isCancelled]; i++)
		{
			XMLDepartures *deps = [[ XMLDepartures alloc ] init];
			StopDistance *sd = [locator itemAtIndex:i];
			
			[self.originalDataArray addObject:deps];
			
			[self.backgroundTask.callbackWhenFetching backgroundSubtext:sd.desc];
			[deps getDeparturesForLocation:sd.locid parseError:&parseError];
			if (i==0)
			{
				[stopsstr appendFormat:@"%@",sd.locid];
			}
			else
			{
				[stopsstr appendFormat:@",%@",sd.locid];
			}
			deps.distance = sd;
			[deps release];
			
			
			[self.backgroundTask.callbackWhenFetching backgroundItemsDone:i+2];
		}
		
		if ([self.originalDataArray count] > 0)
		{	
			[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
			
			_blockFilter = false;
			[self sortByBus];
		}
	}
    
    [self.backgroundTask.callbackWhenFetching backgroundCompleted:self];

	
	[pool release];
}



- (void)fetchTimesForVehicleStops:(NSString*)block
{
    int items = 0;
    int pos  = 0;
    NSError *parseError = nil;
    bool found = false;
    bool done = false;
    
    while (items < MAX_STOPS && pos < self.vehicleStops.count && !done)
    {
        Stop * stop = [self.vehicleStops objectAtIndex:pos];
        XMLDepartures *deps = [[ XMLDepartures alloc ] init];
        
        
        [deps setBlockFilter:block];
        deps.firstOnly = YES;
        
        [self.backgroundTask.callbackWhenFetching backgroundSubtext:stop.desc];
        
        [self.backgroundTask.callbackWhenFetching backgroundItemsDone:items+1];
        
        [deps getDeparturesForLocation:stop.locid parseError:&parseError];
        
        if (deps.gotData && deps.safeItemCount > 0)
        {
            [self.originalDataArray addObject:deps];
            pos++;
            items++;
            found = YES;
        }
        else if (!found)
        {
            [self.vehicleStops removeObjectAtIndex:pos];
        }
        else
        {
            pos++;
            done = YES;
        }
    
    
        [deps release];
    }
}



- (void)fetchTimesForVehicle:(NSDictionary *)args
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSThread *thread = [NSThread currentThread];
	
	[self.backgroundTask.callbackWhenFetching backgroundThread:thread];
	
	
	NSString* loc		= [args objectForKey:kDictLocation];
	NSString* block		= [args objectForKey:kDictBlock];
	NSString* route    = [args objectForKey:kDictRoute];
	NSString* dir       = [args objectForKey:kDictDir];
	
	[self clearSections];
	[XMLDepartures clearCache];
	self.streetcarLocations = nil;
    
    // Get Route info
    XMLStops * stops = [[[XMLStops alloc] init] autorelease];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	NSError *parseError = nil;
    
    [self.backgroundTask.callbackWhenFetching backgroundStart:MAX_STOPS+1 title:NSLocalizedString(@"getting next stop IDs", @"progress message")];
    
    [stops getStopsAfterLocation:loc route:route direction:dir description:@"" parseError:&parseError cacheAction:TriMetXMLUpdateCache];
    
    [self.backgroundTask.callbackWhenFetching backgroundItemsDone:1];
    
    if ([stops gotData])
    {
        
         self.vehicleStops = stops.itemArray;
        
        [self fetchTimesForVehicleStops:block];
    }
	
    
    if (self.originalDataArray.count == 0)
    {
        [thread cancel];
        [self.backgroundTask.callbackWhenFetching backgroundSetErrorMsg:NSLocalizedString(@"Could not find any arrivals for that vehicle.", @"error message")];
    }
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	

    _blockFilter = true;
    self.blockSort = YES;
	
    [self sortByBus];
    
    self.allowSort = YES;
    
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	
	if (![thread isCancelled])
	{
		[_userData setLastArrivals:loc];
		
		NSMutableArray *names = [[[NSMutableArray alloc] init] autorelease];
		
		for (XMLDepartures *dep in self.originalDataArray)
		{
			if (dep.locDesc)
			{
				[names addObject:dep.locDesc];
			}
		}
		
		if (names.count == self.originalDataArray.count)
		{
			[_userData setLastNames:names];
		}
		else {
			[_userData setLastNames:nil];
		}
        
	}
	
	
	[pool release];
	
}



- (void)fetchTimesForNearestStopsWithArray:(NSArray*) stops
{
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSThread *thread = [NSThread currentThread];
	
	[self.backgroundTask.callbackWhenFetching backgroundThread:thread];
	
	
	[self clearSections];
	[XMLDepartures clearCache];
	self.streetcarLocations = nil;
	
	
	
	[self.backgroundTask.callbackWhenFetching backgroundStart:(int)[stops count] title:kGettingArrivals];
	
	NSMutableString * stopsstr = [[[NSMutableString alloc] init] autorelease];
	self.stops = stopsstr;
	int i;
	NSError *parseError = nil;	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

	for (i=0; i< [stops count] && ![thread isCancelled]; i++)
	{
		XMLDepartures *deps = [[ XMLDepartures alloc ] init];
		StopDistance *sd = [stops objectAtIndex:i];
			
		[self.originalDataArray addObject:deps];
			
		[self.backgroundTask.callbackWhenFetching backgroundSubtext:sd.desc];
		[deps getDeparturesForLocation:sd.locid parseError:&parseError];
		if (i==0)
		{
			[stopsstr appendFormat:@"%@",sd.locid];
		}
		else
		{
			[stopsstr appendFormat:@",%@",sd.locid];
		}
		deps.distance = sd;
		[deps release];
			
			
		[self.backgroundTask.callbackWhenFetching backgroundItemsDone:i+2];
	}
		
	if ([self.originalDataArray count] > 0)
	{	
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		
		_blockFilter = false;
		[self sortByBus];
	}
		
	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	
	[pool release];
}

- (void)fetchTimesForLocation:(NSDictionary *)args
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSThread *thread = [NSThread currentThread];
	
	[self.backgroundTask.callbackWhenFetching backgroundThread:thread];
	
	
	NSString* loc		= [args objectForKey:kDictLocation];
	NSString* block		= [args objectForKey:kDictBlock];
	NSArray*  names		= [args objectForKey:kDictNames];
	NSString* bookmark  = [args objectForKey:kDictBookmark];
	
	[self clearSections];
	[XMLDepartures clearCache];
	self.streetcarLocations = nil;
	
	self.stops = loc;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	NSError *parseError = nil;	
	
	NSScanner *scanner = [NSScanner scannerWithString:loc];
	NSCharacterSet *comma = [NSCharacterSet characterSetWithCharactersInString:@","];
	NSString *aLoc;
	
	int items = 0;
	
	while ([scanner scanUpToCharactersFromSet:comma intoString:&aLoc])
	{	
		items ++;
		
		if (![scanner isAtEnd])
		{
			scanner.scanLocation++;
		}
	} 
	
	[self.backgroundTask.callbackWhenFetching backgroundStart:items title:(bookmark!=nil?bookmark:kGettingArrivals)];
	
	
	[scanner setScanLocation:0];
	
	items = 1;
	
	while ([scanner scanUpToCharactersFromSet:comma intoString:&aLoc] && ![thread isCancelled])
	{	
		XMLDepartures *deps = [[ XMLDepartures alloc ] init];
		[self.originalDataArray addObject:deps];
		[deps setBlockFilter:block];
		
		if (names == nil || (items -1) > [names count])
		{
			[self.backgroundTask.callbackWhenFetching backgroundSubtext:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), aLoc]];
		}
		else {
			[self.backgroundTask.callbackWhenFetching backgroundSubtext:[names objectAtIndex:(items -1)]];
		}

	
		[deps getDeparturesForLocation:aLoc parseError:&parseError];
		
		if (![scanner isAtEnd])
		{
			scanner.scanLocation++;
		}
		[deps release];
		
		[self.backgroundTask.callbackWhenFetching backgroundItemsDone:items];
		items ++;
		
	}
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	if ([self.originalDataArray count] > 0)
	{	
		if (block!=nil)
		{
			self.title = NSLocalizedString(@"Track Trip", @"screen title");
			_blockFilter = true;
		}
		else
		{
			_blockFilter = false;
		}
		[self sortByBus];
		// [[(MainTableViewController *)[self.navigationController topViewController] tableView] reloadData];	
		// return YES;
	}
	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
	
	if (![thread isCancelled])
	{
		[_userData setLastArrivals:loc];	
		
		NSMutableArray *names = [[[NSMutableArray alloc] init] autorelease];
		
		for (XMLDepartures *dep in self.originalDataArray)
		{
			if (dep.locDesc)
			{
				[names addObject:dep.locDesc];
			}
		}
		
		if (names.count == self.originalDataArray.count)
		{
			[_userData setLastNames:names];
		}
		else {
			[_userData setLastNames:nil];
		}

	}
	
	
	[pool release];
	
}

- (void)fetchVehiclesAgain:(id)arg
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSThread *thread = [NSThread currentThread];
	
	[self.backgroundTask.callbackWhenFetching backgroundThread:thread];
	
	
	[self.backgroundTask.callbackWhenFetching backgroundStart:MAX_STOPS title:kGettingArrivals];
    
	[self clearSections];
    
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    
    XMLDepartures *dd = [self.originalDataArray objectAtIndex:0];
    NSString *block = dd.blockFilter;
	
    [self.originalDataArray removeAllObjects];
    
    [self fetchTimesForVehicleStops:block];
    
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    
    _blockFilter = true;
    self.blockSort = YES;
    self.allowSort = YES;
	
    [self sortByBus];
	[self clearSections];
	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:nil];
    
    
	[pool release];
}

- (void)fetchAgain:(id)arg
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int i=0;
	
	NSThread *thread = [NSThread currentThread];
	
	[self.backgroundTask.callbackWhenFetching backgroundThread:thread];
	
	
	[self.backgroundTask.callbackWhenFetching backgroundStart:(int)[self.originalDataArray count] title:kGettingArrivals];

	[self clearSections];

	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	for (i=0; i< [self.originalDataArray count] && ![thread isCancelled]; i++)
	{
		XMLDepartures *dd = [self.originalDataArray objectAtIndex:i];
		if (dd.locDesc !=nil)
		{
			[self.backgroundTask.callbackWhenFetching backgroundSubtext:dd.locDesc];
		}
		[dd reload];
		[self.backgroundTask.callbackWhenFetching backgroundItemsDone:i+1];
	}
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self sortByBus];
	[self clearSections];
	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:nil];
	 
	 
	[pool release];
}

- (void)fetchAgainInBackground:(id<BackgroundTaskProgress>)background 
{
	self.backgroundTask.callbackWhenFetching = background;
	
    if (self.vehicleStops)
    {
        [NSThread detachNewThreadSelector:@selector(fetchVehiclesAgain:) toTarget:self withObject:nil];
    }
    else
    {
        [NSThread detachNewThreadSelector:@selector(fetchAgain:) toTarget:self withObject:nil];
    }
}

- (void)fetchTimesForLocationInBackground:(id<BackgroundTaskProgress>)background loc:(NSString*)loc block:(NSString *)block
{
	self.backgroundTask.callbackWhenFetching = background;
	
	[NSThread detachNewThreadSelector:@selector(fetchTimesForLocation:) toTarget:self withObject:
			[NSDictionary dictionaryWithObjectsAndKeys:
									loc,	kDictLocation,
									block,	kDictBlock,
									nil]];
	
}

- (void)fetchTimesForVehicleInBackground:(id<BackgroundTaskProgress>)background route:(NSString *)route direction:(NSString *)direction nextLoc:(NSString*)loc block:(NSString *)block
{
    self.backgroundTask.callbackWhenFetching = background;
	
	[NSThread detachNewThreadSelector:@selector(fetchTimesForVehicle:) toTarget:self withObject:
     [NSDictionary dictionaryWithObjectsAndKeys:
      loc,      kDictLocation,
      block,	kDictBlock,
      direction,kDictDir,
      route,    kDictRoute,
      nil]];
}


- (void)fetchTimesForNearestStopsInBackground:(id<BackgroundTaskProgress>)background location:(CLLocation *)here maxToFind:(int)max minDistance:(double)min mode:(TripMode)mode
{
	self.backgroundTask.callbackWhenFetching = background;
	
	XMLLocateStops *locator = [[[XMLLocateStops alloc] init] autorelease];
	
	locator.maxToFind = max;
	locator.location = here;
	locator.mode = mode;
	locator.minDistance = min;
	
	[NSThread detachNewThreadSelector:@selector(fetchTimesForNearestStops:) toTarget:self withObject:locator];
	
}

- (void)fetchTimesForNearestStopsInBackground:(id<BackgroundTaskProgress>)background stops:(NSArray *)stops
{
	self.backgroundTask.callbackWhenFetching = background;
	[NSThread detachNewThreadSelector:@selector(fetchTimesForNearestStopsWithArray:) toTarget:self withObject:stops];
}

- (void)fetchTimesForLocationInBackground:(id<BackgroundTaskProgress>)background loc:(NSString*)loc names:(NSArray *)names
{
	self.backgroundTask.callbackWhenFetching = background;
	
	if (names !=nil)
	{
		[NSThread detachNewThreadSelector:@selector(fetchTimesForLocation:) 
								 toTarget:self 
							   withObject:
									[NSDictionary dictionaryWithObjectsAndKeys:
											loc,	kDictLocation,
											names,	kDictNames,
											nil]];
	}
	else {
		[NSThread detachNewThreadSelector:@selector(fetchTimesForLocation:) 
								 toTarget:self 
							   withObject:
									[NSDictionary dictionaryWithObjectsAndKeys:
											loc,	kDictLocation,
											nil]];
	}

}

- (void)fetchTimesForLocationInBackground:(id<BackgroundTaskProgress>)background loc:(NSString*)loc
{
	self.backgroundTask.callbackWhenFetching = background;
	
	[NSThread detachNewThreadSelector:@selector(fetchTimesForLocation:) 
							 toTarget:self 
						   withObject:
								[NSDictionary dictionaryWithObjectsAndKeys:
											loc,	kDictLocation,  nil]];
}

- (void)fetchTimesForLocationInBackground:(id<BackgroundTaskProgress>)background loc:(NSString*)loc title:(NSString *)title
{
	self.backgroundTask.callbackWhenFetching = background;
	
	[NSThread detachNewThreadSelector:@selector(fetchTimesForLocation:) 
							 toTarget:self 
						   withObject:
								[NSDictionary dictionaryWithObjectsAndKeys:
											loc,	kDictLocation,
											title,	kDictBookmark,  nil]];
}
- (void)fetchTimesForLocationsInBackground:(id<BackgroundTaskProgress>)background stops:(NSArray *) stops
{
	self.backgroundTask.callbackWhenFetching = background;
	
	[NSThread detachNewThreadSelector:@selector(fetchTimesForLocations:) toTarget:self withObject:stops];
	
}
- (void)fetchTimesForBlockInBackground:(id<BackgroundTaskProgress>)background block:(NSString*)block start:(NSString*)start stop:(NSString*) stop
{
	id args[] = { block, start, stop };
	
	self.backgroundTask.callbackWhenFetching = background;
	
	[NSThread detachNewThreadSelector:@selector(fetchTimesForBlockVargs:) toTarget:self withObject:
	  [NSArray arrayWithObjects:args count:sizeof(args)/sizeof(id)]];
}

- (void)fetchTimesViaQrCodeRedirectInBackground:(id<BackgroundTaskProgress>)background URL:(NSString*)url
{
    self.backgroundTask.callbackWhenFetching = background;
	
	[NSThread detachNewThreadSelector:@selector(fetchTimesViaQrCodeRedirect:) toTarget:self withObject:url];
    
}


- (void)fetchStreetcarLocations:(id)arg
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int i=0;
	
	NSSet *streetcarRoutes = [XMLStreetcarLocations getStreetcarRoutesInDepartureArray:self.originalDataArray];

	[self.backgroundTask.callbackWhenFetching backgroundStart:(int)streetcarRoutes.count title:NSLocalizedString(@"getting locations", @"progress message")];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    for (NSString *route in streetcarRoutes)
    {
        NSError *parseError = nil;
        XMLStreetcarLocations *loc = [XMLStreetcarLocations getSingletonForRoute:route];
        [loc getLocations:&parseError];
        [self.backgroundTask.callbackWhenFetching backgroundItemsDone:++i];
    }
    
    [XMLStreetcarLocations insertLocationsIntoDepartureArray:self.originalDataArray forRoutes:streetcarRoutes];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	[self.backgroundTask.callbackWhenFetching backgroundCompleted:nil];
	
	[pool release];
}




#pragma mark UI Helper functions

-(NSString *)formatDistance:(double)distance
{
	NSString *str = nil;
	if (distance < 500)
	{
		str = [NSString stringWithFormat:NSLocalizedString(@"%d ft (%d meters)", @"distance in <feet> then in <metres>"), (int)(distance * 3.2808398950131235),
			   (int)(distance) ];
	}
	else
	{
		str = [NSString stringWithFormat:NSLocalizedString(@"%.2f miles (%.2f km)", @"distance in <miles> then in <kilometres>"), (float)(distance / 1609.344),
			   (float)(distance / 1000) ];
	}	
	return str;
}


- (UITableViewCell *)distanceCellWithReuseIdentifier:(NSString *)identifier
{
	CGRect rect;
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
	
#define LEFT_COLUMN_OFFSET 10.0
#define LEFT_COLUMN_WIDTH 260
	
#define MAIN_FONT_SIZE 16.0
#define LABEL_HEIGHT 26.0
	
	/*
	 Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
	 */
	UILabel *label;
	
	rect = CGRectMake(LEFT_COLUMN_OFFSET, (kDepartureCellHeight/2.0 - LABEL_HEIGHT) / 2.0, LEFT_COLUMN_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = DISTANCE_TAG;
	label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
	label.adjustsFontSizeToFitWidth = YES;
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	label.textColor  = [UIColor blueColor];
	[label release];
	
	
	rect = CGRectMake(LEFT_COLUMN_OFFSET, kDepartureCellHeight/2.0 + (kDepartureCellHeight/2.0 - LABEL_HEIGHT) / 2.0, LEFT_COLUMN_WIDTH, LABEL_HEIGHT);
	label = [[UILabel alloc] initWithFrame:rect];
	label.tag = ACCURACY_TAG;
	label.font = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
	label.adjustsFontSizeToFitWidth = YES;
	[cell.contentView addSubview:label];
	label.highlightedTextColor = [UIColor whiteColor];
	label.textColor  = [UIColor blueColor];
	[label release];
	
	return cell;
}



#pragma mark UI Callback methods


- (void)detailsChanged
{
    _reloadWhenAppears = YES;
}

- (void)refresh {
    [self stopLoading];
    [self refreshAction:nil];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	id<DepartureTimesDataProvider> dd = [self departureData:self.actionItem.section];
	self.actionItem = nil;
	
	AlarmTaskList *taskList = [AlarmTaskList getSingleton];
	if ([taskList userAlertForProximityAction:(int)buttonIndex stopId:dd.DTDataLocID lat:dd.DTDataLocLat lng:dd.DTDataLocLng desc:dd.DTDataLocDesc])
	{
		[self reloadData];	
	}
}

- (void)refreshAction:(id)sender
{
    
	if ([self.table isHidden] || self.backgroundTask.progressModal !=nil)
	{
		return; 
	}
	
    DEBUG_LOG(@"Refreshing\n");
	self.backgroundRefresh = true;
	
	
	[self fetchAgainInBackground:self.backgroundTask];
	
	
	//	[[(MainTableViewController *)[self.navigationController topViewController] table] reloadData];	
}

-(void)showMapNow:(id)sender
{
	MapViewController *mapPage = [[MapViewController alloc] init];
	mapPage.callback = self.callback;
    
    if (_blockFilter || _singleMapItem!=nil)
    {
        mapPage.title = NSLocalizedString(@"Arrivals", @"screen title");
    }
    else
    {
        mapPage.title = NSLocalizedString(@"Stops", @"screen title");
    }
	
    long i,j;
    
    NSMutableSet *blocks = [[[NSMutableSet alloc] init] autorelease];
    
	for (i=[self.originalDataArray count]-1; i>=0 ; i--)
	{
		XMLDepartures * dep = [self.originalDataArray objectAtIndex:i];
        
        if (_singleMapItem!=nil && dep !=_singleMapItem)
        {
            continue;
        }
		
		if (dep.locLat !=nil)
		{
			[mapPage addPin:dep];
            
            if (_blockFilter || _singleMapItem!=nil)
            {
			
                for (j=0; j< [dep safeItemCount]; j++)
                {
                    Departure *dd = [dep itemAtIndex:j];
				
                    if (dd.hasBlock && ![blocks containsObject:dd.block])
                    {
                        [mapPage addPin:dd];
                        [blocks addObject:dd.block];
                    }
                }
            }
        }
	}
    _singleMapItem = nil;
	
	[[self navigationController] pushViewController:mapPage animated:YES];
	[mapPage release];
	
}

-(bool)needtoFetchStreetcarLocationsForStop:(XMLDepartures*)dep
{
    bool needToFetchStreetcarLocations = false;
    
    if (dep.locLat !=nil)
    {
        for (int j=0; j< [dep safeItemCount]; j++)
        {
            Departure *dd = [dep itemAtIndex:j];
            
            if (dd.streetcar && dd.blockPositionLat == nil)
            {
                needToFetchStreetcarLocations = true;
                break;
            }
        }
    }
    
    return needToFetchStreetcarLocations;
}

- (void)showMapFetchlocations:(bool)needToFetchStreetcarLocations
{
    if (needToFetchStreetcarLocations)
    {
        _fetchingLocations = YES;
        self.backgroundTask.callbackWhenFetching = self.backgroundTask;
        [NSThread detachNewThreadSelector:@selector(fetchStreetcarLocations:) toTarget:self withObject:nil];
    }
    else {
        [self showMapNow:nil];
    }

}

-(void)showMap:(id)sender
{
    _singleMapItem = nil;
    
    if ([self.originalDataArray count] > 1)
    {
        [self showMapNow:nil];
    }
    else
    {
        bool needToFetchStreetcarLocations = false;
	
        long i;
        for (i=[self.originalDataArray count]-1; i>=0 && !needToFetchStreetcarLocations ; i--)
        {
            needToFetchStreetcarLocations = [self needtoFetchStreetcarLocationsForStop:[self.originalDataArray objectAtIndex:i]];
        }
	
        [self showMapFetchlocations:needToFetchStreetcarLocations];
    }
}

- (void)showMapForOneStop:(XMLDepartures *)dep
{
    _singleMapItem = dep;
    [self showMapFetchlocations:[self needtoFetchStreetcarLocationsForStop:dep]];
}



-(void)sortButton:(id)sender
{
	DepartureSortTableView * options = [[ DepartureSortTableView alloc ] init];
	
	
	options.depView = self;
	
	[[self navigationController] pushViewController:options animated:YES];
	
	
	[options release];
	
	
}

-(void)bookmarkButton:(id)sender
{
	NSMutableString *loc =  [[[NSMutableString alloc] init] autorelease];
	NSMutableString *desc = [[[NSMutableString alloc] init] autorelease];
	int i;
	
	if ([self.originalDataArray count] == 1)
	{
		XMLDepartures *dd = [self.originalDataArray objectAtIndex:0];
		if ([self validStop:0])
		{
			[loc appendFormat:@"%@",dd.locid];
			[desc appendFormat:@"%@", dd.locDesc];
		}
		else
		{
			return;
		}
	}
	else
	{
		XMLDepartures *dd = [self.originalDataArray objectAtIndex:0];
		[loc appendFormat:@"%@", dd.locid];
		[desc appendFormat:NSLocalizedString(@"Stop IDs: %@", @"A list of TriMet stop IDs"), dd.locid];
		for (i=1; i< [self.originalDataArray count]; i++)
		{
			XMLDepartures *dd = [self.originalDataArray objectAtIndex:i];
			[loc appendFormat:@",%@",dd.locid];
			[desc appendFormat:@",%@",dd.locid];
		}
	}
	
	_bookmarkItem = kNoBookmark;
	
	@synchronized (_userData)
	{
		for (i=0; _userData.faves!=nil &&  i< _userData.faves.count; i++)
		{
			NSDictionary *bm = [_userData.faves objectAtIndex:i];
			NSString * faveLoc = (NSString *)[bm objectForKey:kUserFavesLocation];
			if (bm !=nil && faveLoc !=nil && [faveLoc isEqualToString:loc])
			{
				_bookmarkItem = i;
				desc = [bm objectForKey:kUserFavesChosenName];
				break;
			}
		}
	}
	
	self.bookmarkLoc  = loc;
	self.bookmarkDesc = desc;
	
	if (_bookmarkItem == kNoBookmark)
	{
		UIActionSheet *actionSheet = [[[ UIActionSheet alloc ] initWithTitle:NSLocalizedString(@"Bookmark", @"action list title")
                                                                    delegate:self
                                                           cancelButtonTitle:NSLocalizedString(@"Cancel", @"button text")
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:NSLocalizedString(@"Add new bookmark", @"button text"), nil] autorelease];
		actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
		[actionSheet showFromToolbar:self.navigationController.toolbar]; // show from our table view (pops up in the middle of the table)
	}
	else {
		UIActionSheet *actionSheet = [[[ UIActionSheet alloc ] initWithTitle:desc
                                                                    delegate:self
                                                           cancelButtonTitle:NSLocalizedString(@"Cancel", @"button text")
                                                      destructiveButtonTitle:NSLocalizedString(@"Delete this bookmark", @"button text")
                                                           otherButtonTitles:NSLocalizedString(@"Edit this bookmark", @"button text"),
																   NSLocalizedString(@"Add new bookmark", @"button text"), nil] autorelease];
		actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
		[actionSheet showFromToolbar:self.navigationController.toolbar]; // show from our table view (pops up in the middle of the table)
	}	
}

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (_bookmarkItem == kNoBookmark)
	{
		if (buttonIndex == 0)
		{
			EditBookMarkView *edit = [[EditBookMarkView alloc] init];
			[edit addBookMarkFromStop:self.bookmarkDesc location:self.bookmarkLoc];
			
			// Push the detail view controller
			[[self navigationController] pushViewController:edit animated:YES];
			[edit release];
		}
	}	
	else {
		switch (buttonIndex)
		{
			case 0:  // Delete this bookmark
			{
				@synchronized (_userData)
				{
					[_userData.faves removeObjectAtIndex:_bookmarkItem];
					_userData.favesChanged = YES;
					[_userData cacheAppData];
				}
				break;
			}
			case 1:  // Edit this bookmark
			{
				EditBookMarkView *edit = [[EditBookMarkView alloc] init];
				@synchronized (_userData)
				{
					[edit editBookMark:[_userData.faves objectAtIndex:_bookmarkItem] item:_bookmarkItem];
				}
				// Push the detail view controller
				[[self navigationController] pushViewController:edit animated:YES];
				[edit release];
				break;
				
			}
			case 2:  // Add new bookmark
			{
				EditBookMarkView *edit = [[EditBookMarkView alloc] init];
				[edit addBookMarkFromStop:self.bookmarkDesc location:self.bookmarkLoc];
				
				// Push the detail view controller
				[[self navigationController] pushViewController:edit animated:YES];
				[edit release];
				break;
			}
			case 3:  // Cancel
				break;
		}
	}

}



#pragma mark TableView methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result;
	id<DepartureTimesDataProvider> dd = [self departureData:indexPath.section];
	NSIndexPath *newIndexPath = [self subsection:indexPath];
	
	
	switch (newIndexPath.section)
	{
		case kSectionTimes:
			if ([dd DTDataGetSafeItemCount]==0 && newIndexPath.row == 0 && !_blockFilter )
			{
				result = kNonDepartureHeight;
			}
			else
			{
				if ((LargeScreenStyle([self screenWidth])) !=0)
				{
					result = kWideDepartureCellHeight;
				}
				else {
					result = kDepartureCellHeight;
				}
				
			}
			break;
		case kSectionStatic:
			return kDisclaimerCellHeight;
		case kSectionTitle:
			return [self narrowRowHeight];
		case kSectionNearby:
		case kSectionProximity:
		case kSectionTrip:
		case kSectionOneStop:
        case kSectionInfo:
        case kSectionMapOne:
			return [self narrowRowHeight];
		case kSectionAccuracy:
			return [self narrowRowHeight];
        case kSectionXML:
			return [self narrowRowHeight];
		case kSectionDistance:
			if ([dd DTDataDistance].accuracy > 0.0)
			{
				return kDepartureCellHeight;
			}
			else
			{
				return [self narrowRowHeight];
			}
		default:
			result = [self narrowRowHeight];
			break;
	}
	
	return result;
}



- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.visibleDataArray count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
#ifndef __clang_analyzer__
	SECTIONROWS *sr = [self calcSubsections:section];
	
	if ([self validStop:section])
	{
		id<DepartureTimesDataProvider> dd = [self departureData:section];
		[_userData addToRecentsWithLocation:[dd DTDataLocID] 
								description:[NSString stringWithFormat:@"%@ - %@", 
											 [dd DTDataLocDesc],
											 [dd DTDataDir]]];
	}
	
	DEBUG_LOG(@"Section: %ld rows %ld expanded %d\n", (long)section, (long)sr->row[kSectionsPerStop-1],
			  (int)_sectionExpanded[section]);

	
	return sr->row[kSectionsPerStop-1];
#endif
}



- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	id<DepartureTimesDataProvider> dd = [self departureData:section];
	return [dd DTDataGetSectionHeader];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell.reuseIdentifier isEqualToString:kActionCellId])
	{
		// cell.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        
        cell.backgroundColor = [self greyBackground];
	}
    else
    {
        [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
}




- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	
	id<DepartureTimesDataProvider> dd = [self departureData:indexPath.section];
	NSIndexPath * newIndexPath = [self subsection:indexPath];
	
	switch (newIndexPath.section)
	{
		case kSectionDistance:
		{
			bool twoLines = ([dd DTDataDistance].accuracy > 0.0);
			if (twoLines)
			{
				cell = [tableView dequeueReusableCellWithIdentifier:kDistanceCellId2];
				if (cell == nil) {
					cell = [self distanceCellWithReuseIdentifier:kDistanceCellId2];
				}
				
				NSString *distance = [NSString stringWithFormat:NSLocalizedString(@"Distance %@", @"stop distance"), [self formatDistance:[dd DTDataDistance].distance]];
				((UILabel*)[cell.contentView viewWithTag:DISTANCE_TAG]).text = distance;
				UILabel *accuracy = (UILabel*)[cell.contentView viewWithTag:ACCURACY_TAG];
				accuracy.text = [NSString stringWithFormat:NSLocalizedString(@"Accuracy +/- %@", @"accuracy of location services"), [self formatDistance:[dd DTDataDistance].accuracy]];
				[cell setAccessibilityLabel:[NSString stringWithFormat:@"%@, %@", distance, accuracy.text]];
				
			}
			else
			{
				cell = [tableView dequeueReusableCellWithIdentifier:kDistanceCellId];
				if (cell == nil) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDistanceCellId] autorelease];
				}
				
				cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Distance %@", @"stop distance"), [self formatDistance:[dd DTDataDistance].distance]];
				cell.textLabel.textColor = [UIColor blueColor];
				cell.textLabel.font = [self getBasicFont];;
				[cell setAccessibilityLabel:cell.textLabel.text];
				
			}
			cell.imageView.image = nil;
			break;
		}
		case kSectionTimes:
		// Configure the cell
		{
			int i = (int)newIndexPath.row;
			NSInteger deps = [dd DTDataGetSafeItemCount];
			if (deps ==0 && i == 0)
			{
				cell = [tableView dequeueReusableCellWithIdentifier:kStatusCellId];
				if (cell == nil) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kStatusCellId] autorelease];
				}
				if (_blockFilter)
				{
					cell.textLabel.text = NSLocalizedString(@"No arrival data for that particular trip.", @"error message");
					cell.textLabel.adjustsFontSizeToFitWidth = NO;
					cell.textLabel.numberOfLines = 0;
					cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
					cell.textLabel.font = [self getParagraphFont];
					
				}
				else
				{
					cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"(ID %@) No arrivals found.", @"No arrivals for a specific TriMet stop ID"), [dd DTDataLocID]];
					cell.textLabel.font = [self getBasicFont];

				}
				cell.accessoryType = UITableViewCellAccessoryNone;
				break;
			}
			else
			{
				Departure *departure = [dd DTDataGetDeparture:newIndexPath.row];
				NSString *cellId = [departure cellReuseIdentifier:kBigDepartureId width:[self screenWidth]];
				cell = [tableView dequeueReusableCellWithIdentifier:cellId];
				
				if (cell == nil) {
					cell = [departure bigTableviewCellWithReuseIdentifier:cellId width:[self screenWidth]];
				}
				[dd DTDataPopulateCell:departure cell:cell decorate:YES big:YES wide:LargeScreenStyle([self screenWidth])];
				// [departure populateCell:cell decorate:YES big:YES];
				
			}
			cell.imageView.image = nil;
			break;
		}
		case kSectionStatic:
			
			if (newIndexPath.row==0)
			{
				cell = [tableView dequeueReusableCellWithIdentifier:kDisclaimerCellId];
				if (cell == nil) {
					cell = [self disclaimerCellWithReuseIdentifier:kDisclaimerCellId];
				}
				
				if ([dd DTDataNetworkError])
				{
					if ([dd DTDataNetworkErrorMsg])
					{
						[self addTextToDisclaimerCell:cell 
												 text:kNetworkMsg];
					}
					else {
						[self addTextToDisclaimerCell:cell text:
						 [NSString stringWithFormat:kNoNetworkID, [dd DTDataLocID]]];
					}

				}	
				else if ([self validStop:indexPath.section])
				{
					NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
					[dateFormatter setDateStyle:kCFDateFormatterNoStyle];
					[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
					NSDate *queryTime = [NSDate dateWithTimeIntervalSince1970: TriMetToUnixTime([dd DTDataQueryTime])]; 
					[self addTextToDisclaimerCell:cell text:[NSString stringWithFormat:NSLocalizedString(@"%@ Updated: %@", @"text followed by time data was fetched"),
															 [dd DTDataStaticText],
															 [dateFormatter stringFromDate:queryTime]]];
				}
				
				
				if ([dd DTDataNetworkError])
				{
					cell.accessoryView = nil;
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				}
				else if ([dd DTDataHasDetails])
				{
					cell.accessoryView =  [[[ UIImageView alloc ] 
										   initWithImage: _sectionExpanded[indexPath.section] 
                                            ? [self alwaysGetIcon7:kIconCollapse7 old:kIconCollapse]
                                            : [self alwaysGetIcon7:kIconExpand7 old:kIconExpand]
										   ] autorelease];
					
					
					cell.accessoryType =  UITableViewCellAccessoryDisclosureIndicator;
					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				}
				else
				{
					cell.accessoryView = nil;
					cell.accessoryType = UITableViewCellAccessoryNone;
					cell.selectionStyle = UITableViewCellSelectionStyleNone;
				}
				
				// Check disclaimers
				Departure *dep = nil;
				NSString *streetcarDisclaimer = nil;
				
				for (int i=0; i< [dd DTDataGetSafeItemCount] && streetcarDisclaimer==nil; i++)
				{
					dep = [dd DTDataGetDeparture:i];
					
					if (dep.streetcar && dep.copyright !=nil)
					{
						streetcarDisclaimer = dep.copyright;
					}
				}
				
				[self addStreetcarTextToDisclaimerCell:cell text:streetcarDisclaimer trimetDisclaimer:YES];
				
				break;
			}
		case kSectionNearby:
			{
				cell = [tableView dequeueReusableCellWithIdentifier:kActionCellId];
				if (cell == nil) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kActionCellId] autorelease];
				}
				cell.textLabel.text = NSLocalizedString(@"Nearby stops", @"button text");
				cell.textLabel.textColor = [ UIColor darkGrayColor];
				cell.textLabel.font = [self getBasicFont]; 
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.imageView.image = [self getActionIcon7:kIconLocate7 old:kIconLocate];
			}
			break;
             
		case kSectionOneStop:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:kActionCellId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kActionCellId] autorelease];
			}
			
			cell.textLabel.text = NSLocalizedString(@"Show only this stop", @"button text");
			cell.textLabel.textColor = [ UIColor darkGrayColor];
			cell.textLabel.font = [self getBasicFont]; 
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.imageView.image = [self getActionIcon7:kIconLocate7 old:kIconLocate];
		}
		break;	
        case kSectionInfo:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:kActionCellId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kActionCellId] autorelease];
			}
			
			cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Stop ID %@ info", @"button text"), [dd DTDataLocID]];
			cell.textLabel.textColor = [ UIColor darkGrayColor];
			cell.textLabel.font = [self getBasicFont]; 
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.imageView.image = [self getActionIcon:kIconLink];
		}
            break;
        case kSectionMapOne:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:kActionCellId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kActionCellId] autorelease];
			}
			cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Show map of arrivals", @"button text")];
			cell.textLabel.textColor = [ UIColor darkGrayColor];
			cell.textLabel.font = [self getBasicFont];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.imageView.image = cell.imageView.image = [self getActionIcon7:kIconMapAction7 old:kIconMapAction];
		}
            break;
		case kSectionFilter:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:kActionCellId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kActionCellId] autorelease];
			}
			
			if (self.savedBlock)
			{
				cell.textLabel.text = NSLocalizedString(@"Show one arrival", @"button text");
			}
			else {
				cell.textLabel.text = NSLocalizedString(@"Show all arrivals", @"button text");
			}

			cell.textLabel.textColor = [ UIColor darkGrayColor];
			cell.textLabel.font = [self getBasicFont]; 
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.imageView.image = [self getActionIcon7:kIconLocate7 old:kIconLocate];
		}
			break;	
		case kSectionProximity:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:kActionCellId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kActionCellId] autorelease];
			}
			
			AlarmTaskList *taskList = [AlarmTaskList getSingleton];
			
			if ([taskList hasTaskForStopIdProximity:dd.DTDataLocID])
			{
				cell.textLabel.text = NSLocalizedString(@"Cancel proximity alarm", @"button text");
			}
			else 
			{
				cell.textLabel.text = kUserProximityCellText;
			}

			cell.textLabel.textColor = [ UIColor darkGrayColor];
			cell.textLabel.font = [self getBasicFont]; 
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.imageView.image = [self getActionIcon:kIconAlarm];
		}
		break;
		case kSectionTrip:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:kActionCellId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kActionCellId] autorelease];
			}
			
			if (newIndexPath.row == kTripRowFrom)
			{
				cell.textLabel.text = NSLocalizedString(@"Plan trip from here", @"button text");
			}
			else
			{
				cell.textLabel.text = NSLocalizedString(@"Plan trip to here", @"button text");
			}
			cell.textLabel.textColor = [ UIColor darkGrayColor];
			cell.textLabel.font = [self getBasicFont]; 
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.imageView.image = [self getActionIcon:kIconTripPlanner];
		}
			break;	
		case kSectionTitle:
			{
				cell = [tableView dequeueReusableCellWithIdentifier:kTitleCellId];
				if (cell == nil) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kActionCellId] autorelease];
				}
				
				cell.textLabel.text = [dd DTDataGetSectionTitle];
				cell.textLabel.textColor = [ UIColor darkGrayColor];
				cell.textLabel.font = [self getBasicFont]; 
				cell.accessoryType = UITableViewCellAccessoryNone;
				cell.imageView.image = nil;
			}
			break;		
		case kSectionAccuracy:
			{
				cell = [tableView dequeueReusableCellWithIdentifier:kTitleCellId];
				if (cell == nil) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kActionCellId] autorelease];
				}
				
				cell.textLabel.text = NSLocalizedString(@"Check TriMet web site", @"button text");
				cell.textLabel.textColor = [ UIColor darkGrayColor];
				cell.textLabel.font = [self getBasicFont]; 
				cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
				cell.imageView.image = [self getActionIcon:kIconLink];
			}
			break;
        case kSectionXML:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kTitleCellId];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kActionCellId] autorelease];
            }
            
            cell.textLabel.text = NSLocalizedString(@"Show raw XML data", @"button text");
            cell.textLabel.textColor = [ UIColor darkGrayColor];
            cell.textLabel.font = [self getBasicFont]; 
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [self getActionIcon:kIconXml];
            break;
        }
    }
	[self maybeAddSectionToAccessibility:cell indexPath:indexPath alwaysSaySection:NO];
	return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	return [self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	id<DepartureTimesDataProvider> dd = [self departureData:indexPath.section];
	NSIndexPath *newIndexPath = [self subsection:indexPath];
	
	switch (newIndexPath.section)
	{
		case kSectionTimes:
		{
			if ([dd DTDataGetSafeItemCount]!=0 && newIndexPath.row < [dd DTDataGetSafeItemCount])
			{
				Departure *departure = [dd DTDataGetDeparture:newIndexPath.row];
		
				// if (departure.hasBlock || departure.detour)
				{
					DepartureDetailView *departureDetailView = [[DepartureDetailView alloc] init];
					departureDetailView.callback = self.callback;
                    departureDetailView.delegate = self;
                    
                    departureDetailView.navigationItem.prompt = self.navigationItem.prompt;
					
					if (depthCount < kMaxDepth && [self.visibleDataArray count] > 1)
					{
						departureDetailView.stops = self.stops;
					}
					
					[departureDetailView fetchDepartureInBackground:self.backgroundTask dep:departure allDepartures:self.originalDataArray
                                                   allowDestination:((!_blockFilter) || [UserPrefs getSingleton].vehicleLocations) && depthCount < kMaxDepth];
					
					[departureDetailView release];	
				}
			}
			break;
		}
		case kSectionTrip:
		{
			TripPlannerSummaryView *tripPlanner = [[[TripPlannerSummaryView alloc] init] autorelease];
			
			@synchronized (_userData)
			{
				[tripPlanner.tripQuery addStopsFromUserFaves:_userData.faves];
			}
			
			// Push the detail view controller
		
			TripEndPoint *endpoint = nil;
			
			if (newIndexPath.row == kTripRowFrom)
			{
				endpoint = tripPlanner.tripQuery.userRequest.fromPoint;
			}
			else 
			{
				endpoint = tripPlanner.tripQuery.userRequest.toPoint;
			}

			
			endpoint.useCurrentLocation = false;
			endpoint.additionalInfo     = [dd DTDataLocDesc];
			endpoint.locationDesc       = [dd DTDataLocID];
			
			
			[[self navigationController] pushViewController:tripPlanner animated:YES];
			break;
		}
		case kSectionProximity:
		{
			AlarmTaskList *taskList = [AlarmTaskList getSingleton];
			
			if ([taskList hasTaskForStopIdProximity:dd.DTDataLocID])
			{
				[taskList cancelTaskForStopIdProximity:dd.DTDataLocID];
			}
			else 
			{
				self.actionItem = indexPath;
				[taskList userAlertForProximity:self];
			}
			[self reloadData];
			break;
		}
		case kSectionNearby:
		{
			
			CLLocation *here = [[[CLLocation alloc] initWithLatitude:[[dd DTDataLocLat] doubleValue] longitude:[[dd DTDataLocLng] doubleValue]] autorelease];
            
            FindByLocationView *find = [[FindByLocationView alloc] initWithLocation:here description:[dd DTDataLocDesc]];

			[[self navigationController] pushViewController:find animated:YES];
            
			[find release];

			/*
			else
			{
				UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Nearby stops"
																   message:@"No stops were found"
																  delegate:nil
														 cancelButtonTitle:@"OK"
														 otherButtonTitles:nil] autorelease];
				[alert show];
				
			}
			*/
			break;
		}
        case kSectionInfo:
		{
			NSString *url = [NSString stringWithFormat:@"http://trimet.org/go/cgi-bin/cstops.pl?action=entry&resptype=U&lang=pdaen&noCat=Landmark&Loc=%@",
							 [dd DTDataLocID]];
			WebViewController *webPage = [[WebViewController alloc] init];
			[webPage setURLmobile:url full:url];
			webPage.showErrors = NO;
			[webPage displayPage:[self navigationController] animated:YES itemToDeselect:self];
			[webPage release];
			break;
		}
            
        case kSectionMapOne:
		{
			[self showMapForOneStop:[dd DTDataXML ]];
			break;
		}
		case kSectionAccuracy:
		{
			NSString *url = [NSString stringWithFormat:@"http://trimet.org/arrivals/small/tracker?locationID=%@",
							 [dd DTDataLocID]];
			WebViewController *webPage = [[WebViewController alloc] init];
			[webPage setURLmobile:url full:url]; 
			webPage.showErrors = NO;
			[webPage displayPage:[self navigationController] animated:YES itemToDeselect:self];
			[webPage release];
			break;
		}
        case kSectionXML:
		{
            XMLDepartures *dep = [dd DTDataXML];
            
            if (dep && dep.rawData)
            {
                self.xmlButton = nil;
                [self xmlAction:[self.table cellForRowAtIndexPath:indexPath].imageView];
            }
            [self.table deselectRowAtIndexPath:indexPath animated:YES];
           
            break;
        }
		case kSectionOneStop:
		{
			DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
			
			departureViewController.callback = self.callback;
			[departureViewController fetchTimesForLocationInBackground:self.backgroundTask 
																   loc:[dd DTDataLocID]
																 title:[dd DTDataLocDesc]];
			[departureViewController release];
			break;
		}
		case kSectionFilter:
		{
			
			if ([dd respondsToSelector:@selector(DTDataXML)])
			{
				XMLDepartures *dep = (XMLDepartures*)[dd DTDataXML];
					
				if (self.savedBlock)
				{
					dep.blockFilter = self.savedBlock;
					self.savedBlock = nil;
				}
				else 
				{
					self.savedBlock = dep.blockFilter;
					dep.blockFilter = nil;
				}
				[self refreshAction:nil];
			}
			
			[self.table deselectRowAtIndexPath:indexPath animated:YES];
			break;
		}
		case kSectionStatic:
		{
			if ([dd DTDataNetworkError])
			{
				[self networkTips:[dd DTDataHtmlError] networkError:[dd DTDataNetworkErrorMsg]];
                [self clearSelection];
				
			} else if (!_blockSort)
			{
				int sect = (int)indexPath.section;
				[self.table deselectRowAtIndexPath:indexPath animated:YES];
				_sectionExpanded[sect] = _sectionExpanded[sect] ? false : true;
			
				
				// copy this struct
				SECTIONROWS oldRows = *(_sectionRows + sect);
				
				SECTIONROWS *newRows = _sectionRows + sect;
				
				newRows->row[0] = kSectionRowInit;
				
				[self calcSubsections:sect];
				
				NSMutableArray *changingRows = [[[NSMutableArray alloc] init] autorelease];
				
				int row;
				
				SECTIONROWS *additionalRows;
				
				if (_sectionExpanded[sect])
				{
					additionalRows = newRows;
				}
				else 
				{
					additionalRows = &oldRows;
				}

				
			    for (int i=0; i< kSectionsPerStop; i++)
				{
					DEBUG_LOG(@"index %d\n",i);
					DEBUG_LOG(@"row %d\n", newRows->row[i+1]-newRows->row[i]);
					DEBUG_LOG(@"old row %d\n", oldRows.row[i+1]-oldRows.row[i]);
					
					if (newRows->row[i+1]-newRows->row[i] != oldRows.row[i+1]-oldRows.row[i])
					{
						
						for (row = additionalRows->row[i]; row < additionalRows->row[i+1]; row++)
						{
							[changingRows addObject:[NSIndexPath indexPathForRow:row
																	   inSection:sect]];
						}
					}
				}
				
				
				UITableViewCell *staticCell = [self.table cellForRowAtIndexPath:indexPath];
				
				if (staticCell != nil)
				{
					staticCell.accessoryView =  [[ UIImageView alloc ] 
									   initWithImage: _sectionExpanded[sect] 
                                                 ? [self alwaysGetIcon7:kIconCollapse7  old:kIconCollapse]
                                                 : [self alwaysGetIcon7:kIconExpand7    old:kIconCollapse]
									   ];
					[staticCell setNeedsDisplay];
				}
			
				[self.table beginUpdates];	
				
				
				if (_sectionExpanded[sect])
				{
					[self.table insertRowsAtIndexPaths:changingRows withRowAnimation:UITableViewRowAnimationRight];
				}
				else 
				{
					[self.table deleteRowsAtIndexPaths:changingRows withRowAnimation:UITableViewRowAnimationRight];
					
				
				}
				
				
				
				DEBUG_LOG(@"reloadRowsAtIndexPaths %d %d\n", newRows->row[kSectionStatic], sect);
				
				
				
				[self.table endUpdates];
//[self reloadData];

			}
				
				
			/*	
				if ([self.visibleDataArray count] > 1 && depthCount < kMaxDepth && [dd DTDataHasDetails])
			{
				DepartureTimesView *departureViewController = [[DepartureTimesView alloc] init];
				
				departureViewController.callback = self.callback;
				[departureViewController fetchTimesForLocationInBackground:self.backgroundTask loc:[dd DTDataLocID]];
				[departureViewController release];
			}
			 */
			
		}
	}
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (editingStyle == UITableViewCellEditingStyleDelete) {
	}
	if (editingStyle == UITableViewCellEditingStyleInsert) {
	}
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}



#pragma mark View methods



- (void)viewDidLoad {
	[super viewDidLoad];
	// add our custom refresh button as the nav bar's custom right view
    // The custom button here is to stop the button from flashing each time
    // the text is updated in iOS7.
    
    if ([AlignedBarItemButton iOS7])
    {
        CGRect buttonRect = CGRectMake(0,0, 110, 30);
    
        self.refreshText = [[[UILabel alloc] initWithFrame:buttonRect] autorelease];
        self.refreshText.backgroundColor = [UIColor clearColor];
        self.refreshText.textAlignment = UITextAlignmentRight;
    
        UIButton *button = [AlignedBarItemButton suitableButtonRight:YES];
    
        [button addTarget:self action:@selector(refreshAction:)forControlEvents:UIControlEventTouchUpInside];
        [button addSubview:self.refreshText];
        button.frame = buttonRect;

        self.refreshButton = [[[UIBarButtonItem alloc] initWithCustomView:button] autorelease];
        
        [self setRefreshtextColor];
        
    }
    else
    {
        self.refreshButton = [[UIBarButtonItem alloc] initWithTitle:kRefreshText style:UIBarButtonItemStylePlain target:self action:@selector(refreshAction:)];
    }
    
    self.navigationItem.rightBarButtonItem = self.refreshButton;
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	//Configure and enable the accelerometer
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChangeInUserSettings:) name:NSUserDefaultsDidChangeNotification object:nil];
	
	[self startTimer];
    
    [self cacheWarningRefresh:NO];
}

- (void) viewWillDisappear:(BOOL)animated
{
    DEBUG_LOG(@"DepartureTimesView:viewWillDisappear\n");
    
    // [UIView setAnimationsEnabled:NO];
    self.navigationItem.prompt = nil;
    // [UIView setAnimationsEnabled:YES];
    
    [super viewWillDisappear:animated];
}

- (void) viewDidDisappear:(BOOL)animated
{
    DEBUG_LOG(@"DepartureTimesView:viewDidDisappear\n");
    [super viewDidDisappear:animated];
    
	[self stopTimer];
    DEBUG_LOG(@"viewDidDisappear\n");
    
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}





#pragma mark TableViewWithToolbar methods

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
	// match each of the toolbar item's style match the selection in the "UIBarButtonItemStyle" segmented control
	UIBarButtonItemStyle style = UIBarButtonItemStylePlain;
	
	// create the system-defined "OK or Done" button
    UIBarButtonItem *bookmark = [[UIBarButtonItem alloc]
                                 initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                                 target:self action:@selector(bookmarkButton:)];
	bookmark.style = style;
	
	
    
	[toolbarItems addObject:bookmark];
    [toolbarItems addObject:[CustomToolbar autoFlexSpace]];
    
    if (((!(_blockFilter || [self.originalDataArray count] == 1)) || _allowSort) && ([UserPrefs getSingleton].groupByArrivalsIcon))
    {
        UIBarButtonItem *sort = [[[UIBarButtonItem alloc]
                                  // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                                  initWithImage:[TableViewWithToolbar getToolbarIcon7:kIconSort7 old:kIconSort]
                                  style:UIBarButtonItemStylePlain
                                  target:self action:@selector(sortButton:)] autorelease];
        
        sort.accessibilityLabel = NSLocalizedString(@"Group Arrivals", @"Accessibility text");
        
        [toolbarItems addObject:sort];;
        [toolbarItems addObject:[CustomToolbar autoFlexSpace]];
        
    }
    
    [toolbarItems addObject:[CustomToolbar autoMapButtonWithTarget:self action:@selector(showMap:)]];
    
    if ([UserPrefs getSingleton].ticketAppIcon)
    {
        [toolbarItems addObject:[CustomToolbar autoFlexSpace]];
        [toolbarItems addObject:[self autoTicketAppButton]];
    }
    
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
    
	[bookmark release];
}

#pragma mark Accelerometer methods

-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self becomeFirstResponder];
    
    if (_reloadWhenAppears)
    {
        _reloadWhenAppears = NO;
        [self reloadData];
    }
    
    [self iOS7workaroundPromptGap];
}


- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	if ([UserPrefs getSingleton].shakeToRefresh && event.type == UIEventSubtypeMotionShake) {
		UIViewController * top = [[self navigationController] visibleViewController];
		
		if ([top respondsToSelector:@selector(refreshAction:)])
		{
			[top performSelector:@selector(refreshAction:) withObject:nil];
		}
	}
}

- (void) handleChangeInUserSettings:(id)obj
{
	[self reloadData];
	[self stopTimer];
	[self startTimer];
}

#pragma mark BackgroundTask methods

-(void)BackgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled
{
		
	if (self.backgroundRefresh && !cancelled)
	{
		[self startTimer];
	}	
	
	if (_fetchingLocations)
	{
		[self showMapNow:nil];
		_fetchingLocations = false;
	}
	else
	{
		[super BackgroundTaskDone:viewController cancelled:cancelled];
	}

}

-(void)backgroundTaskStarted
{
	[self stopTimer];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self reloadData];
}

- (void)reloadData
{
    [super reloadData];
    
    [self setRefreshtextColor];
    
    [self cacheWarningRefresh:YES];
    
}

- (void)appendXmlData:(NSMutableData *)buffer
{
    id<DepartureTimesDataProvider> dd = [self departureData:[self.table.indexPathForSelectedRow section]];
    XMLDepartures *dep = [dd DTDataXML];
    
    [dep appendQueryAndData:buffer];
    
    if (dep.streetcarData)
    {
        [buffer appendData:dep.streetcarData];
    }
}

@end

