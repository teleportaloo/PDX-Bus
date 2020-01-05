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
#import "StopDistance.h"

#import "MapViewWithRoutes.h"
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
#import "NSString+Helper.h"
#import "LocationAuthorization.h"
#import "AllRailStationView.h"
#import "RailStationTableView.h"
#import "VehicleTableView.h"
#import "CLLocation+Helper.h"
#import "Detour+DTData.h"
#import "Detour+iOSUI.h"
#import "XMLMultipleDepartures.h"
#import "KMLRoutes.h"
#import "ArrivalsIntent.h"
#import "MainQueueSync.h"

// The array must be set up carefully so don't change this ordering without
// changing the code aslo.
enum {
    kSectionDistance = 0,
    kSectionTitle,
    kSectionTimes,
    kSectionDetours,
    kSectionTrip,
    kSectionFilter,
    kSectionProximity,
    kSectionNearby,
    kSectionSiri,
    kSectionOneStop,
    kSectionOpposite,
    kSectionVehicles,
    kSectionNoDeeper,
    kSectionStation,
    kSectionInfo,
    kSectionAccuracy,
    kSectionStatic,
    kSectionSystemAlert,
    kSectionsPerStop
};

enum
{
    kTripRowFrom = 0,
    kTripRowTo,
    kTripRows
};

#define kActionCellId           @"Action"
#define kTitleCellId            @"Title"
#define kAlarmCellId            @"Alarm"
#define kDistanceCellId         @"Distance"
#define kDistanceCellId2        @"Distance2"
#define kStatusCellId           @"Status"

#define kGettingArrivals        @"getting departures"
#define kGettingStop            @"getting stop ID";

#define DISTANCE_TAG 1
#define ACCURACY_TAG 2

static int depthCount = 0;
#define kMaxDepth 4
 
@implementation DepartureTimesView

#define kNonDepartureHeight 35.0




#define MAX_STOPS 10

- (void)dealloc {

    depthCount--;
    DEBUG_LOGL(depthCount);
    
    if (self.userActivity)
    {
        [self.userActivity invalidate];
    }
    
    
    [self clearSections];
}


- (instancetype)init {
    if ((self = [super init]))
    {
        self.title = NSLocalizedString(@"Departures", @"page title");
        self.originalDataArray = [NSMutableArray array];
        self.visibleDataArray = [NSMutableArray array];
        self.locationsDb = [StopLocations getDatabase];
        self.allDetours = [NSMutableDictionary dictionary];
        self.allRoutes = [NSMutableDictionary dictionary];
        self.refreshFlags = kRefreshAll;
        
        DEBUG_LOGL(depthCount);
        depthCount++;
        _updatedWatch = NO;
    }
    return self;
}

#ifndef PDXBUS_EXTENSION
- (CGFloat)heightOffset
{
    return -[UIApplication sharedApplication].statusBarFrame.size.height;
}
#endif

#pragma mark Data sorting and manipulation

- (bool)validStopDataProvider:(id<DepartureTimesDataProvider>) dd
{
    return (dd.depGetSectionHeader!=nil
            &&  dd.depDetour == nil
            &&    (dd.depGetSafeItemCount == 0
                   ||  (dd.depGetSafeItemCount > 0 && [dd depGetDeparture:0].errorMessage==nil)));
}

- (bool)validStop:(unsigned long) i
{
    id<DepartureTimesDataProvider> dd = self.visibleDataArray[i];
    return [self validStopDataProvider:dd];
}

