//
//  DepartureTimesView.m
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DepartureTimesView.h"
#import "DepartureData+iOSUI.h"
#import "XMLDepartures.h"
#import "DepartureDetailView.h"
#import "EditBookMarkView.h"
#import "WebViewController.h"
#import "StopDistanceData.h"

#import "MapViewController.h"
#import "SimpleAnnotation.h"
#import "DepartureTimesByBus.h"
#import "DepartureSortTableView.h"
#import "UserFaves.h"
#import "XMLLocateStops+iOSUI.h"
#import "AlarmTaskList.h"
#import "TripPlannerSummaryView.h"
#import "ProcessQRCodeString.h"
#import "DebugLogging.h"
#import "XMLStops.h"
#import "FindByLocationView.h"
#import "XMLDepartures+iOSUI.h"
#import "AlarmAccurateStopProximity.h"
#import "FormatDistance.h"
#import "XMLRoutes.h"
#import "XMLStops.h"
#import "StringHelper.h"
#import "LocationAuthorization.h"
#import "AllRailStationView.h"
#import "RailStationTableView.h"


#define kSectionDistance	0
#define kSectionTitle		1
#define kSectionTimes		2
#define kSectionTrip		3
#define kSectionFilter		4
#define kSectionProximity	5
#define kSectionNearby		6
#define kSectionOneStop		7
#define kSectionMapOne      8
#define kSectionOpposite    9
#define kSectionNoDeeper    10
#define kSectionStation		11
#define kSectionInfo        12
#define kSectionAccuracy	13
#define kSectionXML         14
#define kSectionStatic		15
#define kSectionsPerStop	16



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
@synthesize blockSort			= _blockSort;
@synthesize streetcarLocations	= _streetcarLocations;
@synthesize actionItem			= _actionItem;
@synthesize savedBlock			= _savedBlock;
@synthesize allowSort           = _allowSort;
@synthesize userActivity        = _userActivity;
@synthesize sectionRows         = _sectionRows;
@synthesize sectionExpanded     = _sectionExpanded;


#define kNonDepartureHeight 35.0



#define MAX_STOPS 8

- (void)dealloc {
 	self.displayName			= nil;
	self.visibleDataArray		= nil;
	self.locationsDb			= nil;
	self.originalDataArray		= nil;
	self.streetcarLocations		= nil;

	depthCount--;
    DEBUG_LOGL(depthCount);
	self.stops = nil;
    self.bookmarkLoc			= nil;
	self.bookmarkDesc			= nil;
	self.actionItem				= nil;
	self.savedBlock				= nil;
    self.vehicleStops           = nil;
    
    if (self.userActivity)
    {
        [self.userActivity invalidate];
        self.userActivity = nil;
    }
    self.sectionExpanded        = nil;
    
	
	[self clearSections];
	[super dealloc];
}


- (instancetype)init {
	if ((self = [super init]))
	{
        self.title = NSLocalizedString(@"Arrivals", @"page title");
        self.originalDataArray = [NSMutableArray array];
		[self sortByStop];
		self.locationsDb = [StopLocations getDatabase];
        DEBUG_LOGL(depthCount);
		depthCount++;
        _updatedWatch = NO;
	}
	return self;
}

- (CGFloat) heightOffset
{
    return -[UIApplication sharedApplication].statusBarFrame.size.height;
}

#pragma mark Data sorting and manipulation


- (bool)validStop:(unsigned long) i
{
	id<DepartureTimesDataProvider> dd = self.visibleDataArray[i];
	return (dd.DTDataGetSectionHeader!=nil
			&&	(dd.DTDataGetSafeItemCount == 0
				 ||  (dd.DTDataGetSafeItemCount > 0 && [dd DTDataGetDeparture:0].errorMessage==nil)));
}

- (void)sortByStop
{
    NSMutableArray *uiArray = [NSMutableArray array];
    
    for (XMLDepartures *dd in self.originalDataArray)
    {
        [uiArray addObject:dd];
    }
    
    self.visibleDataArray = uiArray;
}