- (void)sortByStop
{
    NSMutableArray *uiArray = [NSMutableArray array];
    NSMutableSet *detoursNoLongerFound = [UserPrefs sharedInstance].hiddenSystemWideDetours.mutableCopy;
    
    
    [self.allDetours enumerateKeysAndObjectsUsingBlock: ^void (NSNumber* detourId, Detour* detour, BOOL *stop)
     {
         [detour.routes sortUsingComparator:^NSComparisonResult(Route *r1, Route *r2){
             return [r1 compare:r2];
         }];
         
         if (detour.systemWideFlag)
         {
             [uiArray addObject:detour];
             [detoursNoLongerFound removeObject:detour.detourId];
         }
     }];
    
    bool hasData = YES;
    
    for (XMLDepartures *dep in self.originalDataArray)
    {
        if (dep.gotData)
        {
            hasData = NO;
            break;
        }
    }
    
    if (hasData)
    {
        [[UserPrefs sharedInstance] removeOldSystemWideDetours:detoursNoLongerFound];
    }
    
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
        self.visibleDataArray = [NSMutableArray array];
        return;
    }
    
    if (!self.blockSort)
    {
        [self sortByStop];
        return;
    }
    
    self.visibleDataArray = [NSMutableArray array];
    
    [self.allDetours enumerateKeysAndObjectsUsingBlock: ^void (NSNumber* detourId, Detour* detour, BOOL *stop)
     {
         [detour.routes sortUsingComparator:^NSComparisonResult(Route *r1, Route *r2){
             return [r1 compare:r2];
         }];
         
         if (detour.systemWideFlag)
         {
             [self.visibleDataArray  addObject:detour];
         }
     }];
    
    int stop;
    int bus;
    int search;
    int insert;
    BOOL found;
    Departure *itemToInsert;
    Departure *firstItemForBus;
    Departure *existingItem;
    DepartureTimesByBus *busRoute;
    XMLDepartures *dep;
    
    for (stop = 0; stop < self.originalDataArray.count; stop++)
    {
        @autoreleasepool
        {
            dep = self.originalDataArray[stop];
            if (dep.gotData)
            {
                for (bus = 0; bus < dep.count; bus++)
                {
                    itemToInsert = dep[bus];
                    found = NO;
                    for (search = 0; search < self.visibleDataArray.count; search ++)
                    {
                        busRoute = self.visibleDataArray[search];
                        firstItemForBus = [busRoute depGetDeparture:0];
                        
                        if (itemToInsert.block !=nil && [firstItemForBus.block isEqualToString:itemToInsert.block])
                        {
                            for (insert = 0; insert < busRoute.departureItems.count; insert++)
                            {
                                existingItem = [busRoute depGetDeparture:insert];
                                
                                // existingItem is later in time than itemToInsert
                                if ([existingItem.departureTime compare:itemToInsert.departureTime] ==  NSOrderedDescending )
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
                    }
                }
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
            if (self.navigationItem.prompt == nil)
            {
                [self.navigationController setNavigationBarHidden:YES];
            }
            
            self.navigationItem.prompt = kCacheWarning;
            [self.navigationController setNavigationBarHidden:NO];
        }
        else
        {
            if (self.navigationItem.prompt != nil)
            {
                [self.navigationController setNavigationBarHidden:YES];
            }
            
            self.navigationItem.prompt = nil;
            [self.navigationController setNavigationBarHidden:NO];
        }
        
        XMLDepartures *item0 = self.originalDataArray.firstObject;
        
        if (item0 && [item0 depQueryTime] != nil)
        {
            [self updateRefreshDate:item0.depQueryTime];
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
    
    if (self.sectionExpanded == nil || self.sectionExpanded.count != self.visibleDataArray.count)
    {
        self.sectionExpanded = [NSMutableArray array];
        
        int stops = 0;
        int first = INT_MAX;
        
        // We count the stops - if there is one then that is expanded.
        
        for (int i=0; i< self.visibleDataArray.count; i++)
        {
            id<DepartureTimesDataProvider> dd = self.visibleDataArray[i];
            
            if (dd.depDetour==nil)
            {
                stops++;
                
                if (i<first)
                {
                    first = i;
                }
                
                if (stops > 1)
                {
                    break;
                }
            }
        }
        
        for (int i=0; i< self.visibleDataArray.count; i++)
        {
            self.sectionExpanded[i] = @NO;
        }
        
        if (stops == 1)
        {
            self.sectionExpanded[first] = @YES;
        }
    }
    
    SECTIONROWS *sr = self.sectionRows[section];
    
    if (sr[0].integerValue == kSectionRowInit)
    {
        bool expanded = !_blockSort && self.sectionExpanded[section].boolValue;
        id<DepartureTimesDataProvider> dd = self.visibleDataArray[section];
        
        int next = 0;
        
        // kSectionDistance
        if (dd.depDistance != nil)
        {
            next++;
        }
        sr[kSectionDistance] = @(next);
        
        // kSectionTitle
        if (dd.depGetSectionTitle != nil)
        {
            next++;
        }
        sr[kSectionTitle] = @(next);
        
        
        // kSectionTimes
        NSInteger itemCount = dd.depGetSafeItemCount;
        
        if (itemCount==0 && dd.depDetour==nil)
        {
            itemCount = 1;
        }
        
        next += itemCount;
        sr[kSectionTimes] = @(next);
        
        // kSectionDetours
        if (dd.depDetoursPerSection)
        {
            next+= dd.depDetoursPerSection.count;
        }
        sr[kSectionDetours] = @(next);
        
        // kSectionTrip
        if (dd.depLocation!=nil && expanded)
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
        if (dd.depLocation!=nil && expanded && [AlarmTaskList proximitySupported])
        {
            next++;
        }
        sr[kSectionProximity] = @(next);
        
        // kSectionNearby
        if (dd.depLocation!=nil && depthCount < kMaxDepth && expanded && [DepartureTimesView canGoDeeper])
        {
            next++;
        }
        sr[kSectionNearby] = @(next);
        
        // kSectionSiri
        if (@available(iOS 12.0, *))
        {
            if (dd.depLocation!=nil && depthCount < kMaxDepth && expanded && [DepartureTimesView canGoDeeper])
            {
                next++;
            }
        }
        sr[kSectionSiri] = @(next);
        
        // kSectionOneStop
        if (dd.depLocation!=nil && depthCount < kMaxDepth && expanded && self.visibleDataArray.count>1 && [DepartureTimesView canGoDeeper])
        {
            next++;
        }
        sr[kSectionOneStop] = @(next);
        
        
        // kSectionOpposite
        if (dd.depLocation!=nil && expanded && [DepartureTimesView canGoDeeper])
        {
            next++;
        }
        sr[kSectionOpposite] = @(next);
        
        
        // kSectionVehicle
        if (dd.depLocation!=nil && expanded && ([UserPrefs sharedInstance].vehicleLocations) && [DepartureTimesView canGoDeeper])
        {
            next++;
        }
        sr[kSectionVehicles] = @(next);
        
        
        
        // kSectionNoDeeper
        if (expanded && ![DepartureTimesView canGoDeeper])
        {
            next++;
        }
        sr[kSectionNoDeeper] = @(next);
        
        
        // kSectionStation
        if (expanded && dd.depLocId!=nil && [AllRailStationView railstationFromStopId:dd.depLocId]!=nil && [DepartureTimesView canGoDeeper])
        {
            next++;
        }
        sr[kSectionStation] = @(next);
        
        // kSectionInfo
        if (expanded && dd.depLocation!=nil)
        {
            next++;
        }
        sr[kSectionInfo] = @(next);
        
        // kSectionAccuracy
        if (expanded && [UserPrefs sharedInstance].showTransitTracker && dd.depLocation!=nil)
        {
            next++;
        }
        sr[kSectionAccuracy] = @(next);
            
        // kSectionStatic
        if (!dd.depDetour)
        {
            next++;
        }
        sr[kSectionStatic] = @(next);
        
        if (dd.depDetour)
        {
            next++;
        }
        sr[kSectionSystemAlert] = @(next);
        
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
//    printf("Old %d %d new %d %d\n",(int)indexPath.section,(int)indexPath.row, (int)newIndexPath.section, (int)newIndexPath.row);

    return newIndexPath;
}

#pragma mark Data fetchers

- (void)fetchTimesForVehicleStops:(NSString*)block task:(id<BackgroundTaskController>)task
{
    int items = 0;
    int batch = 0;
    int pos  = 0;
    bool found = false;
    bool done = false;
    
    @autoreleasepool {
    
        NSArray *batches = [XMLMultipleDepartures batchesFromEnumerator:self.vehicleStops selector:@selector(locid)  max:INT_MAX];
        
        while (batch < batches.count && items < MAX_STOPS && pos < self.vehicleStops.count && !done)
        {
            XMLMultipleDepartures *multiple = [XMLMultipleDepartures xmlWithOptions:DepOptionsFirstOnly];
            
            multiple.oneTimeDelegate = task;
            
            multiple.allDetours = self.allDetours;
            multiple.allRoutes = self.allRoutes;
            
            [task taskItemsDone:items+1];
            
            [multiple getDeparturesForLocations:batches[batch] block:block];
            
            if (multiple.gotData && multiple.count > 0)
            {
                for (XMLDepartures *dep in multiple)
                {
                    if (items < MAX_STOPS)
                    {
                        if (dep.gotData && dep.count > 0 && !(dep.items.firstObject.status!=kStatusEstimated && dep.items.firstObject.minsToArrival > 59))
                        {
                            [self.originalDataArray addObject:dep];
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
                    }
                    else
                    {
                        break;
                    }
                }
            }
            else
            {
                done = YES;
            }

            batch++;
            
            XML_DEBUG_RAW_DATA(multiple);
        }
    
    }
}


- (StopDistance *)fetchOtherDirectionForDeparture:(Departure*)dep items:(int*)items total:(int*)total task:(id<BackgroundTaskController>)task
{
    // Note - to autorelease pool as this is not a thread method
    XMLRoutes *xmlRoutes = [XMLRoutes xml];

    PC_ROUTE_INFO info = [TriMetInfo infoForRoute:dep.route];
    
    NSString *oppositeRoute = nil;
    NSString *oppositeDirection = nil;
    
    if (info && info->opposite != kNoDir && info->opposite!= kDir1)
    {
        oppositeRoute = [NSString stringWithFormat:@"%ld", (long)info->opposite];
        oppositeDirection = dep.dir;
        [task taskItemsDone:++(*items)];
    }
    else if (info && info->opposite == kDir1)
    {
        oppositeRoute = dep.route;
        
        if ([dep.dir isEqualToString:kKmlFirstDirection])
        {
            oppositeDirection = kKmlOptionalDirection;
        }
        else
        {
            oppositeDirection = kKmlFirstDirection;
        }
    }
    else
    {
        oppositeRoute = dep.route;
        
        [task taskSubtext:@"checking direction"];
        [xmlRoutes getDirections:oppositeRoute cacheAction:TrIMetXMLCacheReadOrFetch];
        if (xmlRoutes.itemFromCache)
        {

            [task taskTotalItems:--(*total)];
        }
        else
        {
            [task taskItemsDone:++(*items)];
        }
    
        // Find the first direction that isn't us
        if (xmlRoutes.count > 0)
        {
            Route *route = xmlRoutes.items.firstObject;
        
            for (NSString *routeDir in route.directions)
            {
                if (![routeDir isEqualToString:dep.dir])
                {
                    oppositeDirection = routeDir;
                }
            }
        }
    }
    
    XML_DEBUG_RAW_DATA(xmlRoutes);
    
    if (oppositeDirection)
    {
        NSString *otherLine = nil;
        NSArray *routes = nil;
        
        if (info && info->interlined_route != kNoRoute)
        {
            otherLine = [TriMetInfo interlinedRouteString:info];
        }
        
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
        
        [task taskSubtext:@"finding stop"];
        
        bool fetched = NO;
        
        for (NSString *foundRoute in routes)
        {
            XMLStops *stops = [[XMLStops alloc] init];
            [stops getStopsForRoute:foundRoute direction:oppositeDirection description:nil cacheAction:TrIMetXMLCacheReadOrFetch];
            fetched = fetched || (!stops.itemFromCache);
            
            if (stops.count >0)
            {
                for (Stop *stop in stops.items)
                {
                    CLLocation *there = [[CLLocation alloc] initWithLatitude:stop.lat.doubleValue longitude:stop.lng.doubleValue];
                    CLLocationDistance dist = [dep.stopLocation distanceFromLocation:there];
                    
                    if (dist < closest)
                    {
                        closest = dist;
                        closestStop = stop;
                    }
                    
                }
            }
            
            XML_DEBUG_RAW_DATA(stops);
        }
        
        if (fetched)
        {
            [task taskItemsDone:++(*items)];
        }
        else
        {
            [task taskTotalItems:--(*total)];
        }


        
        if (closestStop)
        {
            StopDistance *distance = [StopDistance data];
            
            distance.locid      = closestStop.locid;
            distance.desc       = closestStop.desc;
            distance.dir        = oppositeDirection;
            distance.distance   = closest;
            distance.accuracy   = 0;
            distance.location   = [CLLocation fromStringsLat:closestStop.lat lng:closestStop.lng];


            return distance;
        }
    }
    return nil;
}

- (void)fetchTimesForLocation:(NSString *)location
                        block:(NSString *)block
                        names:(NSArray *)names
                     bookmark:(NSString*)bookmark
                     opposite:(Departure*)findOpposite
                  oppositeAll:(XMLDepartures*)findOppositeAll
               taskController:(id<BackgroundTaskController>)task
{
    [task taskRunAsync:^{
        self.bookmarkDesc = bookmark;
        
        self.xml = [NSMutableArray array];
        
        NSString* loc = location;
        
        [self clearSections];
        [XMLDepartures clearCache];
        
        NSMutableArray *oppositeStops = nil;
        int total = 0;
        int items = 0;
        
        if (findOpposite)
        {
            total = 3;
            
            [task taskStartWithItems:total title:(bookmark!=nil?bookmark:kGettingArrivals)];
            StopDistance  * stop = [self fetchOtherDirectionForDeparture:findOpposite items:&items total:&total task:task];
            
            if (stop)
            {
                oppositeStops = @[stop].mutableCopy;
                loc = stop.locid;
            }
            
            total --;
        }
        else if (findOppositeAll)
        {
            NSMutableArray *uniqueRoutes = [NSMutableArray array];
            
            for (int i=0; i<findOppositeAll.count; i++)
            {
                Departure *dep = findOppositeAll[i];
                
                Departure * found = 0;
                
                for (Departure *d in uniqueRoutes)
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
            [task taskStartWithItems:total title:(bookmark!=nil?bookmark:kGettingArrivals)];
            
            oppositeStops = [NSMutableArray array];
            
            for (Departure *d in uniqueRoutes)
            {
                StopDistance* foundStop = [self fetchOtherDirectionForDeparture:d items:&items total:&total task:task];
                
                if (foundStop)
                {
                    for (int i=0; i<oppositeStops.count; i++)
                    {
                        StopDistance* stop = oppositeStops[i];
                        
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
            
            if (!task.taskCancelled)
            {
                loc = [NSString commaSeparatedStringFromEnumerator:oppositeStops selector:@selector(locid)];
            }
            total--;
        }
        else
        {
            total = 0;
            [task taskStartWithItems:1 title:(bookmark!=nil?bookmark:kGettingArrivals)];
        }
        
        self.stops = loc;
        int stopCount = 0;
        
        if (loc != nil)
        {
            NSArray *locList = loc.arrayFromCommaSeparatedString;
            
            total = (int)locList.count;
            
            if (total > 1)
            {
                NSInteger batches = kMultipleDepsBatches(locList.count);
                [task taskTotalItems:batches];
                NSInteger start = 0;
                
                for (int batch=0; batch<batches; batch++)
                {
                    XMLMultipleDepartures *multiple = [XMLMultipleDepartures xml];
                    multiple.oneTimeDelegate = task;
                    multiple.allDetours = self.allDetours;
                    multiple.allRoutes = self.allRoutes;
                    multiple.blockFilter = block;
                    
                    NSInteger batchSize = locList.count - start;
                    
                    if (batchSize > kMultipleDepsMaxStops)
                    {
                        batchSize = kMultipleDepsMaxStops;
                    }
                    
                    NSArray *batchLocs = [locList subarrayWithRange:NSMakeRange(start, batchSize)];
                    
                    [multiple getDeparturesForLocations:[NSString commaSeparatedStringFromEnumerator:batchLocs selector:@selector(self)]];
                    

                    for (XMLDepartures *deps in multiple)
                    {
                        [self.originalDataArray addObject:deps];
                        if (oppositeStops && stopCount < oppositeStops.count)
                        {
                            deps.distance = oppositeStops[stopCount];
                        }
                        stopCount++;
                    }
                    start+= kMultipleDepsMaxStops;
                    XML_DEBUG_RAW_DATA(multiple);
                    [task taskItemsDone:batch+1];
                    
                    
                }
            }
            else
            {
                
                [task taskTotalItems:total];
                
                int stopCount = 0;
                for (int i=0; i<locList.count && !task.taskCancelled; i++)
                {
                    XMLDepartures *deps = [XMLDepartures xml];
                    deps.allDetours = self.allDetours;
                    deps.allRoutes  = self.allRoutes;
                    [self.originalDataArray addObject:deps];
                    deps.blockFilter = block;
                    NSString *aLoc = locList[i];
                    
                    
                    if (names == nil || stopCount > names.count)
                    {
                        [task taskSubtext:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), aLoc]];
                    }
                    else
                    {
                        [task taskSubtext:names[stopCount]];
                    }
                    deps.oneTimeDelegate = task;
                    [deps getDeparturesForLocation:aLoc];
                    
                    if (oppositeStops && stopCount < oppositeStops.count)
                    {
                        deps.distance = oppositeStops[stopCount];
                    }
                    
                    stopCount++;
                    items ++;
                    
                    XML_DEBUG_RAW_DATA(deps);

                    [task taskItemsDone:items];
                    
                }
            }
            
            if (self.originalDataArray.count > 0)
            {
                if (block!=nil)
                {
                    self.title = NSLocalizedString(@"Track Trip", @"screen title");
                    self->_blockFilter = true;
                }
                else
                {
                    self->_blockFilter = false;
                }
                [self sortByBus];
                // [[(MainTableViewController *)[self.navigationController topViewController] tableView] reloadData];
                // return YES;
            }
            
            
            if (!task.taskCancelled)
            {
                [self->_userData setLastArrivals:loc];
                
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
                    [self->_userData setLastNames:names];
                }
                else
                {
                    [self->_userData setLastNames:nil];
                }
            }
            
        }
        else if (findOpposite || findOppositeAll)
        {
            [task taskCancel];
            [task taskSetErrorMsg:@"Could not find a stop going the other way."];
        }
        
        return self;
    }];
    
}

- (void)fetchAgainAsync:(id<BackgroundTaskController>)task 
{
    
    
    if (self.vehicleStops)
    {
        [task taskRunAsync:^{
            self.backgroundRefresh = YES;
            
            [self clearSections];
            self.xml = [NSMutableArray array];
            
        
            [task taskStartWithItems:1 title:kGettingArrivals];
            
            XMLDepartures *dd = self.originalDataArray.firstObject;
        
            NSString *block = dd.blockFilter;
            
            [self.originalDataArray removeAllObjects];
            [self.allDetours removeAllObjects];
            
            [self fetchTimesForVehicleStops:block task:task];
            
            self->_blockFilter = true;
            self.blockSort = YES;
            self.allowSort = YES;
            
            [self sortByBus];
            [self clearSections];
            
            return (UIViewController*)nil;
        }];
    }
    else
    {
        [task taskRunAsync:^{

            self.backgroundRefresh = YES;
            
            int i=0;
            
            [self clearSections];
            
            // [self.allDetours removeAllObjects];
            
            self.xml = [NSMutableArray array];
            
            if (self.originalDataArray.count >1)
            {
                int batches =  kMultipleDepsBatches(self.originalDataArray.count); 
                [task taskStartWithItems:batches title:kGettingArrivals];
                int start = 0;
                
                for (int batch=0; batch<batches; batch++)
                {
                    int intbatch = 0;
                    XMLMultipleDepartures *multiple = [XMLMultipleDepartures xml];
                    multiple.oneTimeDelegate = task;
                    multiple.allDetours = self.allDetours;
                    multiple.allRoutes  = self.allRoutes;
                    multiple.blockFilter = self.originalDataArray.firstObject.blockFilter;
                    
                    for (i=start; i< self.originalDataArray.count && !task.taskCancelled && intbatch < kMultipleDepsMaxStops; i++)
                    {
                        XMLDepartures *dd = self.originalDataArray[i];
                        
                        if (dd.locid)
                        {
                            multiple.stops[dd.locid] = dd;
                            intbatch++;
                        }
                    }
                    [multiple reload];
                    
                    start+= kMultipleDepsMaxStops;
                    
                    XML_DEBUG_RAW_DATA(multiple);
                    [task taskItemsDone:batch+1];
                }
            }
            else
            {
                [task taskStartWithItems:self.originalDataArray.count title:kGettingArrivals];
                
                for (i=0; i< self.originalDataArray.count && !task.taskCancelled; i++)
                {
                    XMLDepartures *dd = self.originalDataArray[i];
                    if (dd.locDesc !=nil)
                    {
                        [task taskSubtext:dd.locDesc];
                    }
                    dd.oneTimeDelegate = task;
                    [dd reload];
                    
                    XML_DEBUG_RAW_DATA(dd);
                    
                    [task taskItemsDone:i+1];
                }
            }
            [self sortByBus];
            [self clearSections];
            
            return (UIViewController*)nil;
            
        }];
    }
}

- (void)fetchTimesForLocationAsync:(id<BackgroundTaskController>)task loc:(NSString*)loc block:(NSString *)block
{
    [self fetchTimesForLocation:loc
                          block:block
                          names:nil
                       bookmark:nil
                       opposite:nil
                    oppositeAll:nil
                 taskController:task];
}

- (void)fetchTimesForVehicleAsync:(id<BackgroundTaskController>)task vehicleId:(NSString *)vehicleId
{
    [self fetchTimesForVehicleAsync:task route:nil direction:nil nextLoc:nil block:nil targetDeparture:nil vehicleId:vehicleId];
}

- (void)fetchTimesForVehicleAsync:(id<BackgroundTaskController>)task route:(NSString *)route direction:(NSString *)direction nextLoc:(NSString*)loc block:(NSString *)block targetDeparture:(Departure *)targetDep
{
    [self fetchTimesForVehicleAsync:task route:route direction:direction nextLoc:loc block:block targetDeparture:targetDep vehicleId:nil];
}

- (void)fetchTimesForVehicleAsync:(id<BackgroundTaskController>)task
                            route:(NSString *)route1
                        direction:(NSString *)direction1
                          nextLoc:(NSString*)loc1
                            block:(NSString *)block1
                  targetDeparture:(Departure *)targetDep
                        vehicleId:(NSString*)vehicleId
{
    [task taskRunAsync:^{
        NSString *localRoute = route1;
        NSString *localDirection = direction1;
        NSString *localLoc = loc1;
        NSString *localBlock = block1;
        
        int items = 2;
        int done = 0;
        
        if (vehicleId!=nil)
        {
            items = 3;
            [task taskStartWithItems:items title:kGettingArrivals];
            XMLLocateVehicles *locator = [XMLLocateVehicles xml];
            
            locator.dist = 0.0;
            
            [locator findNearestVehicles:nil direction:nil blocks:nil vehicles:[NSSet setWithObject:vehicleId]];
            [task taskItemsDone:++done];
            
            if (locator.gotData && locator.items.count>0)
            {
                for (Vehicle *vehicle in locator)
                {
                    if ([vehicle.vehicleID isEqualToString:vehicleId])
                    {
                        localBlock = vehicle.block;
                        localLoc = vehicle.nextLocID;
                        localDirection = vehicle.direction;
                        localRoute = vehicle.routeNumber;
                        break;
                    }
                }
            }
        }
        
        
        if (!localBlock && targetDep!=nil)
        {
            localBlock = targetDep.block;
        }
        
        if (!localBlock && targetDep == nil)
        {
            [task taskSetErrorMsg: NSLocalizedString(@"Vehicle not found, it may not be currently in service.  Note, Streetcar is not supported.", @"error text")];
            [task taskCancel];
            return self;
        }
        else
        {
            
            [self clearSections];
            [XMLDepartures clearCache];
            self.xml = [NSMutableArray array];
            
            XMLStops * stops = [XMLStops xml];
            
            // Get Route info
            if ((targetDep==nil || targetDep.trips== nil || targetDep.trips.count == 0) && localLoc!=nil)
            {
                stops.oneTimeDelegate = task;
                [stops getStopsAfterLocation:localLoc route:localRoute direction:localDirection description:@"" cacheAction:TriMetXMLForceFetchAndUpdateCache];
                
                XML_DEBUG_RAW_DATA(stops);
                [task taskItemsDone:++done];
            }
            else if (targetDep.nextLocid!=nil)
            {
                [task taskStartWithItems:1+targetDep.trips.count  title:kGettingArrivals];
                
                stops.items = [NSMutableArray array];
                
                int items = 0;
                for (DepartureTrip *trip in targetDep.trips)
                {
                    XMLStops *tripStops = [XMLStops xml];
                    tripStops.oneTimeDelegate = task;
                    
                    if (items==0)
                    {
                        [tripStops getStopsAfterLocation:targetDep.nextLocid route:trip.route direction:trip.dir description:@"" cacheAction:TrIMetXMLCacheReadOrFetch];
                    }
                    else
                    {
                        [tripStops getStopsForRoute:trip.route direction:trip.dir description:@"" cacheAction:TrIMetXMLCacheReadOrFetch];
                    }
                    
                    if (stops.items.count > 0 && tripStops.items.count > 0 && [stops.items.lastObject.locid isEqualToString:tripStops.items.firstObject.locid])
                    {
                        [stops.items removeLastObject];
                    }
                    
                    [stops.items addObjectsFromArray:tripStops.items];
                    
                    XML_DEBUG_RAW_DATA(tripStops);
                    items++;
                    [task taskItemsDone:items];
                }
            }
            
            if (stops.gotData || stops.items.count >0)
            {
                self.vehicleStops = stops.items;
                [self fetchTimesForVehicleStops:localBlock task:task];
            }
            else
            {
                [task taskCancel];
                [task taskSetErrorMsg:NSLocalizedString(@"Could not find any departures for that vehicle.", @"error message")];
            }
            
            if (self.originalDataArray.count == 0)
            {
                [task taskCancel];
                [task taskSetErrorMsg:NSLocalizedString(@"Could not find any departures for that vehicle.", @"error message")];
            }
            
            self->_blockFilter = true;
            self.blockSort = YES;
            
            [self sortByBus];
            
            self.allowSort = YES;
            
            
            
            if (!task.taskCancelled)
            {
                [self->_userData setLastArrivals:localLoc];
                
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
                    [self->_userData setLastNames:names];
                }
                else {
                    [self->_userData setLastNames:nil];
                }
                
            }
            return self;
        }
        
    }];
    
}


- (void)fetchTimesForNearestStopsAsync:(id<BackgroundTaskController>)task location:(CLLocation *)here maxToFind:(int)max minDistance:(double)min mode:(TripMode)mode
{
    [task taskRunAsync:^{
        XMLLocateStops *locator = [XMLLocateStops xml];
        
        locator.maxToFind = max;
        locator.location = here;
        locator.mode = mode;
        locator.minDistance = min;
        
        [self clearSections];
        [XMLDepartures clearCache];
        self.xml = [NSMutableArray array];
        
        [task taskStartWithItems:kMultipleDepsBatches(locator.maxToFind)+1 title:kGettingArrivals];
        
        [task taskSubtext:NSLocalizedString(@"getting locations", @"progress message")];
        locator.oneTimeDelegate = task;
        [locator findNearestStops];
        
        [task taskItemsDone:1];
        
        if (![locator displayErrorIfNoneFound:task])
        {
            NSMutableString * stopsstr = [NSMutableString string];
            self.stops = stopsstr;
            int i = 0;
            
            NSArray *batches = [XMLMultipleDepartures batchesFromEnumerator:locator selector:@selector(locid) max:locator.maxToFind];
            
            [task taskTotalItems:batches.count+1];
            
            for (int batch = 0; batch < batches.count && !task.taskCancelled; batch++)
            {
                XMLMultipleDepartures *multiple = [XMLMultipleDepartures xml];
                multiple.oneTimeDelegate = task;
                multiple.allDetours = self.allDetours;
                multiple.allRoutes  = self.allRoutes;
                
                [multiple getDeparturesForLocations:batches[batch]];
                
                if (batch==0)
                {
                    [stopsstr appendFormat:@"%@",batches[batch]];
                }
                else
                {
                    [stopsstr appendFormat:@",%@",batches[batch]];
                }
                
                for (XMLDepartures *deps in multiple)
                {
                    deps.distance = locator[i];
                    i++;
                    [self.originalDataArray addObject:deps];
                }
                XML_DEBUG_RAW_DATA(multiple);
                [task taskItemsDone:batch+2];
            }
            
            if (self.originalDataArray.count > 0)
            {
                self->_blockFilter = false;
                [self sortByBus];
            }
        }
        
        return self;
    }];
}


- (void)fetchTimesForStopInOtherDirectionAsync:(id<BackgroundTaskController>)task departure:(Departure*)dep
{
    [self fetchTimesForLocation:nil
                          block:nil
                          names:nil
                       bookmark:nil
                       opposite:dep
                    oppositeAll:nil
                 taskController:task];
}

- (void)fetchTimesForStopInOtherDirectionAsync:(id<BackgroundTaskController>)task departures:(XMLDepartures*)deps
{
    [self fetchTimesForLocation:nil
                          block:nil
                          names:nil
                       bookmark:nil
                       opposite:nil
                    oppositeAll:deps
                 taskController:task];
}

- (void)fetchTimesForNearestStopsAsync:(id<BackgroundTaskController>)task stops:(NSArray<StopDistance*>*)stops
{
    [task taskRunAsync:^{
        [self clearSections];
        [XMLDepartures clearCache];
        self.xml = [NSMutableArray array];
        
        NSMutableString * stopsstr = [NSMutableString string];
        self.stops = stopsstr;
        int i=0;
        NSArray *batches = [XMLMultipleDepartures batchesFromEnumerator:stops selector:@selector(locid) max:INT_MAX];
        
        [task taskStartWithItems:batches.count+1 title:kGettingArrivals];
        
        
        for (int batch = 0; batch < batches.count && !task.taskCancelled; batch++)
        {
            XMLMultipleDepartures *multiple = [XMLMultipleDepartures xml];
            multiple.oneTimeDelegate = task;
            multiple.allDetours = self.allDetours;
            multiple.allRoutes  = self.allRoutes;
            
            [multiple getDeparturesForLocations:batches[batch]];
            
            
            for (XMLDepartures *deps in multiple)
            {
                StopDistance *sd = stops[i];
                deps.distance = sd;
                
                if (i==0)
                {
                    [stopsstr appendFormat:@"%@",sd.locid];
                }
                else
                {
                    [stopsstr appendFormat:@",%@",sd.locid];
                }
                
                i++;
                [self.originalDataArray addObject:deps];
            }
            XML_DEBUG_RAW_DATA(multiple);
            [task taskItemsDone:batch+2];
        }
        
        if (self.originalDataArray.count > 0)
        {
            self->_blockFilter = false;
            [self sortByBus];
        }
        return (UIViewController*)self;
    }];
}

- (void)fetchTimesForLocationAsync:(id<BackgroundTaskController>)task loc:(NSString*)loc names:(NSArray *)names
{
    [self fetchTimesForLocation:loc
                          block:nil
                          names:names
                       bookmark:nil
                       opposite:nil
                    oppositeAll:nil
                 taskController:task];
}

- (void)fetchTimesForLocationAsync:(id<BackgroundTaskController>)task loc:(NSString*)loc
{
    [self fetchTimesForLocation:loc
                          block:nil
                          names:nil
                       bookmark:nil
                       opposite:nil
                    oppositeAll:nil
                 taskController:task];
}

- (void)fetchTimesForLocationAsync:(id<BackgroundTaskController>)task loc:(NSString*)loc title:(NSString *)title
{
    [self fetchTimesForLocation:loc
                          block:nil
                          names:nil
                       bookmark:title
                       opposite:nil
                    oppositeAll:nil
                 taskController:task];
}

- (void)fetchTimesForBlockAsync:(id<BackgroundTaskController>)task block:(NSString*)block start:(NSString*)start stop:(NSString*) stop
{
    [task taskRunAsync:^{
        [task taskStartWithItems:2 title:kGettingArrivals];
        
        [self clearSections];
        [XMLDepartures clearCache];
        self.xml = [NSMutableArray array];
    
        XMLDepartures *deps = [XMLDepartures xml];
        deps.allDetours = self.allDetours;
        deps.allRoutes  = self.allRoutes;
        
        [self.originalDataArray addObject:deps];
        deps.blockFilter = block;
        [task taskSubtext:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), start]];
        deps.oneTimeDelegate = task;
        [deps getDeparturesForLocation:start];
        deps.sectionTitle = NSLocalizedString(@"Departure", @"");
        
        XML_DEBUG_RAW_DATA(deps);
        
        [task taskItemsDone:1];
        
        if(!task.taskCancelled)
        {
            deps = [XMLDepartures xml];
            
            [self.originalDataArray addObject:deps];
            deps.blockFilter = block;
            [task taskSubtext:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), stop]];
            deps.oneTimeDelegate = task;
            [deps getDeparturesForLocation:stop];
            deps.sectionTitle = NSLocalizedString(@"Departure", @"");
            [task taskItemsDone:2];
        }
        
        self->_blockFilter = true;
        
        dispatch_async(dispatch_get_main_queue(),^{
            self.title = NSLocalizedString(@"Trip", @"");
        });
        
        [self sortByBus];

        return self;
    }];
}

- (void)fetchTimesViaQrCodeRedirectAsync:(id<BackgroundTaskController>)task URL:(NSString*)url
{
    [task taskRunAsync:^{
        [task taskStartWithItems:2 title:kGettingArrivals];
        
        [task taskSubtext:NSLocalizedString(@"getting stop ID", @"progress message")];
        
        ProcessQRCodeString *qrCode = [[ProcessQRCodeString alloc] init];
        NSString *stopId = [qrCode extractStopId:url];
        
        [task taskItemsDone:1];
        
        [self clearSections];
        [XMLDepartures clearCache];
        self.stops = stopId;
        self.xml = [NSMutableArray array];
        
        static NSString *streetcar = @"www.portlandstreetcar.org";
        
        if (!task.taskCancelled && stopId)
        {
            XMLDepartures *deps = [XMLDepartures xml];
            deps.allDetours = self.allDetours;
            deps.allRoutes  = self.allRoutes;
            
            [self.originalDataArray addObject:deps];
            [task taskSubtext:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), stopId]];
            deps.oneTimeDelegate = task;
            [deps getDeparturesForLocation:stopId];
            XML_DEBUG_RAW_DATA(deps);
            [task taskItemsDone:2];
        }
        else if (url.length >= streetcar.length && [[url substringToIndex:streetcar.length] isEqualToString:streetcar])
        {
            [task taskCancel];
            [task taskSetErrorMsg:NSLocalizedString(@"That QR Code is for the Portland Streetcar web site - there should be another QR code close by that has the stop ID.",
                                                                                              @"error message")];
        }
        else
        {
            [task taskCancel];
            [task taskSetErrorMsg:NSLocalizedString(@"The QR Code is not for a TriMet stop.", @"error message")];
        }
        
        self->_blockFilter = false;
        [self sortByBus];
        return (UIViewController *)self;
    }];
}






#pragma mark UI Helper functions


- (UITableViewCell *)distanceCellWithReuseIdentifier:(NSString *)identifier
{
    CGRect rect;
    
    UITableViewCell *cell = [self tableView:self.table cellWithReuseIdentifier:identifier];
    
#define LEFT_COLUMN_OFFSET 10.0
#define LEFT_COLUMN_WIDTH 260
    
#define MAIN_FONT_SIZE 16.0
#define LABEL_HEIGHT 26.0
    
    if ([cell viewWithTag:DISTANCE_TAG] == nil)
    {
        /*
         Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
         */
        UILabel *label;
        
        rect = CGRectMake(LEFT_COLUMN_OFFSET, (kDepartureCellHeight/2.0 - LABEL_HEIGHT) / 2.0, LEFT_COLUMN_WIDTH, LABEL_HEIGHT);
        label = [[UILabel alloc] initWithFrame:rect];
        label.tag = DISTANCE_TAG;
        label.font = [UIFont boldSystemFontOfSize:MAIN_FONT_SIZE];
        label.adjustsFontSizeToFitWidth = YES;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        [cell.contentView addSubview:label];
        label.highlightedTextColor = [UIColor whiteColor];
        label.textColor  = [UIColor modeAwareBlue];
        
        
        rect = CGRectMake(LEFT_COLUMN_OFFSET, kDepartureCellHeight/2.0 + (kDepartureCellHeight/2.0 - LABEL_HEIGHT) / 2.0, LEFT_COLUMN_WIDTH, LABEL_HEIGHT);
        label = [[UILabel alloc] initWithFrame:rect];
        label.tag = ACCURACY_TAG;
        label.font = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
        label.adjustsFontSizeToFitWidth = YES;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        [cell.contentView addSubview:label];
        label.highlightedTextColor = [UIColor whiteColor];
        label.textColor  = [UIColor modeAwareBlue];
        
    }
    return cell;
}