- (void)sortByBus
{
	if (self.originalDataArray.count == 0)
	{
		return;
	}
	
	if (!self.blockSort)
	{
        [self sortByStop];
		return;
	}
	
    self.visibleDataArray = [NSMutableArray array];
	
	int stop;
	int bus;
	int search;
	int insert;
	BOOL found;
	DepartureData *itemToInsert;
	DepartureData *firstItemForBus;
	DepartureData *existingItem;
	DepartureTimesByBus *busRoute;
	XMLDepartures *dep;
	
	for (stop = 0; stop < self.originalDataArray.count; stop++)
	{
		dep = self.originalDataArray[stop];
		for (bus = 0; bus < dep.count; bus++)
		{
			itemToInsert = dep[bus];
			found = NO;
			for (search = 0; search < self.visibleDataArray.count; search ++)
			{
				busRoute = self.visibleDataArray[search];
				firstItemForBus = [busRoute DTDataGetDeparture:0];
				
				if (itemToInsert.block !=nil && [firstItemForBus.block isEqualToString:itemToInsert.block])
				{
					for (insert = 0; insert < busRoute.departureItems.count; insert++)
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
				DepartureTimesByBus * newBus = [DepartureTimesByBus alloc].init;
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
        [self sortByStop];
	}
	
	[self clearSections];
	
	[self reloadData];
}

#pragma Cache warning

- (void)cacheWarningRefresh:(bool)refresh
{
    DEBUG_LOGB(refresh);

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
        
        XMLDepartures *item0 = self.originalDataArray.firstObject;
        
        if (item0 && [item0 DTDataQueryTime] > 0)
        {
            self.secondLine = [NSString stringWithFormat:NSLocalizedString(@"Last updated: %@", @"pull to refresh text"),
                               [NSDateFormatter localizedStringFromDate:TriMetToNSDate([item0 DTDataQueryTime])
                                                              dateStyle:NSDateFormatterNoStyle
                                                              timeStyle:NSDateFormatterMediumStyle]];
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
    
    DEBUG_LOGR(self.table.frame);
}


#pragma mark Section calculations

- (void)clearSections
{
    self.sectionRows = nil;
}

-(SECTIONROWS *)calcSubsections:(NSInteger)section
{
	if (self.sectionRows == NULL)
	{
        self.sectionRows = [NSMutableArray array];
		
		for (NSInteger i=0; i< self.visibleDataArray.count; i++)
		{
            self.sectionRows[i] = [NSMutableArray array];
			self.sectionRows[i][0] = @(kSectionRowInit);
		}
	}
	
	if (self.sectionExpanded == nil)
	{
        self.sectionExpanded = [NSMutableArray array];
		
		if (self.originalDataArray.count == 1)
		{
			self.sectionExpanded[0] = @YES;
		}
		else 
		{
			for (int i=0; i< self.originalDataArray.count; i++)
			{
				self.sectionExpanded[i] = @NO;
			}
		}	
	}
	
    SECTIONROWS *sr = self.sectionRows[section];
    
	if (sr[0].integerValue == kSectionRowInit)
	{
		bool expanded = !_blockSort && self.sectionExpanded[section].boolValue;
		id<DepartureTimesDataProvider> dd = self.visibleDataArray[section];
		
		int next = 0;
		
		// kSectionDistance
		if (dd.DTDataDistance != nil)
		{
			next++;
		}
		sr[kSectionDistance] = @(next);
		
		// kSectionTitle
		if (dd.DTDataGetSectionTitle != nil)
		{
			next++;
		}
		sr[kSectionTitle] = @(next);
		
		
		// kSectionTimes
		NSInteger itemCount = dd.DTDataGetSafeItemCount;
		
		if (itemCount==0)
		{
			itemCount = 1;
		}
		
		next += itemCount;
		sr[kSectionTimes] = @(next);
		
		// kSectionTrip
		if (dd.DTDataLoc!=nil && expanded)
		{
			next += kTripRows;
		}
		sr[kSectionTrip] = @(next);
		
		// kSectionFilter
		if (_blockFilter && expanded)
		{
			next++;
		}
		sr[kSectionFilter] = @(next);
		
		// kSectionProximity
		if (dd.DTDataLoc!=nil && expanded && [AlarmTaskList proximitySupported])
		{
			next++;
		}
		sr[kSectionProximity] = @(next);
		
		// kSectionNearby
		if (dd.DTDataLoc!=nil && depthCount < kMaxDepth && expanded)
		{
			next++;
		}
		sr[kSectionNearby] = @(next);
		
		// kSectionOneStop
		if (dd.DTDataLoc!=nil && depthCount < kMaxDepth && expanded && self.visibleDataArray.count>1)
		{
			next++;
		}
		sr[kSectionOneStop] = @(next);
        
        // kSectionOneStop
		if (dd.DTDataLoc!=nil && expanded)
		{
			next++;
		}
		sr[kSectionMapOne] = @(next);
        
        // kSectionOneOpposite
        if (dd.DTDataLoc!=nil && expanded && [DepartureTimesView canGoDeeper])
        {
            next++;
        }
        sr[kSectionOpposite] = @(next);
        
        // kSectionOneOpposite
        if (expanded && ![DepartureTimesView canGoDeeper])
        {
            next++;
        }
        sr[kSectionNoDeeper] = @(next);
		
        
        // kSectionStation
        if (expanded && dd.DTDataLocID!=nil && [AllRailStationView railstationFromStopId:dd.DTDataLocID]!=nil && [DepartureTimesView canGoDeeper])
        {
            next++;
        }
        sr[kSectionStation] = @(next);
		
        // kSectionInfo
		if (expanded)
		{
			next++;
		}
		sr[kSectionInfo] = @(next);
        
        
        
		// kSectionAccuracy
		if (expanded && [UserPrefs sharedInstance].showTransitTracker)
		{
			next++;
		}
        sr[kSectionAccuracy] = @(next);

        
        // kSectionXML
		if (expanded && [UserPrefs sharedInstance].debugXML)
		{
			next++;
		}
		sr[kSectionXML] = @(next);
		    
		// kSectionStatic
		next++;
		sr[kSectionStatic] = @(next);
		
		// final placeholder
		sr[kSectionsPerStop] = @(next);
	}
	return sr;
}

- (NSIndexPath *)subsection:(NSIndexPath*)indexPath;
{
	NSIndexPath *newIndexPath = nil;

	int prevrow = 0;
	SECTIONROWS *sr = [self calcSubsections: indexPath.section];
	
	for (int i=0; i < kSectionsPerStop; i++)
	{
		if (indexPath.row < sr[i].integerValue)
		{
			newIndexPath = 
				[NSIndexPath 
					indexPathForRow:indexPath.row - prevrow
					inSection:i];
			break;
		}
		prevrow = sr[i].intValue;
	}
//	printf("Old %d %d new %d %d\n",(int)indexPath.section,(int)indexPath.row, (int)newIndexPath.section, (int)newIndexPath.row);

	return newIndexPath;
}

#pragma mark Data fetchers

- (void)fetchTimesForVehicleStops:(NSString*)block
{
    int items = 0;
    int pos  = 0;
    bool found = false;
    bool done = false;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    while (items < MAX_STOPS && pos < self.vehicleStops.count && !done)
    {
        Stop * stop = self.vehicleStops[pos];
        XMLDepartures *deps = [[ XMLDepartures alloc ] init];
        
        
        deps.blockFilter = block;
        deps.firstOnly = YES;
        
        [self.backgroundTask.callbackWhenFetching backgroundSubtext:stop.desc];
        
        [self.backgroundTask.callbackWhenFetching backgroundItemsDone:items+1];
        
        [deps getDeparturesForLocation:stop.locid];
        
        if (deps.gotData && deps.count > 0)
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
    
    [pool release];
}


- (StopDistanceData *)fetchOtherDirectionForDeparture:(DepartureData*)dep items:(int*)items total:(int*)total
{
    // Note - to autorelease pool as this is not a thread method
    XMLRoutes *routes = [XMLRoutes xml];
    
    static NSDictionary *oppositePairs = nil;
    
    
    // Some routes have an opposite route - the direction is '0' for both
    // e.g. streetcar
    if (oppositePairs == nil)
    {
        oppositePairs = @{ @"194": @"195", @"195": @"194"}.retain;
    }
    
    NSString *oppositeRoute = oppositePairs[dep.route];
    
    NSString *oppositeDirection = nil;
    
    if (oppositeRoute != nil)
    {
        oppositeDirection = dep.dir;
        [self.backgroundTask.callbackWhenFetching backgroundItemsDone:++(*items)];
    }
    else
    {
        oppositeRoute = dep.route;
        
        [self.backgroundTask.callbackWhenFetching backgroundSubtext:@"checking direction"];
        [routes getDirections:oppositeRoute cacheAction:TrIMetXMLCacheReadOrFetch];
        if (routes.itemFromCache)
        {

            [self.backgroundTask.callbackWhenFetching backgroundItems:--(*total)];
        }
        else
        {
            [self.backgroundTask.callbackWhenFetching backgroundItemsDone:++(*items)];
        }
    
        // Find the first direction that isn't us
        if (routes.count > 0)
        {
            Route *route = routes.itemArray.firstObject;
        
            for (NSString *routeDir in route.directions)
            {
                if (![routeDir isEqualToString:dep.dir])
                {
                    oppositeDirection = routeDir;
                }
            }
        }
    }
    
    if (oppositeDirection)
    {
        static NSDictionary *interlined = nil;
        
        // some lines are interlined so finding one route is as good as another
        if (interlined == nil)
        {
            interlined = @{ @"190": @"290", @"290": @"190"}.retain;
        }
        
        NSArray *routes = nil;
        
        NSString *otherLine = interlined[oppositeRoute];
        
        if (otherLine)
        {
            routes = @[oppositeRoute, otherLine];
        }
        else
        {
            routes = @[oppositeRoute];
        }
        
        CLLocationDistance closest = DBL_MAX;
        Stop *closestStop = nil;
        
        [self.backgroundTask.callbackWhenFetching backgroundSubtext:@"finding stop"];
        
        bool fetched = NO;
        
        for (NSString *foundRoute in routes)
        {
            XMLStops *stops = [[XMLStops alloc] init];
            [stops getStopsForRoute:foundRoute direction:oppositeDirection description:nil cacheAction:TrIMetXMLCacheReadOrFetch];
            fetched = fetched || (!stops.itemFromCache);
            
            if (stops.count >0)
            {
                for (Stop *stop in stops.itemArray)
                {
                    CLLocation *there = [[CLLocation alloc] initWithLatitude:stop.lat.doubleValue longitude:stop.lng.doubleValue];
                    CLLocationDistance dist = [dep.stopLocation distanceFromLocation:there];
                    
                    if (dist < closest)
                    {
                        closest = dist;
                        [closestStop release];
                        closestStop = [stop retain];
                    }
                    
                    [there release];
                }
            }
            [stops release];
        }
        
        if (fetched)
        {
            [self.backgroundTask.callbackWhenFetching backgroundItemsDone:++(*items)];
        }
        else
        {
            [self.backgroundTask.callbackWhenFetching backgroundItems:--(*total)];
        }


        
        if (closestStop)
        {
            StopDistanceData *distance = [StopDistanceData data];
            
            distance.locid      = closestStop.locid;
            distance.desc       = closestStop.desc;
            distance.dir        = oppositeDirection;
            distance.distance   = closest;
            distance.accuracy   = 0;
            distance.location   = [[[CLLocation alloc] initWithLatitude:closestStop.lat.doubleValue longitude:closestStop.lng.doubleValue] autorelease];


            [closestStop release];
            return distance;
        }
    }
    return nil;
}

- (void)fetchTimesForLocation:(NSString *)location
                        block:(NSString *)block
                        names:(NSArray *)names
                     bookmark:(NSString*)bookmark
                     opposite:(DepartureData*)findOpposite
                  oppositeAll:(XMLDepartures*)findOppositeAll
{
    [self runAsyncOnBackgroundThread:^{
        NSThread *thread = [NSThread currentThread];
        
        NSString* loc = location;
        self.networkActivityIndicatorVisible = YES;
        
        [self clearSections];
        [XMLDepartures clearCache];
        self.streetcarLocations = nil;
        
        NSMutableArray *oppositeStops = nil;
        int total = 0;
        int items = 0;
        
        if (findOpposite)
        {
            total = 3;
            
            [self.backgroundTask.callbackWhenFetching backgroundStart:total title:(bookmark!=nil?bookmark:kGettingArrivals)];
            StopDistanceData  * stop = [self fetchOtherDirectionForDeparture:findOpposite items:&items total:&total];
            
            if (stop)
            {
                oppositeStops = [@[stop].mutableCopy autorelease];
                loc = stop.locid;
            }
            
            total --;
        }
        else if (findOppositeAll)
        {
            NSMutableArray *uniqueRoutes = [NSMutableArray array];
            
            for (int i=0; i<findOppositeAll.count; i++)
            {
                DepartureData *dep = findOppositeAll[i];
                
                DepartureData * found = 0;
                
                for (DepartureData *d in uniqueRoutes)
                {
                    if ([d.route isEqualToString:dep.route] && [d.dir isEqualToString:dep.dir])
                    {
                        found = d;
                        break;
                    }
                }
                
                if (found == nil)
                {
                    [uniqueRoutes addObject:dep];
                }
            }
            
            total = (int)uniqueRoutes.count * 2 + 1;
            [self.backgroundTask.callbackWhenFetching backgroundStart:total title:(bookmark!=nil?bookmark:kGettingArrivals)];
            
            oppositeStops = [NSMutableArray array];
            
            for (DepartureData *d in uniqueRoutes)
            {
                StopDistanceData* foundStop = [self fetchOtherDirectionForDeparture:d items:&items total:&total];
                
                if (foundStop)
                {
                    for (int i=0; i<oppositeStops.count; i++)
                    {
                        StopDistanceData* stop = oppositeStops[i];
                        
                        if ([stop.locid isEqualToString:foundStop.locid])
                        {
                            foundStop = nil;
                            break;
                        }
                        else if (foundStop.distance < stop.distance)
                        {
                            [oppositeStops insertObject:foundStop atIndex:i];
                            foundStop = nil;
                            break;
                        }
                    }
                    
                    if (foundStop !=nil)
                    {
                        [oppositeStops addObject:foundStop];
                    }
                }
                else
                {
                    break;
                }
            }
            
            if (!thread.cancelled)
            {
                loc = [NSString commaSeparatedStringFromEnumerator:oppositeStops selector:@selector(locid)];
            }
            total--;
        }
        else
        {
            total = 0;
            [self.backgroundTask.callbackWhenFetching backgroundStart:1 title:(bookmark!=nil?bookmark:kGettingArrivals)];
        }
        
        self.stops = loc;
        
        if (loc != nil)
        {
            NSArray *locList = loc.arrayFromCommaSeparatedString;
            
            total = (int)locList.count;
            
            [self.backgroundTask.callbackWhenFetching backgroundItems:total];
            
            int stopCount = 0;
            for (int i=0; i<locList.count && !thread.cancelled; i++)
            {
                XMLDepartures *deps = [XMLDepartures xml];
                [self.originalDataArray addObject:deps];
                deps.blockFilter = block;
                NSString *aLoc = locList[i];
                
                
                if (names == nil || stopCount > names.count)
                {
                    [self.backgroundTask.callbackWhenFetching backgroundSubtext:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), aLoc]];
                }
                else
                {
                    [self.backgroundTask.callbackWhenFetching backgroundSubtext:names[stopCount]];
                }
                
                [deps getDeparturesForLocation:aLoc];
                
                if (oppositeStops && stopCount < oppositeStops.count)
                {
                    deps.distance = oppositeStops[stopCount];
                }
                
                stopCount++;
                items ++;
                [self.backgroundTask.callbackWhenFetching backgroundItemsDone:items];
                
            }
            
            self.networkActivityIndicatorVisible = NO;
            
            
            if (self.originalDataArray.count > 0)
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
            
            
            if (!thread.cancelled)
            {
                [_userData setLastArrivals:loc];
                
                NSMutableArray *names = [NSMutableArray array];
                
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
                else
                {
                    [_userData setLastNames:nil];
                }
            }
            
        }
        else if (findOpposite || findOppositeAll)
        {
            [thread cancel];
            [self.backgroundTask.callbackWhenFetching backgroundSetErrorMsg:@"Could not find a stop going the other way."];
        }
        
        [self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
        
        
    }];
    
}

- (void)fetchAgainAsync:(id<BackgroundTaskProgress>)background 
{
    self.backgroundTask.callbackWhenFetching = background;
    
    if (self.vehicleStops)
    {
        [self runAsyncOnBackgroundThread:^{
            [self.backgroundTask.callbackWhenFetching backgroundStart:MAX_STOPS title:kGettingArrivals];
            
            [self clearSections];
            
            self.networkActivityIndicatorVisible = YES;
            
            
            XMLDepartures *dd = self.originalDataArray.firstObject;
            NSString *block = dd.blockFilter;
            
            [self.originalDataArray removeAllObjects];
            
            [self fetchTimesForVehicleStops:block];
            
            self.networkActivityIndicatorVisible = NO;
            
            _blockFilter = true;
            self.blockSort = YES;
            self.allowSort = YES;
            
            [self sortByBus];
            [self clearSections];
            
            [self.backgroundTask.callbackWhenFetching backgroundCompleted:nil];
            
        }];
    }
    else
    {
        [self runAsyncOnBackgroundThread:^{
            int i=0;
            
            NSThread *thread = [NSThread currentThread];
            
            [self.backgroundTask.callbackWhenFetching backgroundStart:(int)self.originalDataArray.count title:kGettingArrivals];
            
            [self clearSections];
            
            self.networkActivityIndicatorVisible = YES;
            for (i=0; i< self.originalDataArray.count && !thread.cancelled; i++)
            {
                XMLDepartures *dd = self.originalDataArray[i];
                if (dd.locDesc !=nil)
                {
                    [self.backgroundTask.callbackWhenFetching backgroundSubtext:dd.locDesc];
                }
                [dd reload];
                [self.backgroundTask.callbackWhenFetching backgroundItemsDone:i+1];
            }
            self.networkActivityIndicatorVisible = NO;
            [self sortByBus];
            [self clearSections];
            
            [self.backgroundTask.callbackWhenFetching backgroundCompleted:nil];
            
        }];
    }
}

- (void)fetchTimesForLocationAsync:(id<BackgroundTaskProgress>)background loc:(NSString*)loc block:(NSString *)block
{
    self.backgroundTask.callbackWhenFetching = background;
    
    [self fetchTimesForLocation:loc
                          block:block
                          names:nil
                       bookmark:nil
                       opposite:nil
                    oppositeAll:nil];
}

- (void)fetchTimesForVehicleAsync:(id<BackgroundTaskProgress>)background route:(NSString *)route direction:(NSString *)direction nextLoc:(NSString*)loc block:(NSString *)block
{
    self.backgroundTask.callbackWhenFetching = background;
    
    [self runAsyncOnBackgroundThread:^{
            NSThread *thread = [NSThread currentThread];
        
            [self clearSections];
            [XMLDepartures clearCache];
            self.streetcarLocations = nil;
            
            // Get Route info
            XMLStops * stops = [XMLStops xml];
            
            self.networkActivityIndicatorVisible = YES;
            
            [self.backgroundTask.callbackWhenFetching backgroundStart:MAX_STOPS+1 title:NSLocalizedString(@"getting next stop IDs", @"progress message")];
            
            [stops getStopsAfterLocation:loc route:route direction:direction description:@"" cacheAction:TriMetXMLForceFetchAndUpdateCache];
            [self.backgroundTask.callbackWhenFetching backgroundItemsDone:1];
            
            if (stops.gotData)
            {
                
                self.vehicleStops = stops.itemArray;
                
                [self fetchTimesForVehicleStops:block];
            }
            
            
            if (self.originalDataArray.count == 0)
            {
                [thread cancel];
                [self.backgroundTask.callbackWhenFetching backgroundSetErrorMsg:NSLocalizedString(@"Could not find any arrivals for that vehicle.", @"error message")];
            }
            
            self.networkActivityIndicatorVisible = NO;
            
            
            _blockFilter = true;
            self.blockSort = YES;
            
            [self sortByBus];
            
            self.allowSort = YES;
            
            [self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
            
            if (!thread.cancelled)
            {
                [_userData setLastArrivals:loc];
                
                NSMutableArray *names = [NSMutableArray array];
                
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
        
    }];
    
}


- (void)fetchTimesForNearestStopsAsync:(id<BackgroundTaskProgress>)background location:(CLLocation *)here maxToFind:(int)max minDistance:(double)min mode:(TripMode)mode
{
    self.backgroundTask.callbackWhenFetching = background;
    
    XMLLocateStops *locator = [XMLLocateStops xml];
    
    locator.maxToFind = max;
    locator.location = here;
    locator.mode = mode;
    locator.minDistance = min;
    
    [self runAsyncOnBackgroundThread:^{
        NSThread *thread = [NSThread currentThread];
        
        [self clearSections];
        [XMLDepartures clearCache];
        self.streetcarLocations = nil;
        
        [self.backgroundTask.callbackWhenFetching backgroundStart:locator.maxToFind+1 title:kGettingArrivals];
        
        [self.backgroundTask.callbackWhenFetching backgroundSubtext:NSLocalizedString(@"getting locations", @"progress message")];
        
        [locator findNearestStops];
        
        [self.backgroundTask.callbackWhenFetching backgroundItemsDone:1];
        
        if (![locator displayErrorIfNoneFound:self.backgroundTask.callbackWhenFetching])
        {
            NSMutableString * stopsstr = [NSMutableString string];
            self.stops = stopsstr;
            int i;
            self.networkActivityIndicatorVisible = YES;
            for (i=0; i< locator.count && i<locator.maxToFind && !thread.cancelled; i++)
            {
                XMLDepartures *deps = [XMLDepartures xml];
                StopDistanceData *sd = locator[i];
                
                [self.originalDataArray addObject:deps];
                
                [self.backgroundTask.callbackWhenFetching backgroundSubtext:sd.desc];
                [deps getDeparturesForLocation:sd.locid];
                if (i==0)
                {
                    [stopsstr appendFormat:@"%@",sd.locid];
                }
                else
                {
                    [stopsstr appendFormat:@",%@",sd.locid];
                }
                deps.distance = sd;
                
                [self.backgroundTask.callbackWhenFetching backgroundItemsDone:i+2];
            }
            
            if (self.originalDataArray.count > 0)
            {
                self.networkActivityIndicatorVisible = NO;
                
                _blockFilter = false;
                [self sortByBus];
            }
        }
        
        [self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
    }];
}


- (void)fetchTimesForStopInOtherDirectionAsync:(id<BackgroundTaskProgress>)background departure:(DepartureData*)dep
{
    self.backgroundTask.callbackWhenFetching = background;
    
    [self fetchTimesForLocation:nil
                          block:nil
                          names:nil
                       bookmark:nil
                       opposite:dep
                    oppositeAll:nil];
}

- (void)fetchTimesForStopInOtherDirectionAsync:(id<BackgroundTaskProgress>)background departures:(XMLDepartures*)deps
{
    self.backgroundTask.callbackWhenFetching = background;
    
    [self fetchTimesForLocation:nil
                          block:nil
                          names:nil
                       bookmark:nil
                       opposite:nil
                    oppositeAll:deps];
}

- (void)fetchTimesForNearestStopsAsync:(id<BackgroundTaskProgress>)background stops:(NSArray *)stops
{
	self.backgroundTask.callbackWhenFetching = background;
    
    [self runAsyncOnBackgroundThread:^{
        NSThread *thread = [NSThread currentThread];
        
        [self clearSections];
        [XMLDepartures clearCache];
        self.streetcarLocations = nil;
        
        [self.backgroundTask.callbackWhenFetching backgroundStart:(int)stops.count title:kGettingArrivals];
        
        NSMutableString * stopsstr = [NSMutableString string];
        self.stops = stopsstr;
        int i;
        self.networkActivityIndicatorVisible = YES;
        
        for (i=0; i< stops.count && !thread.cancelled; i++)
        {
            XMLDepartures *deps = [XMLDepartures xml];
            StopDistanceData *sd = stops[i];
            
            [self.originalDataArray addObject:deps];
            
            [self.backgroundTask.callbackWhenFetching backgroundSubtext:sd.desc];
            [deps getDeparturesForLocation:sd.locid];
            if (i==0)
            {
                [stopsstr appendFormat:@"%@",sd.locid];
            }
            else
            {
                [stopsstr appendFormat:@",%@",sd.locid];
            }
            deps.distance = sd;
            
            [self.backgroundTask.callbackWhenFetching backgroundItemsDone:i+2];
        }
        
        if (self.originalDataArray.count > 0)
        {
            self.networkActivityIndicatorVisible = NO;
            
            _blockFilter = false;
            [self sortByBus];
        }
        
        
        [self.backgroundTask.callbackWhenFetching backgroundCompleted:self];

    }];

}

- (void)fetchTimesForLocationAsync:(id<BackgroundTaskProgress>)background loc:(NSString*)loc names:(NSArray *)names
{
    self.backgroundTask.callbackWhenFetching = background;
    
    [self fetchTimesForLocation:loc
                          block:nil
                          names:names
                       bookmark:nil
                       opposite:nil
                    oppositeAll:nil];
}

- (void)fetchTimesForLocationAsync:(id<BackgroundTaskProgress>)background loc:(NSString*)loc
{
	self.backgroundTask.callbackWhenFetching = background;
    
    [self fetchTimesForLocation:loc
                          block:nil
                          names:nil
                       bookmark:nil
                       opposite:nil
                    oppositeAll:nil];
	
}

- (void)fetchTimesForLocationAsync:(id<BackgroundTaskProgress>)background loc:(NSString*)loc title:(NSString *)title
{
	self.backgroundTask.callbackWhenFetching = background;
    
    [self fetchTimesForLocation:loc
                          block:nil
                          names:nil
                       bookmark:title
                       opposite:nil
                    oppositeAll:nil];
}

- (void)fetchTimesForLocationsAsync:(id<BackgroundTaskProgress>)background stops:(NSArray *) stops
{
    self.backgroundTask.callbackWhenFetching = background;
    
    [self runAsyncOnBackgroundThread:^{
        NSThread *thread = [NSThread currentThread];
        
        [self clearSections];
        [XMLDepartures clearCache];
        self.streetcarLocations = nil;
        
        [self.backgroundTask.callbackWhenFetching backgroundStart:(int)stops.count title:kGettingArrivals];
        
        
        NSMutableString * stopsstr = [NSMutableString string];
        self.stops = stopsstr;
        int i;
        self.networkActivityIndicatorVisible = YES;
        for (i=0; i< stops.count && !thread.cancelled; i++)
        {
            XMLDepartures *deps = [XMLDepartures xml];
            StopDistanceData *sd = stops[i];
            
            [self.originalDataArray addObject:deps];
            [self.backgroundTask.callbackWhenFetching backgroundSubtext:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), sd.locid]];
            [deps getDeparturesForLocation:sd.locid];
            if (i==0)
            {
                [stopsstr appendFormat:@"%@",sd.locid];
            }
            else
            {
                [stopsstr appendFormat:@",%@",sd.locid];
            }
            deps.distance = sd;
            
            [self.backgroundTask.callbackWhenFetching backgroundItemsDone:i+1];
        }
        
        if (self.originalDataArray.count > 0)
        {
            self.networkActivityIndicatorVisible = NO;
            
            _blockFilter = false;
            [self sortByBus];
        }
        
        [self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
    }];
}

- (void)fetchTimesForBlockAsync:(id<BackgroundTaskProgress>)background block:(NSString*)block start:(NSString*)start stop:(NSString*) stop
{
    self.backgroundTask.callbackWhenFetching = background;
    
    
    [self runAsyncOnBackgroundThread:^{
        
        NSThread *thread = [NSThread currentThread];
        
        [self.backgroundTask.callbackWhenFetching backgroundStart:2 title:kGettingArrivals];
        
        [self clearSections];
        [XMLDepartures clearCache];
        self.streetcarLocations = nil;
        
        self.networkActivityIndicatorVisible = YES;
        XMLDepartures *deps = [XMLDepartures xml];
        
        [self.originalDataArray addObject:deps];
        deps.blockFilter = block;
        [self.backgroundTask.callbackWhenFetching backgroundSubtext:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), start]];
        [deps getDeparturesForLocation:start];
        deps.sectionTitle = NSLocalizedString(@"Departure", @"");
        [self.backgroundTask.callbackWhenFetching backgroundItemsDone:1];
        
        if(!thread.cancelled)
        {
            deps = [XMLDepartures xml];
            
            [self.originalDataArray addObject:deps];
            deps.blockFilter = block;
            [self.backgroundTask.callbackWhenFetching backgroundSubtext:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), stop]];
            [deps getDeparturesForLocation:stop];
            deps.sectionTitle = NSLocalizedString(@"Arrival", @"");
            [self.backgroundTask.callbackWhenFetching backgroundItemsDone:2];
        }
        
        _blockFilter = true;
        self.title = NSLocalizedString(@"Trip", @"");
        
        [self sortByBus];
        self.networkActivityIndicatorVisible = NO;
        
        [self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
    }];
}

- (void)fetchTimesViaQrCodeRedirectAsync:(id<BackgroundTaskProgress>)background URL:(NSString*)url
{
    self.backgroundTask.callbackWhenFetching = background;
    
    [self runAsyncOnBackgroundThread:^{
            NSThread *thread = [NSThread currentThread];
            
            [self.backgroundTask.callbackWhenFetching backgroundStart:2 title:kGettingArrivals];
            
            [self.backgroundTask.callbackWhenFetching backgroundSubtext:NSLocalizedString(@"getting stop ID", @"progress message")];
            
            
            self.networkActivityIndicatorVisible = YES;
            
            ProcessQRCodeString *qrCode = [[[ProcessQRCodeString alloc] init] autorelease];
            NSString *stopId = [qrCode extractStopId:url];
            
            [self.backgroundTask.callbackWhenFetching backgroundItemsDone:1];
            
            [self clearSections];
            [XMLDepartures clearCache];
            self.streetcarLocations = nil;
            self.stops = stopId;
            
            static NSString *streetcar = @"www.portlandstreetcar.org";
            
            if (!thread.isCancelled && stopId)
            {
                XMLDepartures *deps = [XMLDepartures xml];
                
                [self.originalDataArray addObject:deps];
                [self.backgroundTask.callbackWhenFetching backgroundSubtext:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), stopId]];
                [deps getDeparturesForLocation:stopId];
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
            
            self.networkActivityIndicatorVisible = NO;
            
            _blockFilter = false;
            [self sortByBus];
            [self.backgroundTask.callbackWhenFetching backgroundCompleted:self];
        
    }];
}






#pragma mark UI Helper functions


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
	id<DepartureTimesDataProvider> dd = self.visibleDataArray[self.actionItem.section];
	self.actionItem = nil;
	
	AlarmTaskList *taskList = [AlarmTaskList sharedInstance];
	if ([taskList userAlertForProximityAction:(int)buttonIndex stopId:dd.DTDataLocID loc:dd.DTDataLoc desc:dd.DTDataLocDesc])
	{
		[self reloadData];	
	}
}

- (void)refreshAction:(id)sender
{
    [super refreshAction:sender];
    
	if (self.table.hidden || self.backgroundTask.progressModal !=nil)
	{
		return; 
	}
	
    DEBUG_LOG(@"Refreshing\n");
	self.backgroundRefresh = true;
	
	
	[self fetchAgainAsync:self.backgroundTask];
	
	
	//	[[(MainTableViewController *)[self.navigationController topViewController] table] reloadData];	
}

-(void)showMapNow:(id)sender
{
    MapViewController *mapPage = [MapViewController viewController];
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
    
    NSMutableSet *blocks = [NSMutableSet set];
    
	for (i=self.originalDataArray.count-1; i>=0 ; i--)
	{
        XMLDepartures * dep   = self.originalDataArray[i];
        
        if (_singleMapItem!=nil && dep !=_singleMapItem)
        {
            continue;
        }
		
		if (dep.loc !=nil)
		{
			[mapPage addPin:dep];
            
            if (_blockFilter || _singleMapItem!=nil)
            {
			
                for (j=0; j< dep.count; j++)
                {
                    DepartureData *dd = dep[j];
				
                    if (dd.hasBlock && ![blocks containsObject:dd.block] && dd.blockPosition!=nil)
                    {
                        [mapPage addPin:dd];
                        [blocks addObject:dd.block];
                    }
                }
            }
        }
	}
    _singleMapItem = nil;
	
	[self.navigationController pushViewController:mapPage animated:YES];
}

-(bool)needtoFetchStreetcarLocationsForStop:(XMLDepartures*)dep
{
    bool needToFetchStreetcarLocations = false;
    
    if (dep.loc !=nil)
    {
        for (int j=0; j< dep.count; j++)
        {
            DepartureData *dd = dep[j];
            
            if (dd.streetcar && dd.blockPosition == nil)
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
        
        [self runAsyncOnBackgroundThread:^{
            int i=0;
            
            NSSet *streetcarRoutes = [XMLStreetcarLocations getStreetcarRoutesInDepartureArray:self.originalDataArray];
            
            [self.backgroundTask.callbackWhenFetching backgroundStart:(int)streetcarRoutes.count+((int)self.originalDataArray.count * (int)streetcarRoutes.count) title:NSLocalizedString(@"getting locations", @"progress message")];
            
            self.networkActivityIndicatorVisible = YES;
            
            
            for (NSString *route in streetcarRoutes)
            {
                for (XMLDepartures *dep in self.originalDataArray)
                {
                    // First get the arrivals via next bus to see if we can get the correct vehicle ID
                    XMLStreetcarPredictions *streetcarArrivals = [[XMLStreetcarPredictions alloc] init];
                    
                    [streetcarArrivals getDeparturesForLocation:[NSString stringWithFormat:@"predictions&a=portland-sc&r=%@&stopId=%@", route,dep.locid]];
                    
                    for (NSInteger i=0; i< streetcarArrivals.count; i++)
                    {
                        DepartureData *vehicle = streetcarArrivals[i];
                        
                        for (DepartureData *dd in dep.itemArray)
                            
                            if ([vehicle.block isEqualToString:dd.block])
                            {
                                dd.streetcarId = vehicle.streetcarId;
                                break;
                            }
                    }
                    
                    [streetcarArrivals release];
                    
                    [self.backgroundTask.callbackWhenFetching backgroundItemsDone:++i];
                }
                
                XMLStreetcarLocations *locs = [XMLStreetcarLocations autoSingletonForRoute:route];
                [locs getLocations];
                [self.backgroundTask.callbackWhenFetching backgroundItemsDone:++i];
            }
            
            [XMLStreetcarLocations insertLocationsIntoDepartureArray:self.originalDataArray forRoutes:streetcarRoutes];
            
            self.networkActivityIndicatorVisible = NO;
            
            [self.backgroundTask.callbackWhenFetching backgroundCompleted:nil];
        }];
    }
    else {
        [self showMapNow:nil];
    }
}

-(void)showMap:(id)sender
{
    _singleMapItem = nil;
    
    if (self.originalDataArray.count > 1)
    {
        [self showMapNow:nil];
    }
    else
    {
        bool needToFetchStreetcarLocations = false;
	
        long i;
        for (i=self.originalDataArray.count-1; i>=0 && !needToFetchStreetcarLocations ; i--)
        {
            needToFetchStreetcarLocations = [self needtoFetchStreetcarLocationsForStop:self.originalDataArray[i]];
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
    DepartureSortTableView * options = [DepartureSortTableView viewController];
	
	options.depView = self;
	
	[self.navigationController pushViewController:options animated:YES];
}

-(void)bookmarkButton:(UIBarButtonItem *)sender
{
    NSMutableString *loc =  [NSMutableString string];
    NSMutableString *desc = [NSMutableString string];
    int i;
    
    if (self.originalDataArray.count == 1)
    {
        XMLDepartures *dd = self.originalDataArray.firstObject;
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
        XMLDepartures *dd = self.originalDataArray.firstObject;
        [loc appendFormat:@"%@", dd.locid];
        [desc appendFormat:NSLocalizedString(@"Stop IDs: %@", @"A list of TriMet stop IDs"), dd.locid];
        for (i=1; i< self.originalDataArray.count; i++)
        {
            XMLDepartures *dd = self.originalDataArray[i];
            [loc appendFormat:@",%@",dd.locid];
            [desc appendFormat:@",%@",dd.locid];
        }
    }
    
    int bookmarkItem = kNoBookmark;
    
    @synchronized (_userData)
    {
        for (i=0; _userData.faves!=nil &&  i< _userData.faves.count; i++)
        {
            NSDictionary *bm = _userData.faves[i];
            NSString * faveLoc = (NSString *)bm[kUserFavesLocation];
            if (bm !=nil && faveLoc !=nil && [faveLoc isEqualToString:loc])
            {
                bookmarkItem = i;
                desc = bm[kUserFavesChosenName];
                break;
            }
        }
    }
    
    
    
    if (bookmarkItem == kNoBookmark)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Bookmark", @"action list title")
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add new bookmark", @"button text")
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action){
                                                    EditBookMarkView *edit = [EditBookMarkView viewController];
                                                    [edit addBookMarkFromStop:desc location:loc];
                                                    // Push the detail view controller
                                                    [self.navigationController pushViewController:edit animated:YES];
                                                }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"button text") style:UIAlertActionStyleCancel handler:nil]];
        
        alert.popoverPresentationController.barButtonItem = sender;
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }
    else
    {
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:desc
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Delete this bookmark", @"button text")
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction *action){
                                                    [_userData.faves removeObjectAtIndex:bookmarkItem];
                                                    [self favesChanged];
                                                    [_userData cacheAppData];
                                                }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Edit this bookmark", @"button text")
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action){
                                                    EditBookMarkView *edit = [EditBookMarkView viewController];
                                                    @synchronized (_userData)
                                                    {
                                                        [edit editBookMark:_userData.faves[bookmarkItem] item:bookmarkItem];
                                                    }
                                                    // Push the detail view controller
                                                    [self.navigationController pushViewController:edit animated:YES];
                                                }]];
        
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"button text") style:UIAlertActionStyleCancel handler:nil]];
        
        alert.popoverPresentationController.barButtonItem = sender;
        
        [self presentViewController:alert animated:YES completion:nil];
        
    }
}