#pragma mark UI Callback methods


- (void)detailsChanged
{
    _reloadWhenAppears = YES;
}

- (void)refreshAction:(id)sender
{
    if (!self.backgroundTask.running)
    {
        [super refreshAction:sender];
    
        if (self.table.hidden || self.backgroundTask.progressModal !=nil)
        {
            return;
        }
    
        DEBUG_LOG(@"Refreshing\n");
    
        [self fetchAgainAsync:self.backgroundTask];
    }
}


-(bool)needtoFetchStreetcarLocations:(NSArray<XMLDepartures*>*)deps
{
    for (XMLDepartures* dep in deps)
    {
        if (dep.loc !=nil)
        {
            for (int j=0; j< dep.count; j++)
            {
                Departure *dd = dep[j];
            
                if (dd.streetcar && dd.blockPosition == nil)
                {
                    return YES;
                    break;
                }
            }
        }
    }
    return NO;
}


- (void)fetchStreetcarLocations:(id<BackgroundTaskController>)task
{
    int i=0;
    
    NSSet<NSString*> *streetcarRoutes = [XMLStreetcarLocations getStreetcarRoutesInDepartureArray:self.originalDataArray];
    
    
    for (XMLDepartures *dep in self.originalDataArray)
    {
        // First get the arrivals via next bus to see if we can get the correct vehicle ID
        XMLStreetcarPredictions *streetcarArrivals = [[XMLStreetcarPredictions alloc] init];
        streetcarArrivals.oneTimeDelegate = task;
        
        [streetcarArrivals getDeparturesForLocation:[NSString stringWithFormat:@"predictions&a=portland-sc&stopId=%@",dep.locid]];
        
        for (NSInteger i=0; i< streetcarArrivals.count; i++)
        {
            Departure *vehicle = streetcarArrivals[i];
            
            for (Departure *dd in dep.items)
                
                if ([vehicle.block isEqualToString:dd.block])
                {
                    dd.streetcarId = vehicle.streetcarId;
                    dd.vehicleIDs = [vehicle vehicleIdsForStreetcar];
                    break;
                }
        }
        
        
        [task taskItemsDone:++i];
    }
    
    for (NSString *route in streetcarRoutes)
    {
        XMLStreetcarLocations *locs = [XMLStreetcarLocations sharedInstanceForRoute:route];
        locs.oneTimeDelegate = task;
        [locs getLocations];
        XML_DEBUG_RAW_DATA(locs);
        [task taskItemsDone:++i];
    }
    
    [XMLStreetcarLocations insertLocationsIntoDepartureArray:self.originalDataArray forRoutes:streetcarRoutes];
}


-(void)showMapNow:(id)sender
{
    MapViewWithRoutes *mapPage = [MapViewWithRoutes viewController];
    mapPage.callback = self.callback;
    bool needStreetcarLocations = NO;
    NSInteger additonalTasks = 1;
    
    if (_blockFilter)
    {
        mapPage.title = NSLocalizedString(@"Stops & Departures", @"screen title");
        
        needStreetcarLocations = [self needtoFetchStreetcarLocations:self.originalDataArray];
        
        if (needStreetcarLocations)
        {
            NSSet<NSString*> *streetcarRoutes = [XMLStreetcarLocations getStreetcarRoutesInDepartureArray:self.originalDataArray];
            additonalTasks = 1 + streetcarRoutes.count+((int)self.originalDataArray.count * (int)streetcarRoutes.count);
        }
    }
    else
    {
        mapPage.title = NSLocalizedString(@"Stops", @"screen title");
    }
    
    __weak NSMutableArray *routes = [NSMutableArray array];
    __weak NSMutableArray *directions = [NSMutableArray array];
    
    [mapPage fetchRoutesAsync:self.backgroundTask
                       routes:routes
                   directions:directions
              additionalTasks:additonalTasks
                         task:^(id<BackgroundTaskController> background){
                             if (needStreetcarLocations)
                             {
                                 [self fetchStreetcarLocations:background];
                             }
                             long i,j;
                             
                             NSMutableSet *blocks = [NSMutableSet set];
                             
                             bool found = NO;
                             
                             for (i=self.originalDataArray.count-1; i>=0 ; i--)
                             {
                                 XMLDepartures * dep   = self.originalDataArray[i];
                                 
                                 if (dep.loc !=nil)
                                 {
                                     [mapPage addPin:dep];
                                     
                                     if (self->_blockFilter)
                                     {
                                         for (j=0; j< dep.count; j++)
                                         {
                                             Departure *dd = dep[j];
                                             
                                             if (dd.hasBlock && ![blocks containsObject:dd.block] && dd.blockPosition!=nil)
                                             {
                                                 [mapPage addPin:dd];
                                                 [blocks addObject:dd.block];
                                             }
                                             
                                             if (dd.hasBlock && dd.blockPosition!=nil)
                                             {
                                                 found = NO;
                                                 for (int i=0; i<routes.count; i++)
                                                 {
                                                     if ([routes[i] isEqualToString:dd.route]
                                                         && [directions[i] isEqualToString:dd.dir])
                                                     {
                                                         found = YES;
                                                         break;
                                                     }
                                                 }
                                                 
                                                 if (!found)
                                                 {
                                                     [routes addObject:dd.route];
                                                     [directions addObject:dd.dir];
                                                 }
                                             }
            
                                         }
                                     }
                                 }
                             }
                         }];

}