#pragma mark TableView methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat result;
	id<DepartureTimesDataProvider> dd = self.visibleDataArray[indexPath.section];
	NSIndexPath *newIndexPath = [self subsection:indexPath];
	
	
	switch (newIndexPath.section)
	{
		case kSectionTimes:
			if (dd.DTDataGetSafeItemCount==0 && newIndexPath.row == 0 && !_blockFilter )
			{
				result = kNonDepartureHeight;
			}
			else
			{
                result = DEPARTURE_CELL_HEIGHT;
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
        case kSectionStation:
        case kSectionMapOne:
        case kSectionOpposite:
        case kSectionNoDeeper:
			return [self narrowRowHeight];
		case kSectionAccuracy:
			return [self narrowRowHeight];
        case kSectionXML:
			return [self narrowRowHeight];
		case kSectionDistance:
			if (dd.DTDataDistance.accuracy > 0.0)
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
	return self.visibleDataArray.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	SECTIONROWS *sr = [self calcSubsections:section];
	
	if ([self validStop:section])
	{
		id<DepartureTimesDataProvider> dd = self.visibleDataArray[section];
		[_userData addToRecentsWithLocation:dd.DTDataLocID
								description:dd.DTDataGetSectionHeader];
	}
	
	//DEBUG_LOG(@"Section: %ld rows %ld expanded %d\n", (long)section, (long)sr->row[kSectionsPerStop-1],
	//		  (int)_sectionExpanded[section]);

	
	return sr[kSectionsPerStop-1].integerValue;
}



- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	id<DepartureTimesDataProvider> dd = self.visibleDataArray[section];
	return dd.DTDataGetSectionHeader;
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

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
  
    header.textLabel.adjustsFontSizeToFitWidth = YES;
    header.textLabel.minimumScaleFactor = 0.84;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = nil;
	
	id<DepartureTimesDataProvider> dd = self.visibleDataArray[indexPath.section];
	NSIndexPath * newIndexPath = [self subsection:indexPath];
	
	switch (newIndexPath.section)
	{
		case kSectionDistance:
		{
			bool twoLines = (dd.DTDataDistance.accuracy > 0.0);
			if (twoLines)
			{
				cell = [tableView dequeueReusableCellWithIdentifier:kDistanceCellId2];
				if (cell == nil) {
					cell = [self distanceCellWithReuseIdentifier:kDistanceCellId2];
				}
				
				NSString *distance = [NSString stringWithFormat:NSLocalizedString(@"Distance %@", @"stop distance"), [FormatDistance formatMetres:dd.DTDataDistance.distance]];
				((UILabel*)[cell.contentView viewWithTag:DISTANCE_TAG]).text = distance;
				UILabel *accuracy = (UILabel*)[cell.contentView viewWithTag:ACCURACY_TAG];
				accuracy.text = [NSString stringWithFormat:NSLocalizedString(@"Accuracy +/- %@", @"accuracy of location services"), [FormatDistance formatMetres:dd.DTDataDistance.accuracy]];
				cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", distance, accuracy.text];
				
			}
			else
			{
				cell = [tableView dequeueReusableCellWithIdentifier:kDistanceCellId];
				if (cell == nil) {
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDistanceCellId] autorelease];
				}
				
				cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Distance %@", @"stop distance"), [FormatDistance formatMetres:dd.DTDataDistance.distance]];
				cell.textLabel.textColor = [UIColor blueColor];
				cell.textLabel.font = self.basicFont;;
				cell.accessibilityLabel = cell.textLabel.text;
				
			}
			cell.imageView.image = nil;
			break;
		}
		case kSectionTimes:
		// Configure the cell
		{
			int i = (int)newIndexPath.row;
			NSInteger deps = dd.DTDataGetSafeItemCount;
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
                    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
					cell.textLabel.font = self.paragraphFont;
					
				}
				else
				{
					cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"(ID %@) No arrivals found.", @"No arrivals for a specific TriMet stop ID"), dd.DTDataLocID];
					cell.textLabel.font = self.basicFont;

				}
				cell.accessoryType = UITableViewCellAccessoryNone;
				break;
			}
			else
			{
				DepartureData *departure = [dd DTDataGetDeparture:newIndexPath.row];
           
				DepartureCell *dcell = [tableView dequeueReusableCellWithIdentifier:MakeCellId(kSectionTimes)];
            
				if (dcell == nil) {
                    dcell = [DepartureCell cellWithReuseIdentifier:MakeCellId(kSectionTimes)];
				}
                
				[dd DTDataPopulateCell:departure cell:dcell decorate:YES wide:LARGE_SCREEN];
				// [departure populateCell:cell decorate:YES big:YES];
                
                cell = dcell;
				
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
				
				if (dd.DTDataNetworkError)
				{
					if (dd.DTDataNetworkErrorMsg)
					{
						[self addTextToDisclaimerCell:cell 
												 text:kNetworkMsg];
					}
					else {
						[self addTextToDisclaimerCell:cell text:
						 [NSString stringWithFormat:kNoNetworkID, dd.DTDataLocID]];
					}

				}	
				else if ([self validStop:indexPath.section])
				{
					[self addTextToDisclaimerCell:cell text:[NSString stringWithFormat:NSLocalizedString(@"%@ Updated: %@", @"text followed by time data was fetched"),
															 dd.DTDataStaticText,
															 [NSDateFormatter localizedStringFromDate:TriMetToNSDate(dd.DTDataQueryTime)
                                                                                            dateStyle:NSDateFormatterNoStyle
                                                                                            timeStyle:NSDateFormatterMediumStyle]]];
				}
				
				
				if (dd.DTDataNetworkError)
				{
					cell.accessoryView = nil;
					cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
					cell.selectionStyle = UITableViewCellSelectionStyleBlue;
				}
				else if (dd.DTDataHasDetails)
				{
					cell.accessoryView =  [[[ UIImageView alloc ] 
                                            initWithImage: self.sectionExpanded[indexPath.section].boolValue
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
				DepartureData *dep = nil;
				NSString *streetcarDisclaimer = nil;
				
				for (int i=0; i< dd.DTDataGetSafeItemCount && streetcarDisclaimer==nil; i++)
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
				cell.textLabel.font = self.basicFont; 
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
			cell.textLabel.font = self.basicFont; 
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.imageView.image = [self getActionIcon:kIconArrivals];
		}
		break;	
        case kSectionInfo:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:kActionCellId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kActionCellId] autorelease];
			}
			
			cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Stop ID %@ info", @"button text"), dd.DTDataLocID];
			cell.textLabel.textColor = [ UIColor darkGrayColor];
			cell.textLabel.font = self.basicFont; 
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.imageView.image = [self getActionIcon:kIconTriMetLink];
            break;

		}
        case kSectionStation:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kActionCellId];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kActionCellId] autorelease];
            }
            
            cell.textLabel.text = NSLocalizedString(@"Rail station details", @"button text");
            cell.textLabel.textColor = [ UIColor darkGrayColor];
            cell.textLabel.font = self.basicFont;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [self getActionIcon:KIconRailStations];
            break;
            
        }
        case kSectionMapOne:
		{
			cell = [tableView dequeueReusableCellWithIdentifier:kActionCellId];
			if (cell == nil) {
				cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kActionCellId] autorelease];
			}
			cell.textLabel.text = NSLocalizedString(@"Map of arrivals", @"button text");
			cell.textLabel.textColor = [ UIColor darkGrayColor];
			cell.textLabel.font = self.basicFont;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.imageView.image = cell.imageView.image = [self getActionIcon7:kIconMapAction7 old:kIconMapAction];
            break;
		}
            
        case kSectionOpposite:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kActionCellId];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kActionCellId] autorelease];
            }
            cell.textLabel.text = NSLocalizedString(@"Arrivals going the other way ", @"button text");
            cell.textLabel.textColor = [ UIColor darkGrayColor];
            cell.textLabel.font = self.basicFont;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.imageView.image = [self getActionIcon:kIconArrivals];
            break;
        };
        case kSectionNoDeeper:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:kActionCellId];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kActionCellId] autorelease];
            }
            cell.textLabel.text = NSLocalizedString(@"Too many windows open", @"button text");
            cell.textLabel.textColor = [ UIColor darkGrayColor];
            cell.textLabel.font = self.basicFont;
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.imageView.image = [self getActionIcon:kIconCancel];
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
			cell.textLabel.font = self.basicFont; 
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
			
			AlarmTaskList *taskList = [AlarmTaskList sharedInstance];
			
			if ([taskList hasTaskForStopIdProximity:dd.DTDataLocID])
			{
				cell.textLabel.text = NSLocalizedString(@"Cancel proximity alarm", @"button text");
			}
			else if ([LocationAuthorization locationAuthorizedOrNotDeterminedShowMsg:NO backgroundRequired:YES])
			{
				cell.textLabel.text = kUserProximityCellText;
			}
            else
            {
                cell.textLabel.text = kUserProximityDeniedCellText;
            }

			cell.textLabel.textColor = [ UIColor darkGrayColor];
			cell.textLabel.font = self.basicFont; 
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
			cell.textLabel.font = self.basicFont; 
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
				
				cell.textLabel.text = dd.DTDataGetSectionTitle;
				cell.textLabel.textColor = [ UIColor darkGrayColor];
				cell.textLabel.font = self.basicFont; 
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
				cell.textLabel.font = self.basicFont; 
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
            
            cell.textLabel.text = NSLocalizedString(@"Copy raw XML to clipboard", @"button text");
            cell.textLabel.textColor = [ UIColor darkGrayColor];
            cell.textLabel.font = self.basicFont; 
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.imageView.image = [self getActionIcon:kIconXml];
            break;
        }
        default:
            cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
            break;
    }
	return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	[tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	return [self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	id<DepartureTimesDataProvider> dd = self.visibleDataArray[indexPath.section];
	NSIndexPath *newIndexPath = [self subsection:indexPath];
	
	switch (newIndexPath.section)
	{
		case kSectionTimes:
		{
			if (dd.DTDataGetSafeItemCount!=0 && newIndexPath.row < dd.DTDataGetSafeItemCount)
			{
				DepartureData *departure = [dd DTDataGetDeparture:newIndexPath.row];
		
				// if (departure.hasBlock || departure.detour)
				{
                    DepartureDetailView *departureDetailView = [DepartureDetailView viewController];
					departureDetailView.callback = self.callback;
                    departureDetailView.delegate = self;
                    
                    departureDetailView.navigationItem.prompt = self.navigationItem.prompt;
					
					if (depthCount < kMaxDepth && self.visibleDataArray.count > 1)
					{
						departureDetailView.stops = self.stops;
					}
                    
                    departureDetailView.allowBrowseForDestination = ((!_blockFilter) || [UserPrefs sharedInstance].vehicleLocations) && depthCount < kMaxDepth;
					
					[departureDetailView fetchDepartureAsync:self.backgroundTask dep:departure allDepartures:self.originalDataArray];
				}
			}
			break;
		}
		case kSectionTrip:
		{
            TripPlannerSummaryView *tripPlanner = [TripPlannerSummaryView viewController];
			
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
			endpoint.additionalInfo     = dd.DTDataLocDesc;
			endpoint.locationDesc       = dd.DTDataLocID;
			
			
			[self.navigationController pushViewController:tripPlanner animated:YES];
			break;
		}
		case kSectionProximity:
		{
			AlarmTaskList *taskList = [AlarmTaskList sharedInstance];
			
			if ([taskList hasTaskForStopIdProximity:dd.DTDataLocID])
			{
				[taskList cancelTaskForStopIdProximity:dd.DTDataLocID];
			}
            else if ([LocationAuthorization locationAuthorizedOrNotDeterminedShowMsg:NO backgroundRequired:YES])
			{
				self.actionItem = indexPath;
				[taskList userAlertForProximity:self];
			}
            else
            {
                [LocationAuthorization locationAuthorizedOrNotDeterminedShowMsg:YES backgroundRequired:YES];
            }
			[self reloadData];
			break;
		}
		case kSectionNearby:
		{
            
            FindByLocationView *find = [[FindByLocationView alloc] initWithLocation:dd.DTDataLoc description:dd.DTDataLocDesc];

			[self.navigationController pushViewController:find animated:YES];
            
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
			NSString *url = [NSString stringWithFormat:@"https://trimet.org/go/cgi-bin/cstops.pl?action=entry&resptype=U&lang=pdaen&noCat=Landmark&Loc=%@",
							 dd.DTDataLocID];
            
            
            [WebViewController displayPage:url
                                      full:url
                                 navigator:self.navigationController
                            itemToDeselect:self
                                  whenDone:nil];

			break;
		}
            
        case kSectionStation:
        {
            {
                RailStation * station = [AllRailStationView railstationFromStopId:dd.DTDataLocID];
                
                if (station == nil)
                {
                    return;
                }
                
                RailStationTableView *railView = [RailStationTableView viewController];
                railView.station = station;
                railView.callback = self.callback;
                // railView.from = self.from;
                railView.locationsDb = [StopLocations getDatabase];
                [self.navigationController pushViewController:railView animated:YES];
            }	

            break;
        }
            
        case kSectionMapOne:
		{
			[self showMapForOneStop:[dd DTDataXML ]];
			break;
		}
        case kSectionOpposite:
        {
            DepartureTimesView *opposite = [DepartureTimesView viewController];
            opposite.callback = self.callback;
            [opposite fetchTimesForStopInOtherDirectionAsync:self.backgroundTask departures:dd.DTDataXML];
            break;
        }
        case kSectionNoDeeper:
            [self.navigationController popViewControllerAnimated:YES];
            break;
            
		case kSectionAccuracy:
		{
			NSString *url = [NSString stringWithFormat:@"https://trimet.org/arrivals/small/tracker?locationID=%@",
							 dd.DTDataLocID];
            
            
            [WebViewController displayPage:url
                                      full:url
                                 navigator:self.navigationController
                            itemToDeselect:self
                                  whenDone:nil];
            
			break;
		}
        case kSectionXML:
		{
            XMLDepartures *dep = dd.DTDataXML;
            
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
            DepartureTimesView *departureViewController = [DepartureTimesView viewController];
			
			departureViewController.callback = self.callback;
			[departureViewController fetchTimesForLocationAsync:self.backgroundTask 
                                                            loc:dd.DTDataLocID
                                                          title:dd.DTDataLocDesc];
			break;
		}
		case kSectionFilter:
		{
			
			if ([dd respondsToSelector:@selector(DTDataXML)])
			{
				XMLDepartures *dep = (XMLDepartures*)dd.DTDataXML;
					
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
			if (dd.DTDataNetworkError)
			{
				[self networkTips:dd.DTDataHtmlError networkError:dd.DTDataNetworkErrorMsg];
                [self clearSelection];
				
			} else if (!_blockSort)
			{
				int sect = (int)indexPath.section;
				[self.table deselectRowAtIndexPath:indexPath animated:YES];
				self.sectionExpanded[sect] = self.sectionExpanded[sect].boolValue ? @NO : @YES;
			
				
				// copy this struct
                SECTIONROWS *oldRows = [self.sectionRows[sect].copy autorelease];
				
                SECTIONROWS *newRows = self.sectionRows[sect];
				
				newRows[0] = @(kSectionRowInit);
				
				[self calcSubsections:sect];
				
				NSMutableArray *changingRows = [NSMutableArray array];
				
				int row;
				
				SECTIONROWS *additionalRows;
				
				if (self.sectionExpanded[sect].boolValue)
				{
					additionalRows = newRows;
				}
				else 
				{
					additionalRows = oldRows;
				}

				
			    for (int i=0; i< kSectionsPerStop; i++)
				{
					// DEBUG_LOG(@"index %d\n",i);
					// DEBUG_LOG(@"row %d\n", newRows->row[i+1]-newRows->row[i]);
					// DEBUG_LOG(@"old row %d\n", oldRows.row[i+1]-oldRows.row[i]);
					
					if (newRows[i+1].integerValue-newRows[i].integerValue != oldRows[i+1].integerValue-oldRows[i].integerValue)
					{
						
						for (row = additionalRows[i].intValue; row < additionalRows[i+1].intValue; row++)
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
									   initWithImage: self.sectionExpanded[sect].boolValue
                                                 ? [self alwaysGetIcon7:kIconCollapse7  old:kIconCollapse]
                                                 : [self alwaysGetIcon7:kIconExpand7    old:kIconCollapse]
									   ];
					[staticCell setNeedsDisplay];
				}
			
				[self.table beginUpdates];	
				
				
				if (self.sectionExpanded[sect].boolValue)
				{
					[self.table insertRowsAtIndexPaths:changingRows withRowAnimation:UITableViewRowAnimationRight];
				}
				else 
				{
					[self.table deleteRowsAtIndexPaths:changingRows withRowAnimation:UITableViewRowAnimationRight];
					
				
				}
				// DEBUG_LOG(@"reloadRowsAtIndexPaths %d %d\n", newRows->row[kSectionStatic], sect);
				[self.table endUpdates];
			}
            break;
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
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	//Configure and enable the accelerometer
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleChangeInUserSettings:) name:NSUserDefaultsDidChangeNotification object:[NSUserDefaults standardUserDefaults]];
	
    [self cacheWarningRefresh:NO];
}

- (void) viewWillDisappear:(BOOL)animated
{
    DEBUG_FUNC();
    
    // [UIView setAnimationsEnabled:NO];
    self.navigationItem.prompt = nil;
    // [UIView setAnimationsEnabled:YES];
    
    if (self.userActivity!=nil)
    {
        [self.userActivity invalidate];
        self.userActivity = nil;
    }
    
    [super viewWillDisappear:animated];
}

- (void) viewDidDisappear:(BOOL)animated
{
    DEBUG_FUNC();
    [super viewDidDisappear:animated];
    
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
    [toolbarItems addObject:[UIToolbar autoFlexSpace]];
    
    if (((!(_blockFilter || self.originalDataArray.count == 1)) || _allowSort) && ([UserPrefs sharedInstance].groupByArrivalsIcon))
    {
        UIBarButtonItem *sort = [[[UIBarButtonItem alloc]
                                  // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                                  initWithImage:[TableViewWithToolbar getToolbarIcon7:kIconSort7 old:kIconSort]
                                  style:UIBarButtonItemStylePlain
                                  target:self action:@selector(sortButton:)] autorelease];
        
        sort.accessibilityLabel = NSLocalizedString(@"Group Arrivals", @"Accessibility text");
        
        [toolbarItems addObject:sort];;
        [toolbarItems addObject:[UIToolbar autoFlexSpace]];
        
    }
    
    [toolbarItems addObject:[UIToolbar autoMapButtonWithTarget:self action:@selector(showMap:)]];
    
    if ([UserPrefs sharedInstance].ticketAppIcon)
    {
        [toolbarItems addObject:[UIToolbar autoFlexSpace]];
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
    
    if (!_updatedWatch)
    
    {
        _updatedWatch = YES;
         [self updateWatch];
    };
   
    
    Class userActivityClass = (NSClassFromString(@"NSUserActivity"));
    
    if (userActivityClass !=nil)
    {
        
        NSMutableString *locs = [NSString commaSeparatedStringFromEnumerator:self.originalDataArray selector:@selector(locid)];
        
        
        if (self.userActivity != nil)
        {
            [self.userActivity invalidate];
        }
        
        self.userActivity = [[[NSUserActivity alloc] initWithActivityType:kHandoffUserActivityBookmark] autorelease];
        
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        
        if (self.originalDataArray.count >= 1)
        {
            XMLDepartures *dep = self.originalDataArray.firstObject;
            
            self.userActivity.webpageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://trimet.org/arrivals/small/tracker?locationID=%@", dep.locid]];
        
            
            if (self.originalDataArray.count == 1 && dep.locDesc != nil)
            {
                info[kUserFavesChosenName] = dep.locDesc;
            }
            else
            {
                info[kUserFavesChosenName] = @"Stops";
            }
        
        }
        
        info[kUserFavesLocation] = locs;
        self.userActivity.userInfo = info;
        [self.userActivity becomeCurrent];
    }

    
    [self iOS7workaroundPromptGap];
}

- (bool)neverAdjustContentInset
{
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	if ([UserPrefs sharedInstance].shakeToRefresh && event.type == UIEventSubtypeMotionShake) {
		UIViewController * top = self.navigationController.visibleViewController;
		
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




- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self reloadData];
}

- (void)reloadData
{
    [super reloadData];
    [self cacheWarningRefresh:YES];
}

- (void)appendXmlData:(NSMutableData *)buffer
{
    id<DepartureTimesDataProvider> dd = self.visibleDataArray[self.table.indexPathForSelectedRow.section];
    XMLDepartures *dep = [dd DTDataXML];
    
    [dep appendQueryAndData:buffer];
    
    if (dep.streetcarData)
    {
        [buffer appendData:dep.streetcarData];
    }
}

@end