-(bool)needtoFetchStreetcarLocationsForStop:(XMLDepartures*)dep
{
    bool needToFetchStreetcarLocations = false;
    
    if (dep.loc !=nil)
    {
        for (int j=0; j< dep.count; j++)
        {
            Departure *dd = dep[j];
            
            if (dd.streetcar && dd.blockPosition == nil)
            {
                needToFetchStreetcarLocations = true;
                break;
            }
        }
    }
    
    return needToFetchStreetcarLocations;
}


-(void)showMap:(id)sender
{
    [self showMapNow:nil];
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
        if ([self validStopDataProvider:dd])
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
        if (@available(iOS 12.0, *))
        {
            [alert addAction:[UIAlertAction actionWithTitle:kAddBookmarkToSiri
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action){
                                                        [self addBookmarkToSiri];
                                                    }]];
        }
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
                                                    [self->_userData.faves removeObjectAtIndex:bookmarkItem];
                                                    [self favesChanged];
                                                    [self->_userData cacheAppData];
                                                }]];
        
        
        if (@available(iOS 12.0, *))
        {
            [alert addAction:[UIAlertAction actionWithTitle:kAddBookmarkToSiri
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action){
                                                        [self addBookmarkToSiri];
                                                    }]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Edit this bookmark", @"button text")
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action){
                                                    EditBookMarkView *edit = [EditBookMarkView viewController];
                                                    @synchronized (self->_userData)
                                                    {
                                                        [edit editBookMark:self->_userData.faves[bookmarkItem] item:bookmarkItem];
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
            if (dd.depGetSafeItemCount==0 && newIndexPath.row == 0 && !_blockFilter )
            {
                result = kNonDepartureHeight;
            }
            else
            {
                result = DEPARTURE_CELL_HEIGHT;
            }
            break;
        case kSectionDetours:
            return UITableViewAutomaticDimension;
        case kSectionStatic:
            return kDisclaimerCellHeight;
        case kSectionSystemAlert:
            return UITableViewAutomaticDimension;
        case kSectionTitle:
            return [self narrowRowHeight];
        case kSectionNearby:
        case kSectionSiri:
        case kSectionProximity:
        case kSectionTrip:
        case kSectionOneStop:
        case kSectionInfo:
        case kSectionStation:
        case kSectionOpposite:
        case kSectionVehicles:
        case kSectionNoDeeper:
            return [self narrowRowHeight];
        case kSectionAccuracy:
            return [self narrowRowHeight];
        case kSectionDistance:
            if (dd.depDistance.accuracy > 0.0)
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
    
    if ([self validStop:section] && !_blockSort)
    {
        id<DepartureTimesDataProvider> dd = self.visibleDataArray[section];
        [_userData addToRecentsWithLocation:dd.depLocId
                                description:dd.depGetSectionHeader];
    }
    
    //DEBUG_LOG(@"Section: %ld rows %ld expanded %d\n", (long)section, (long)sr->row[kSectionsPerStop-1],
    //          (int)_sectionExpanded[section]);

    
    return sr[kSectionsPerStop-1].integerValue;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id<DepartureTimesDataProvider> dd = self.visibleDataArray[section];
    return dd.depGetSectionHeader;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell.reuseIdentifier isEqualToString:kActionCellId])
    {
        // cell.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        
        cell.backgroundColor = [UIColor modeAwareCellBackground];
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
    header.accessibilityLabel = header.textLabel.text.phonetic;
}

- (UITableViewCell *)actionCell:(UITableView *)tableView
                         image:(UIImage*)image
                          text:(NSString*)text
                     accessory:(UITableViewCellAccessoryType)accType
{
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:kActionCellId];
    cell.textLabel.font = self.basicFont;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.textLabel.textColor = [UIColor grayColor];
    cell.imageView.image = image;
    cell.textLabel.text = text;
    cell.accessoryType = accType;
    [self updateAccessibility:cell];
    
    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    id<DepartureTimesDataProvider> dd = self.visibleDataArray[indexPath.section];
    NSIndexPath * newIndexPath = [self subsection:indexPath];
    
    switch (newIndexPath.section)
    {
        case kSectionSystemAlert:
        {
            Detour *detour = dd.depDetour;
            
            cell = [self tableView:tableView multiLineCellWithReuseIdentifier:detour.reuseIdentifer];
            
            [detour populateCell:cell font:self.paragraphFont routeDisclosure:YES];
            [self addDetourButtons:detour cell:cell routeDisclosure:YES];
            break;
        }
        case kSectionDistance:
        {
            bool twoLines = (dd.depDistance.accuracy > 0.0);
            if (twoLines)
            {
                cell = [self distanceCellWithReuseIdentifier:kDistanceCellId2];
                
                NSString *distance = [NSString stringWithFormat:NSLocalizedString(@"Distance %@", @"stop distance"), [FormatDistance formatMetres:dd.depDistance.distance]];
                ((UILabel*)[cell.contentView viewWithTag:DISTANCE_TAG]).text = distance;
                UILabel *accuracy = (UILabel*)[cell.contentView viewWithTag:ACCURACY_TAG];
                accuracy.text = [NSString stringWithFormat:NSLocalizedString(@"Accuracy +/- %@", @"accuracy of location services"), [FormatDistance formatMetres:dd.depDistance.accuracy]];
                cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", distance, accuracy.text];
                
            }
            else
            {
                cell = [self tableView:tableView cellWithReuseIdentifier:kDistanceCellId];
        
                cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Distance %@", @"stop distance"), [FormatDistance formatMetres:dd.depDistance.distance]];
                cell.textLabel.textColor = [UIColor modeAwareBlue];
                cell.textLabel.font = self.basicFont;;
                cell.accessibilityLabel = cell.textLabel.text;
                
            }
            cell.imageView.image = nil;
            break;
        }
        case kSectionTimes:
        {
            int i = (int)newIndexPath.row;
            NSInteger deps = dd.depGetSafeItemCount;
            if (deps ==0 && i == 0)
            {
                cell = [self tableView:tableView cellWithReuseIdentifier:kStatusCellId];
            
                if (_blockFilter)
                {
                    cell.textLabel.text = NSLocalizedString(@"No departure data for that particular trip.", @"error message");
                    cell.textLabel.adjustsFontSizeToFitWidth = NO;
                    cell.textLabel.numberOfLines = 0;
                    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
                    cell.textLabel.font = self.paragraphFont;
                    
                }
                else
                {
                    cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"(ID %@) No departures found.", @"No departures for a specific TriMet stop ID"), dd.depLocId];
                    cell.textLabel.font = self.basicFont;
                    
                }
                cell.accessoryType = UITableViewCellAccessoryNone;
                
                [self updateAccessibility:cell];
                break;
            }
            else
            {
                Departure *departure = [dd depGetDeparture:newIndexPath.row];
                DepartureCell *dcell = [DepartureCell tableView:tableView cellWithReuseIdentifier:MakeCellId(kSectionTimes)];
                
                [dd depPopulateCell:departure cell:dcell decorate:YES wide:LARGE_SCREEN];
                // [departure populateCell:cell decorate:YES big:YES];
                
                cell = dcell;
            }
            cell.imageView.image = nil;
            break;
        }
        case kSectionDetours:
        {
            NSInteger i = newIndexPath.row;
            NSNumber *detourId = dd.depDetoursPerSection[i];
            Detour *det = self.allDetours[detourId];
            
            if (det!=nil)
            {
                cell = [self tableView:tableView multiLineCellWithReuseIdentifier:det.reuseIdentifer];
                NSString *text = det.formattedDescriptionWithoutInfo;
                cell.textLabel.attributedText = [text formatAttributedStringWithFont:self.paragraphFont];
                cell.textLabel.accessibilityLabel = text.removeFormatting.phonetic;
                [self addDetourButtons:det cell:cell routeDisclosure:NO];
            }
            else
            {
                cell = [self tableView:tableView multiLineCellWithReuseIdentifier:det.reuseIdentifer];
                NSString *text = @"#D#RThe detour description is missing. ☹️";
                cell.textLabel.attributedText = [text formatAttributedStringWithFont:self.paragraphFont];
                cell.textLabel.accessibilityLabel = text.removeFormatting.phonetic;
                cell.accessoryView = nil;
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            break;
        }
        case kSectionStatic:
            if (newIndexPath.row==0)
            {
                cell = [self disclaimerCell:tableView];
                
                if (dd.depNetworkError)
                {
                    if (dd.depNetworkErrorMsg)
                    {
                        [self addTextToDisclaimerCell:cell
                                                 text:kNetworkMsg];
                    }
                    else {
                        [self addTextToDisclaimerCell:cell text:
                         [NSString stringWithFormat:kNoNetworkID, dd.depLocId]];
                    }
                    
                }
                else if ([self validStop:indexPath.section])
                {
                    [self addTextToDisclaimerCell:cell text:[NSString stringWithFormat:NSLocalizedString(@"%@ Updated: %@", @"text followed by time data was fetched"),
                                                             dd.depStaticText,
                                                             [NSDateFormatter localizedStringFromDate:dd.depQueryTime
                                                                                            dateStyle:NSDateFormatterNoStyle
                                                                                            timeStyle:NSDateFormatterMediumStyle]]];
                }
                else
                {
                    [self addTextToDisclaimerCell:cell text:@""];
                }
                
                
                if (dd.depNetworkError)
                {
                    cell.accessoryView = nil;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                }
                else if (dd.depHasDetails)
                {
                    UIButton *button = [[UIButton alloc] init];
                    button.frame = CGRectMake(0,0, ACCESSORY_BUTTON_SIZE, ACCESSORY_BUTTON_SIZE);
                    
                    [button setImage:(self.sectionExpanded[indexPath.section].boolValue
                                      ? [self getModeAwareIcon:kIconCollapse7]
                                      : [self getModeAwareIcon:kIconExpand7]) forState:UIControlStateNormal];
                    // button.userInteractionEnabled = NO;
                    cell.accessoryView = button;
                   
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
                
                for (int i=0; i< dd.depGetSafeItemCount && streetcarDisclaimer==nil; i++)
                {
                    dep = [dd depGetDeparture:i];
                    
                    if (dep.streetcar && dep.copyright !=nil)
                    {
                        streetcarDisclaimer = dep.copyright;
                    }
                }
                
                [self addStreetcarTextToDisclaimerCell:cell text:streetcarDisclaimer trimetDisclaimer:YES];
                
                [self updateDisclaimerAccessibility:cell];
                
                break;
            }
        case kSectionNearby:
            cell = [self actionCell:tableView
                              image:[self getModeAwareIcon:kIconLocate7]
                               text:NSLocalizedString(@"Nearby stops", @"button text")
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
            
            break;
        case kSectionSiri:
        {
            if (@available(iOS 12.0, *)) {
                
                cell = [self actionCell:tableView
                                  image:[self getIcon:kIconSiri]
                                   text:NSLocalizedString(@"Add this stop to Siri",@"button text")
                              accessory:UITableViewCellAccessoryDisclosureIndicator];
            }
            else
            {
                cell = [self tableView:self.table cellWithReuseIdentifier:kExceptionCellId];
            }
            break;
        }
        case kSectionOneStop:
            cell = [self actionCell:tableView
                              image:[self getIcon:kIconArrivals]
                               text:NSLocalizedString(@"Show only this stop", @"button text")
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
            
            break;
        case kSectionInfo:
            cell = [self actionCell:tableView
                              image:[self getIcon:kIconTriMetLink]
                               text:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@ info", @"button text"), dd.depLocId]
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
            
            break;
        case kSectionStation:
            cell = [self actionCell:tableView
                              image:[self getIcon:KIconRailStations]
                               text:NSLocalizedString(@"Rail station details", @"button text")
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
            break;
        case kSectionOpposite:
            cell = [self actionCell:tableView
                              image:[self getIcon:kIconArrivals]
                               text:NSLocalizedString(@"Departures going the other way ", @"button text")
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
            break;
        case kSectionVehicles:
            cell = [self actionCell:tableView
                              image:[self getIcon:kIconArrivals]
                               text:NSLocalizedString(@"Nearby vehicles ", @"button text")
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
            break;
        case kSectionNoDeeper:
            cell = [self actionCell:tableView
                              image:[self getIcon:kIconCancel]
                               text:NSLocalizedString(@"Too many windows open", @"button text")
                          accessory:UITableViewCellAccessoryNone];
            break;
        case kSectionFilter:
            cell = [self actionCell:tableView
                              image:[self getModeAwareIcon:kIconLocate7]
                               text:self.savedBlock ?  NSLocalizedString(@"Show one departure", @"button text")
                                                    :  NSLocalizedString(@"Show all departures", @"button text")
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
            break;
        case kSectionProximity:
        {
            AlarmTaskList *taskList = [AlarmTaskList sharedInstance];
            NSString *text = nil;
            
            if ([taskList hasTaskForStopIdProximity:dd.depLocId])
            {
                text = NSLocalizedString(@"Cancel proximity alarm", @"button text");
            }
            else if ([LocationAuthorization locationAuthorizedOrNotDeterminedShowMsg:NO backgroundRequired:YES])
            {
                text = kUserProximityCellText;
            }
            else
            {
                text = kUserProximityDeniedCellText;
            }
            
            cell = [self actionCell:tableView
                              image:[self getIcon:kIconAlarm]
                               text:text
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
            break;
        }
        case kSectionTrip:
        {
            NSString *text = nil;
            
            if (newIndexPath.row == kTripRowFrom)
            {
                text = NSLocalizedString(@"Plan trip from here", @"button text");
            }
            else
            {
                text = NSLocalizedString(@"Plan trip to here", @"button text");
            }
            
            cell = [self actionCell:tableView
                              image:[self getIcon:kIconTripPlanner]
                               text:text
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
             break;
        }
        case kSectionTitle:
            cell = [self actionCell:tableView
                              image:nil
                               text:dd.depGetSectionTitle
                          accessory:UITableViewCellAccessoryNone];
            
            break;
        case kSectionAccuracy:
            cell = [self actionCell:tableView
                              image:[self getIcon:kIconLink]
                               text:NSLocalizedString(@"Check TriMet web site", @"button text")
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
            break;
        default:
            cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
            break;
    }
    return cell;
}


- (void)tableView:(UITableView *)tableView detourButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath buttonType:(NSInteger)buttonType
{
    id<DepartureTimesDataProvider> dd = self.visibleDataArray[indexPath.section];
    NSIndexPath * newIndexPath = [self subsection:indexPath];
    
    if (dd.depDetour)
    {
        [self detourAction:dd.depDetour buttonType:buttonType indexPath:indexPath reloadSection:YES];
    }
    else
    {
        Detour *detour = self.allDetours[dd.depDetoursPerSection[newIndexPath.row]];
        [self detourAction:detour buttonType:buttonType indexPath:indexPath reloadSection:YES];
    }

}


- (void)tableView:(UITableView *)table siriButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    
    if (@available(iOS 12.0, *))
    {
        ArrivalsIntent *intent = [[ArrivalsIntent alloc] init];
        id<DepartureTimesDataProvider> dd = self.visibleDataArray[indexPath.section];
        XMLDepartures *dep = dd.depXML;
            
        intent.suggestedInvocationPhrase = [NSString stringWithFormat:@"Show departure at %@", dep.locDesc];
        intent.stops = dep.locid;
        intent.locationName = dep.locDesc;
        
        INShortcut *shortCut = [[INShortcut alloc] initWithIntent:intent];
    
        INUIAddVoiceShortcutViewController *viewController = [[INUIAddVoiceShortcutViewController alloc] initWithShortcut:shortCut];
        viewController.modalPresentationStyle = UIModalPresentationFormSheet;
        viewController.delegate = self;

        [self presentViewController:viewController animated:YES completion:nil];
    }
}

- (void)addBookmarkToSiri
{
    if (@available(iOS 12.0, *))
    {
        INShortcut *shortCut = [[INShortcut alloc] initWithUserActivity:self.userActivity];
        
        INUIAddVoiceShortcutViewController *viewController = [[INUIAddVoiceShortcutViewController alloc] initWithShortcut:shortCut];
        viewController.modalPresentationStyle = UIModalPresentationFormSheet;
        viewController.delegate = self;
        
        [self presentViewController:viewController animated:YES completion:nil];
    }
}

- (void)addVoiceShortcutViewController:(INUIAddVoiceShortcutViewController *)controller didFinishWithVoiceShortcut:(nullable INVoiceShortcut *)voiceShortcut error:(nullable NSError *)error
API_AVAILABLE(ios(12.0))
{
    [controller dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)addVoiceShortcutViewControllerDidCancel:(INUIAddVoiceShortcutViewController *)controller
API_AVAILABLE(ios(12.0))
{
     [controller dismissViewControllerAnimated:YES completion:nil];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    id<DepartureTimesDataProvider> dd = self.visibleDataArray[indexPath.section];
    NSIndexPath *newIndexPath = [self subsection:indexPath];
    
    switch (newIndexPath.section)
    {
        case kSectionTimes:
        {
            if (dd.depGetSafeItemCount!=0 && newIndexPath.row < dd.depGetSafeItemCount)
            {
                Departure *departure = [dd depGetDeparture:newIndexPath.row];
        
                // if (departure.hasBlock || departure.detour)
                if (departure.errorMessage==nil)
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
                    
                    [departureDetailView fetchDepartureAsync:self.backgroundTask dep:departure allDepartures:self.originalDataArray backgroundRefresh:NO];
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
            endpoint.additionalInfo     = dd.depLocDesc;
            endpoint.locationDesc       = dd.depLocId;
            
            
            [self.navigationController pushViewController:tripPlanner animated:YES];
            break;
        }
        case kSectionProximity:
        {
            AlarmTaskList *taskList = [AlarmTaskList sharedInstance];
            
            if ([taskList hasTaskForStopIdProximity:dd.depLocId])
            {
                [taskList cancelTaskForStopIdProximity:dd.depLocId];
            }
            else if ([LocationAuthorization locationAuthorizedOrNotDeterminedShowMsg:NO backgroundRequired:YES])
            {
                id<DepartureTimesDataProvider> dd = self.visibleDataArray[indexPath.section];
                
                [taskList userAlertForProximity:self source:[tableView cellForRowAtIndexPath:indexPath]
                                     completion:^(bool cancelled, bool accurate) {
                                         if (!cancelled)
                                         {
                                             [taskList addTaskForStopIdProximity:dd.depLocId  loc:dd.depLocation desc:dd.depLocDesc accurate:accurate];
                                             [self reloadData];
                                         }
                                     }];
            
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
            FindByLocationView *find = [[FindByLocationView alloc] initWithLocation:dd.depLocation description:dd.depLocDesc];

            [self.navigationController pushViewController:find animated:YES];
            

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
        case kSectionSiri:
            [self tableView:self.table siriButtonTappedForRowWithIndexPath:indexPath];
            break;
            
        case kSectionInfo:
        {
            NSString *url = [NSString stringWithFormat:@"https://trimet.org/go/cgi-bin/cstops.pl?action=entry&resptype=U&lang=pdaen&noCat=Landmark&Loc=%@",
                             dd.depLocId];
            
            
            [WebViewController displayPage:url
                                      full:url
                                 navigator:self.navigationController
                            itemToDeselect:self
                                  whenDone:nil];

            break;
        }
        case kSectionSystemAlert:
            [self detourToggle:dd.depDetour indexPath:indexPath reloadSection:YES];
            break;
        case kSectionStation:
        {
            {
                RailStation * station = [AllRailStationView railstationFromStopId:dd.depLocId];
                
                if (station == nil)
                {
                    return;
                }
                
                RailStationTableView *railView = [RailStationTableView viewController];
                railView.station = station;
                railView.callback = self.callback;
                // railView.from = self.from;
                railView.locationsDb = [StopLocations getDatabase];
                
                [railView maybeFetchRouteShapesAsync:self.backgroundTask];
            }    

            break;
        }
        case kSectionOpposite:
        {
            DepartureTimesView *opposite = [DepartureTimesView viewController];
            opposite.callback = self.callback;
            [opposite fetchTimesForStopInOtherDirectionAsync:self.backgroundTask departures:dd.depXML];
            break;
        }
        case kSectionVehicles:
        {
            [[VehicleTableView viewController] fetchNearestVehiclesAsync:self.backgroundTask
                                                                location:dd.depLocation
                                                             maxDistance:[UserPrefs sharedInstance].vehicleLocatorDistance
                                                       backgroundRefresh:NO
             ];
            break;
        }
            
        case kSectionNoDeeper:
            [self.navigationController popViewControllerAnimated:YES];
            break;
            
        case kSectionAccuracy:
        {
            NSString *url = [NSString stringWithFormat:@"https://trimet.org/arrivals/small/tracker?locationID=%@",
                             dd.depLocId];
            
            
            [WebViewController displayPage:url
                                      full:url
                                 navigator:self.navigationController
                            itemToDeselect:self
                                  whenDone:nil];
            
            break;
        }
        case kSectionOneStop:
        {
            DepartureTimesView *departureViewController = [DepartureTimesView viewController];
            
            departureViewController.callback = self.callback;
            [departureViewController fetchTimesForLocationAsync:self.backgroundTask 
                                                            loc:dd.depLocId
                                                          title:dd.depLocDesc];
            break;
        }
        case kSectionFilter:
        {
            
            if ([dd respondsToSelector:@selector(depXML)])
            {
                XMLDepartures *dep = (XMLDepartures*)dd.depXML;
                    
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
            if (dd.depNetworkError)
            {
                [self networkTips:dd.depHtmlError networkError:dd.depNetworkErrorMsg];
                [self clearSelection];
                
            } else if (!_blockSort)
            {
                int sect = (int)indexPath.section;
                [self.table deselectRowAtIndexPath:indexPath animated:YES];
                self.sectionExpanded[sect] = self.sectionExpanded[sect].boolValue ? @NO : @YES;
            
                
                // copy this struct
                SECTIONROWS *oldRows = self.sectionRows[sect].copy;
                
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
                    UIButton *button = [[UIButton alloc] init];
                    button.frame = CGRectMake(0,0, ACCESSORY_BUTTON_SIZE, ACCESSORY_BUTTON_SIZE);
                    [button setImage:self.sectionExpanded[indexPath.section].boolValue
                                    ? [self getModeAwareIcon:kIconCollapse7]
                                    : [self getModeAwareIcon:kIconExpand7] forState:UIControlStateNormal];
                    button.userInteractionEnabled = NO;
                    staticCell.accessoryView = button;
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
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUserDefaultsDidChangeNotification object:[NSUserDefaults standardUserDefaults]];
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
    [toolbarItems addObject:[UIToolbar flexSpace]];
    
    if (((!(_blockFilter || self.originalDataArray.count == 1)) || _allowSort) && ([UserPrefs sharedInstance].groupByArrivalsIcon))
    {
        UIBarButtonItem *sort = [[UIBarButtonItem alloc]
                                  // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                                  initWithImage:[TableViewWithToolbar getToolbarIcon:kIconSort7]
                                  style:UIBarButtonItemStylePlain
                                  target:self action:@selector(sortButton:)];
        
        sort.accessibilityLabel = NSLocalizedString(@"Group Departures", @"Accessibility text");
        
        TOOLBAR_PLACEHOLDER(sort, @"G");
        
        [toolbarItems addObject:sort];;
        [toolbarItems addObject:[UIToolbar flexSpace]];
        
    }
    
    if ([UserPrefs sharedInstance].debugXML)
    {
        [toolbarItems addObject:[self debugXmlButton]];
        [toolbarItems addObject:[UIToolbar flexSpace]];
    }
    
    [toolbarItems addObject:[UIToolbar mapButtonWithTarget:self action:@selector(showMap:)]];
    
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
    
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
    
    
    if (@available(iOS 12.0, *))
    {
        for (XMLDepartures *dep in self.originalDataArray)
        {
            ArrivalsIntent *intent = [[ArrivalsIntent alloc] init];
            
            intent.suggestedInvocationPhrase = [NSString stringWithFormat:@"Get departures for at %@", dep.locDesc];
            intent.stops = dep.locid;
            
            if (dep.locDesc)
            {
                intent.locationName = dep.locDesc;
            }
            
            INInteraction *interaction = [[INInteraction alloc] initWithIntent:intent response:nil];
            
            [interaction donateInteractionWithCompletion:^(NSError * _Nullable error) {
                LOG_NSERROR(error);
            }];
        }
    }
   
    
    Class userActivityClass = (NSClassFromString(@"NSUserActivity"));
    
    if (userActivityClass !=nil)
    {
        NSMutableString *locs = [NSString commaSeparatedStringFromEnumerator:self.originalDataArray selector:@selector(locid)];
        
        if (self.userActivity != nil)
        {
            [self.userActivity invalidate];
        }
        
        self.userActivity = [[NSUserActivity alloc] initWithActivityType:kHandoffUserActivityBookmark];
        
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        
        if (self.originalDataArray.count >= 1)
        {
            XMLDepartures *dep = self.originalDataArray.firstObject;
            
            self.userActivity.webpageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://trimet.org/arrivals/small/tracker?locationID=%@", dep.locid]];
            
            
            if (self.originalDataArray.count == 1 && dep.locDesc != nil)
            {
                info[kUserFavesChosenName] = dep.locDesc;
            }
            else if (self.bookmarkDesc!=nil)
            {
                info[kUserFavesChosenName] = self.bookmarkDesc;
            }
            else
            {
                info[kUserFavesChosenName] = @"unknown stops";
            }
                                                                                                    
            if (self.bookmarkDesc!=nil)
            {
                self.userActivity.title = [NSString stringWithFormat:kUserFavesDescription,  self.bookmarkDesc];
            }
            else
            {
                self.userActivity.title = [NSString stringWithFormat:@"Launch PDX Bus & show departures for stops %@",  locs];
            }
            
            if (@available(iOS 12.0, *))
            {
                self.userActivity.eligibleForSearch = YES;
                self.userActivity.eligibleForPrediction = YES;
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


- (void)handleChangeInUserSettings:(id)obj
{
   // [self reloadData];
    [MainQueueSync runSyncOnMainQueueWithoutDeadlocking:^{
        [self stopTimer];
        [self startTimer];
    }];
}

#pragma mark BackgroundTask methods

- (void)reloadData
{

    [super reloadData];
    [self cacheWarningRefresh:YES];
}

@end

