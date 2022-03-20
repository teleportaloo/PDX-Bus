//
//  DepartureTimesView.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogUserInterface

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
#import "UserState.h"
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
#import "UIViewController+LocationAuthorization.h"
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
#import "TaskState.h"
#import "DetourTableViewCell.h"
#import "ViewControllerBase+DetourTableViewCell.h"
#import "Icons.h"
#import "UIApplication+Compat.h"
#import "RunParallelBlocks.h"
#import "UIFont+Utility.h"

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

enum {
    kTripRowFrom = 0,
    kTripRowTo,
    kTripRows
};

#define kActionCellId    @"Action"
#define kTitleCellId     @"Title"
#define kAlarmCellId     @"Alarm"
#define kDistanceCellId  @"Distance"
#define kDistanceCellId2 @"Distance2"
#define kStatusCellId    @"Status"

#define kGettingArrivals @"getting departures"
#define kGettingStop     @"getting stop ID";

#define DISTANCE_TAG     1
#define ACCURACY_TAG     2

static int depthCount = 0;
#define kMaxDepth        9

@interface DepartureTimesView () {
    bool _blockFilter;
    bool _reloadWhenAppears;
    bool _updatedWatch;
}

@property (nonatomic, strong) NSMutableArray<SectionRows *> *sectionRows;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *sectionExpanded;
@property (nonatomic, strong) NSMutableArray<id<DepartureTimesDataProvider> > *visibleDepartures;
@property (nonatomic, strong) NSMutableArray<XMLDepartures *> *xmlDepartures;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, Detour *> *allDetours;
@property (nonatomic, strong) NSMutableDictionary<NSString *, Route *> *allRoutes;

@property (nonatomic, copy)   NSString *stopIds;

@property (nonatomic, copy)   NSString *bookmarkLoc;
@property (nonatomic, copy)   NSString *bookmarkDesc;
@property (nonatomic, copy)   NSString *savedBlock;
@property (nonatomic)         bool allowSort;
@property (nonatomic, strong) NSMutableArray *vehicleStops;
@property (nonatomic, strong) NSUserActivity *userActivity;


- (void)refreshAction:(id)sender;
- (void)sortByBus;
- (void)clearSections;
- (void)detailsChanged;

@end

@implementation DepartureTimesView

#define kNonDepartureHeight 35.0

- (void)dealloc {
    depthCount--;
    DEBUG_LOGL(depthCount);
    
    if (self.userActivity) {
        [self.userActivity invalidate];
    }
    
    [self clearSections];
}

- (instancetype)init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"Departures", @"page title");
        self.xmlDepartures = [NSMutableArray array];
        self.visibleDepartures = [NSMutableArray array];
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
- (CGFloat)heightOffset {
    return -[UIApplication sharedApplication].compatStatusBarFrame.size.height;
}

#endif

#pragma mark Data sorting and manipulation

- (bool)validStopDataProvider:(id<DepartureTimesDataProvider>)dd {
    return (dd.depGetSectionHeader != nil
            &&  dd.depDetour == nil
            &&    (dd.depGetSafeItemCount == 0
                   ||  (dd.depGetSafeItemCount > 0 && [dd depGetDeparture:0].errorMessage == nil)));
}

- (bool)validStop:(unsigned long)i {
    id<DepartureTimesDataProvider> dd = self.visibleDepartures[i];
    
    return [self validStopDataProvider:dd];
}

- (NSMutableArray<Detour *> *)sortDetours:(NSMutableSet *)detoursNoLongerFound {
    NSMutableArray<Detour *> *sortedDetours = [NSMutableArray array];
    
    [self.allDetours enumerateKeysAndObjectsUsingBlock: ^void (NSNumber *detourId, Detour *detour, BOOL *stop)
     {
        [detour.routes sortUsingComparator:^NSComparisonResult (Route *r1, Route *r2) {
            return [r1 compare:r2];
        }];
        
        if (detour.systemWide) {
            [sortedDetours addObject:detour];
            [detoursNoLongerFound removeObject:detour.detourId];
        }
    }];
    
    [sortedDetours sortUsingSelector:@selector(compare:)];

    return sortedDetours;
}

- (void)sortByStop {
    NSMutableArray<id<DepartureTimesDataProvider>> *uiArray = [NSMutableArray array];
    NSMutableSet *detoursNoLongerFound = Settings.hiddenSystemWideDetours.mutableCopy;
    
    NSMutableArray<Detour *> * sortedDetours = [self sortDetours:detoursNoLongerFound];

    for (Detour *det in sortedDetours)
    {
        [uiArray addObject:det];
    }
        
    bool hasData = YES;
    
    for (XMLDepartures *deps in self.xmlDepartures) {
        if (deps.gotData) {
            hasData = NO;
            break;
        }
    }
    
    if (hasData) {
        [Settings removeOldSystemWideDetours:detoursNoLongerFound];
    }
    
    for (XMLDepartures *deps in self.xmlDepartures) {
        [uiArray addObject:deps];
    }
    
    self.visibleDepartures = uiArray;
}

- (void)sortByBus {
    if (self.xmlDepartures.count == 0) {
        self.visibleDepartures = [NSMutableArray array];
        return;
    }
    
    if (!self.blockSort) {
        [self sortByStop];
        return;
    }
    
    self.visibleDepartures = [NSMutableArray array];
    
    NSMutableSet *detoursNoLongerFound = Settings.hiddenSystemWideDetours.mutableCopy;
    NSMutableArray<Detour *> * sortedDetours = [self sortDetours:detoursNoLongerFound];
    
    for (Detour *det in sortedDetours)
    {
        [self.visibleDepartures addObject:det];
    }
    
    
    
    int stop;
    int bus;
    int search;
    int insert;
    BOOL found;
    Departure *itemToInsert;
    Departure *firstItemForBus;
    Departure *existingItem;
    DepartureTimesByBus *busRoute;
    XMLDepartures *deps;
    
    for (stop = 0; stop < self.xmlDepartures.count; stop++) {
        @autoreleasepool
        {
            deps = self.xmlDepartures[stop];
            
            if (deps.gotData) {
                for (bus = 0; bus < deps.count; bus++) {
                    itemToInsert = deps[bus];
                    found = NO;
                    
                    for (search = 0; search < self.visibleDepartures.count; search++) {
                        busRoute = self.visibleDepartures[search];
                        firstItemForBus = [busRoute depGetDeparture:0];
                        
                        if (itemToInsert.block != nil && [firstItemForBus.block isEqualToString:itemToInsert.block]) {
                            for (insert = 0; insert < busRoute.departureItems.count; insert++) {
                                existingItem = [busRoute depGetDeparture:insert];
                                
                                // existingItem is later in time than itemToInsert
                                if ([existingItem.departureTime compare:itemToInsert.departureTime] ==  NSOrderedDescending) {
                                    [busRoute.departureItems insertObject:itemToInsert atIndex:insert];
                                    found = YES;
                                    break;
                                }
                            }
                            
                            if (!found) {
                                [busRoute.departureItems addObject:itemToInsert];
                                found = YES;
                            }
                            
                            break;
                        }
                    }
                    
                    if (!found) {
                        DepartureTimesByBus *newBus = [[DepartureTimesByBus alloc] init];
                        [newBus.departureItems addObject:itemToInsert];
                        [self.visibleDepartures addObject:newBus];
                    }
                }
            }
        }
    }
}

+ (BOOL)canGoDeeper {
    return depthCount < kMaxDepth;
}

- (void)resort {
    if (self.blockSort) {
        self.blockSort = YES;
        [self sortByBus];
    } else {
        self.blockSort = NO;
        [self sortByStop];
    }
    
    [self clearSections];
    
    [self reloadData];
}

#pragma Cache warning

- (void)cacheWarningRefresh:(bool)refresh {
    DEBUG_LOGB(refresh);
    
    if (self.xmlDepartures.count > 0) {
        XMLDepartures *first = nil;
        
        for (XMLDepartures *item in self.xmlDepartures) {
            if (item.itemFromCache) {
                first = item;
                break;
            }
        }
        
        if (first && first.itemFromCache) {
            if (self.navigationItem.prompt == nil) {
                [self.navigationController setNavigationBarHidden:YES];
            }
            
            self.navigationItem.prompt = kCacheWarning;
            [self.navigationController setNavigationBarHidden:NO];
        } else {
            if (self.navigationItem.prompt != nil) {
                [self.navigationController setNavigationBarHidden:YES];
            }
            
            self.navigationItem.prompt = nil;
            [self.navigationController setNavigationBarHidden:NO];
        }
        
        XMLDepartures *item0 = self.xmlDepartures.firstObject;
        
        if (item0 && [item0 depQueryTime] != nil) {
            [self updateRefreshDate:item0.depQueryTime];
        } else {
            self.secondLine = @"";
        }
    } else {
        self.secondLine = @"";
        self.navigationItem.prompt = nil;
    }
    
    DEBUG_LOGR(self.table.frame);
}

#pragma mark Section calculations

- (void)clearSections {
    self.sectionRows = nil;
}

- (bool)countStops:(int *)first {
    int stops = 0;
    *first = INT_MAX;
    
    for (int i = 0; i < self.visibleDepartures.count; i++) {
        id<DepartureTimesDataProvider> dd = self.visibleDepartures[i];
        
        if (dd.depDetour == nil) {
            stops++;
            
            if (i < *first) {
                *first = i;
            }
            
            if (stops > 1) {
                break;
            }
        }
    }
    
    return stops > 1;
}

- (SectionRows *)calcSubsections:(NSInteger)section {
    if (self.sectionRows == NULL) {
        self.sectionRows = [NSMutableArray array];
        
        for (NSInteger i = 0; i < self.visibleDepartures.count; i++) {
            self.sectionRows[i] = [NSMutableArray array];
            self.sectionRows[i][0] = @(kSectionRowInit);
        }
    }
    
    bool multipleStops = NO;
    int first = 0;
    
    // We count the stops - if there is one then that is expanded.
    
    multipleStops = [self countStops:&first];
    
    
    if (self.sectionExpanded == nil || self.sectionExpanded.count != self.visibleDepartures.count) {
        self.sectionExpanded = [NSMutableArray array];
        
        for (int i = 0; i < self.visibleDepartures.count; i++) {
            self.sectionExpanded[i] = @NO;
        }
        
        if (!multipleStops) {
            self.sectionExpanded[first] = @YES;
        }
    }
    
    SectionRows *sr = self.sectionRows[section];
    
    if (sr[0].integerValue == kSectionRowInit) {
        bool expanded = !_blockSort && self.sectionExpanded[section].boolValue;
        id<DepartureTimesDataProvider> dd = self.visibleDepartures[section];
        
        int next = 0;
        
        // kSectionDistance
        if (dd.depDistance != nil) {
            next++;
        }
        
        sr[kSectionDistance] = @(next);
        
        // kSectionTitle
        if (dd.depGetSectionTitle != nil) {
            next++;
        }
        
        sr[kSectionTitle] = @(next);
        
        
        // kSectionTimes
        NSInteger itemCount = dd.depGetSafeItemCount;
        
        if (itemCount == 0 && dd.depDetour == nil) {
            itemCount = 1;
        }
        
        next += itemCount;
        sr[kSectionTimes] = @(next);
        
        // kSectionDetours
        if (dd.depDetoursPerSection) {
            next += dd.depDetoursPerSection.count;
        }
        
        sr[kSectionDetours] = @(next);
        
        // kSectionTrip
        if (dd.depLocation != nil && expanded) {
            next += kTripRows;
        }
        
        sr[kSectionTrip] = @(next);
        
        // kSectionFilter
        if (_blockFilter && expanded) {
            next++;
        }
        
        sr[kSectionFilter] = @(next);
    
        // kSectionProximity
        if (dd.depLocation != nil && expanded && [AlarmTaskList proximitySupported]) {
            next++;
        }
        
        sr[kSectionProximity] = @(next);
        
        // kSectionNearby
        if (dd.depLocation != nil && depthCount < kMaxDepth && expanded && [DepartureTimesView canGoDeeper]) {
            next++;
        }
        
        sr[kSectionNearby] = @(next);

#if !TARGET_OS_MACCATALYST
        // kSectionSiri
        if (dd.depLocation != nil && depthCount < kMaxDepth && expanded && [DepartureTimesView canGoDeeper]) {
            next++;
        }
#endif
        
        sr[kSectionSiri] = @(next);
        
        // kSectionOneStop bug here - visable deps may include a detour
        if (dd.depLocation != nil && depthCount < kMaxDepth && expanded && multipleStops && [DepartureTimesView canGoDeeper]) {
            next++;
        }
        
        sr[kSectionOneStop] = @(next);
        
        // kSectionOpposite
        if (dd.depLocation != nil && expanded && [DepartureTimesView canGoDeeper]
            && dd.depGetSafeItemCount > 0) {
            next++;
        }
        
        sr[kSectionOpposite] = @(next);
        
        // kSectionVehicle
        if (dd.depLocation != nil && expanded && (Settings.vehicleLocations) && [DepartureTimesView canGoDeeper]) {
            next++;
        }
        
        sr[kSectionVehicles] = @(next);
        
        // kSectionNoDeeper
        if (expanded && ![DepartureTimesView canGoDeeper]) {
            next++;
        }
        
        sr[kSectionNoDeeper] = @(next);
        
        // kSectionStation
        if (expanded && dd.depStopId != nil && [AllRailStationView railstationFromStopId:dd.depStopId] != nil && [DepartureTimesView canGoDeeper]) {
            next++;
        }
        
        sr[kSectionStation] = @(next);
        
        // kSectionInfo
        if (expanded && dd.depLocation != nil) {
            next++;
        }
        
        sr[kSectionInfo] = @(next);
        
        // kSectionAccuracy
        if (expanded && Settings.showTransitTracker && dd.depLocation != nil) {
            next++;
        }
        
        sr[kSectionAccuracy] = @(next);
        
        // kSectionStatic
        if (!dd.depDetour) {
            next++;
        }
        
        sr[kSectionStatic] = @(next);
        
        if (dd.depDetour) {
            next++;
        }
        
        sr[kSectionSystemAlert] = @(next);
        
        // final placeholder
        sr[kSectionsPerStop] = @(next);
    }
    
    return sr;
}

- (NSIndexPath *)subsection:(NSIndexPath *)indexPath; {
    NSIndexPath *newIndexPath = nil;
    
    int prevrow = 0;
    SectionRows *sr = [self calcSubsections:indexPath.section];
    
    for (int i = 0; i < kSectionsPerStop; i++) {
        if (indexPath.row < sr[i].integerValue) {
            newIndexPath = [NSIndexPath indexPathForRow:indexPath.row - prevrow
                                              inSection:i];
            break;
        }
        
        prevrow = sr[i].intValue;
    }
    
    //    printf("Old %d %d new %d %d\n",(int)indexPath.section,(int)indexPath.row, (int)newIndexPath.section, (int)newIndexPath.row);
    
    return newIndexPath;
}

#pragma mark Data fetchers

- (void)subTaskFetchTimesForVehicleStops:(NSString *)block
                               taskState:(TaskState *)taskState {
    int items = 0;
    int batch = 0;
    int pos = 0;
    bool found = false;
    bool done = false;
    const NSInteger maxToShow = 30;
    taskState.total--;  // we add one back each time around
    
    @autoreleasepool {
        NSArray *batches = [XMLMultipleDepartures batchesFromEnumerator:self.vehicleStops selToGetStopId:@selector(stopId)  max:INT_MAX];
        
        while (batch < batches.count && items < maxToShow && pos < self.vehicleStops.count && !done) {
            XMLMultipleDepartures *multiple = [XMLMultipleDepartures xmlWithOneTimeDelegate:taskState sharedDetours:self.allDetours sharedRoutes:self.allRoutes];
            
            taskState.total++;
            [taskState displayTotal];
            [multiple getDeparturesForStopIds:batches[batch] block:block];
            [taskState incrementItemsDoneAndDisplay];
            
            if (multiple.gotData && multiple.count > 0) {
                for (XMLDepartures *deps in multiple) {
                    if (items < maxToShow) {
                        if (deps.gotData && deps.count > 0 && !(deps.items.firstObject.status != ArrivalStatusEstimated && deps.items.firstObject.minsToArrival > 59)) {
                            [self.xmlDepartures addObject:deps];
                            pos++;
                            items++;
                            found = YES;
                        } else if (!found) {
                            [self.vehicleStops removeObjectAtIndex:pos];
                        } else {
                            pos++;
                            done = YES;
                        }
                    } else {
                        break;
                    }
                }
            } else {
                done = YES;
            }
            
            batch++;
            
            XML_DEBUG_RAW_DATA(multiple);
        }
    }
}

- (StopDistance *)subTaskFetchOtherDirectionForDeparture:(Departure *)dep state:(TaskState *)taskState {
    // Note - to autorelease pool as this is not a thread method
    XMLRoutes *xmlRoutes = [XMLRoutes xml];
    
    PtrConstRouteInfo info = [TriMetInfo infoForRoute:dep.route];
    
    NSString *oppositeRoute = nil;
    NSString *oppositeDirection = nil;
    
    if (info && info->opposite != kNoDir && info->opposite != kDir1) {
        oppositeRoute = [NSString stringWithFormat:@"%ld", (long)info->opposite];
        oppositeDirection = dep.dir;
        [taskState incrementItemsDoneAndDisplay];
    } else if (info && info->opposite == kDir1) {
        oppositeRoute = dep.route;
        
        if ([dep.dir isEqualToString:kKmlFirstDirection]) {
            oppositeDirection = kKmlOptionalDirection;
        } else {
            oppositeDirection = kKmlFirstDirection;
        }
    } else {
        oppositeRoute = dep.route;
        
        [taskState taskSubtext:NSLocalizedString(@"checking direction", @"progress message")];
        [xmlRoutes getDirections:oppositeRoute cacheAction:TrIMetXMLRouteCacheReadOrFetch];
        
        if (xmlRoutes.itemFromCache) {
            [taskState decrementTotalAndDisplay];
        } else {
            [taskState incrementItemsDoneAndDisplay];
        }
        
        // Find the first direction that isn't us
        if (xmlRoutes.count > 0) {
            Route *route = xmlRoutes.items.firstObject;
            
            if (route.directions.count > 1) {
                for (NSString *routeDir in route.directions) {
                    if (![routeDir isEqualToString:dep.dir]) {
                        oppositeDirection = routeDir;
                    }
                }
            } else if (route.directions.count == 1 && [TriMetInfo isSingleLoopRoute:route.route]) {
                oppositeDirection = route.directions.allKeys.firstObject;
            }
        }
    }
    
    XML_DEBUG_RAW_DATA(xmlRoutes);
    
    if (oppositeDirection) {
        NSString *otherLine = nil;
        NSArray *routes = nil;
        
        if (info && info->interlined_route != kNoRoute) {
            otherLine = [TriMetInfo interlinedRouteString:info];
        }
        
        if (otherLine) {
            routes = @[oppositeRoute, otherLine];
        } else {
            routes = @[oppositeRoute];
        }
        
        CLLocationDistance closest = DBL_MAX;
        Stop *closestStop = nil;
        
        [taskState taskSubtext:NSLocalizedString(@"finding stop", @"progress message")];
        
        bool fetched = NO;
        
        NSMutableArray<XMLStops *> *stopsForRoutes = [NSMutableArray array];
        
        RunParallelBlocks *parallelBlocks = [RunParallelBlocks instance];
        
        for (NSString *foundRoute in routes) {
            XMLStops *stops = [[XMLStops alloc] init];
            
            [stopsForRoutes addObject:stops];
            [parallelBlocks startBlock:^{
                [stops getStopsForRoute:foundRoute direction:oppositeDirection description:nil cacheAction:TrIMetXMLRouteCacheReadOrFetch];
           
            }];
        }
        
        [parallelBlocks waitForBlocks];
        
        for (XMLStops *stops in stopsForRoutes) {
            fetched = fetched || (!stops.itemFromCache);
            
            if (stops.count > 0) {
                for (Stop *stop in stops.items) {
                     CLLocationDistance dist = [dep.stopLocation distanceFromLocation:stop.location];
                    
                    if (dist < closest) {
                        closest = dist;
                        closestStop = stop;
                    }
                }
            }
            
            XML_DEBUG_RAW_DATA(stops);
        }
        
        if (fetched) {
            [taskState incrementItemsDoneAndDisplay];
        } else {
            [taskState decrementTotalAndDisplay];
        }
        
        if (closestStop) {
            StopDistance *distance = [StopDistance new];
            
            distance.stopId = closestStop.stopId;
            distance.desc = closestStop.desc;
            distance.dir = oppositeDirection;
            distance.distanceMeters = closest;
            distance.accuracy = 0;
            distance.location = closestStop.location;
            
            
            return distance;
        }
    }
    
    return nil;
}

- (NSMutableArray<StopDistance *> *)subTaskFindOppositeForOneRoute:(NSString *)bookmark
                                                      findOpposite:(Departure *)findOppositeToDep
                                                           stopIds:(NSString **)stopId
                                                         taskState:(TaskState *)taskState {
    NSMutableArray<StopDistance *> *oppositeStops = nil;
    
    taskState.total = 3;
    
    [taskState startTask:(bookmark != nil ? bookmark : kGettingArrivals)];
    
    StopDistance *stop = [self subTaskFetchOtherDirectionForDeparture:findOppositeToDep state:taskState];
    
    if (stop) {
        oppositeStops = @[stop].mutableCopy;
        *stopId = stop.stopId;
    }
    
    [taskState decrementTotalAndDisplay];
    
    return oppositeStops;
}

- (NSMutableArray<StopDistance *> *)subTaskfindOppositeForManyRoutes:(NSString *)bookmark
                                                     findOppositeAll:(XMLDepartures *)xmlFindOppositeToAll
                                                             stopIds:(NSString **)stopIds
                                                           taskState:(TaskState *)taskState {
    NSMutableArray<Departure *> *uniqueRoutes = [NSMutableArray array];
    
    for (int i = 0; i < xmlFindOppositeToAll.count; i++) {
        Departure *dep = xmlFindOppositeToAll[i];
        
        Departure *found = 0;
        
        for (Departure *d in uniqueRoutes) {
            if ([d.route isEqualToString:dep.route] && [d.dir isEqualToString:dep.dir]) {
                found = d;
                break;
            }
        }
        
        if (found == nil) {
            [uniqueRoutes addObject:dep];
        }
    }
    
    taskState.total = (int)uniqueRoutes.count * 2 + 1;
    
    [taskState startTask:(bookmark != nil ? bookmark : kGettingArrivals)];
    
    NSMutableArray<StopDistance *> *oppositeStops = [NSMutableArray array];
    
    RunParallelBlocks *parallelBlocks = [RunParallelBlocks instance];
    
    for (Departure *d in uniqueRoutes) {
        
        [parallelBlocks startBlock:^{
            StopDistance *foundStop = [self subTaskFetchOtherDirectionForDeparture:d state:taskState];
            
            @synchronized (oppositeStops) {
                if (foundStop) {
                    for (int i = 0; i < oppositeStops.count; i++) {
                        StopDistance *stop = oppositeStops[i];
                    
                        if ([stop.stopId isEqualToString:foundStop.stopId]) {
                            foundStop = nil;
                            break;
                        } else if (foundStop.distanceMeters < stop.distanceMeters) {
                            [oppositeStops insertObject:foundStop atIndex:i];
                            foundStop = nil;
                            break;
                        }
                    }
                
                    if (foundStop != nil) {
                        [oppositeStops addObject:foundStop];
                    }
                }
                else
                {
                    DEBUG_LOG(@"No opposite stop for %@", d.stopId);
                }
            }
        }];
        
    }
    
    [parallelBlocks waitForBlocks];
    
    if (!taskState.taskCancelled) {
        *stopIds = [NSString commaSeparatedStringFromEnumerator:oppositeStops selToGetString:@selector(stopId)];
    }
    
    [taskState decrementTotalAndDisplay];
    
    return oppositeStops;
}

- (void)subTaskFetchMultipleStopsWithBlock:(NSString *)block
                                   stopIds:(NSArray *)stopIdArray
                             oppositeStops:(NSMutableArray *)oppositeStops
                                 taskState:(TaskState *)taskState {
    NSInteger batches = kMultipleDepsBatches(stopIdArray.count);
    
    [taskState taskTotalItems:batches];
    NSInteger start = 0;

    RunParallelBlocks *parallelBlocks = [RunParallelBlocks instance];
    
    NSMutableArray<XMLMultipleDepartures *> *xmls = [NSMutableArray array];
    
    for (int batch = 0; batch < batches; batch++) {
        XMLMultipleDepartures *multiple = [XMLMultipleDepartures xmlWithOneTimeDelegate:taskState sharedDetours:self.allDetours sharedRoutes:self.allRoutes];

        
        multiple.blockFilter = block;
        
        NSInteger batchSize = stopIdArray.count - start;
        
        if (batchSize > kMultipleDepsMaxStops) {
            batchSize = kMultipleDepsMaxStops;
        }
        
        NSArray<NSString *> *batchStopIdArray = [stopIdArray subarrayWithRange:NSMakeRange(start, batchSize)];
        
        [xmls addObject:multiple];
        
        [parallelBlocks startBlock:^{
            [multiple getDeparturesForStopIds:[NSString commaSeparatedStringFromStringEnumerator:batchStopIdArray]];
            [taskState incrementItemsDoneAndDisplay];
            XML_DEBUG_RAW_DATA(multiple);
        }];
        
        start += kMultipleDepsMaxStops;
    }
    
    [parallelBlocks waitForBlocks];

    NSInteger stopCount = 0;
    
    for (int batch = 0; batch < batches; batch++) {
        XMLMultipleDepartures *multiple = xmls[batch];
    
        for (XMLDepartures *deps in multiple) {
            [self.xmlDepartures addObject:deps];
            
            if (oppositeStops && stopCount < oppositeStops.count) {
                deps.distance = oppositeStops[stopCount];
            }
            
            stopCount++;
        }
    }
}

- (void)subTaskfetchSingleStopWithBlock:(NSString *)block
                                stopIds:(NSArray *)stopIdArray
                                  names:(NSArray *)names
                          oppositeStops:(NSMutableArray *)oppositeStops
                              taskState:(TaskState *)taskState {
    [taskState displayTotal];
    
    XMLDepartures *deps = [XMLDepartures xmlWithOneTimeDelegate:taskState sharedDetours:self.allDetours sharedRoutes:self.allRoutes];
    
    [self.xmlDepartures addObject:deps];
    deps.blockFilter = block;
    NSString *aLoc = stopIdArray.firstObject;
    
    if (names == nil) {
        [taskState taskSubtext:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), aLoc]];
    } else {
        [taskState taskSubtext:names.firstObject];
    }
    
    [deps getDeparturesForStopId:aLoc];
    
    if (oppositeStops && oppositeStops.count > 0) {
        deps.distance = oppositeStops.firstObject;
    }
    
    [taskState incrementItemsDoneAndDisplay];
    
    XML_DEBUG_RAW_DATA(deps);
}

- (void)fetchTimesForStopId:(NSString *)stopId
                      block:(NSString *)block
                      names:(NSArray *)names
                   bookmark:(NSString *)bookmark
                   opposite:(Departure *)findOppositeToDep
                oppositeAll:(XMLDepartures *)xmlFindOppositeToAll
             taskController:(id<TaskController>)taskController {
    [taskController taskRunAsync:^(TaskState *taskState) {
        self.bookmarkDesc = bookmark;
        
        self.xml = [NSMutableArray array];
        
        NSString *foundStopIds = stopId;
        
        [self clearSections];
        [XMLDepartures clearCache];
        
        NSMutableArray *oppositeStops = nil;
        
        if (findOppositeToDep) {
            oppositeStops = [self subTaskFindOppositeForOneRoute:bookmark
                                                    findOpposite:findOppositeToDep
                                                         stopIds:&foundStopIds
                                                       taskState:taskState];
        } else if (xmlFindOppositeToAll) {
            oppositeStops = [self subTaskfindOppositeForManyRoutes:bookmark
                                                   findOppositeAll:xmlFindOppositeToAll
                                                           stopIds:&foundStopIds
                                                         taskState:taskState];
        } else {
            [taskState startAtomicTask:(bookmark != nil ? bookmark : kGettingArrivals)];
        }
        
        self.stopIds = foundStopIds;
        
        if (foundStopIds != nil && foundStopIds.length!=0) {
            NSArray<NSString *> *stopIdArray = foundStopIds.mutableArrayFromCommaSeparatedString;
            
            taskState.total = (int)stopIdArray.count;
            
            if (taskState.total > 1) {
                [self subTaskFetchMultipleStopsWithBlock:block
                                                 stopIds:stopIdArray
                                           oppositeStops:oppositeStops
                                               taskState:taskState];
            } else {
                [self subTaskfetchSingleStopWithBlock:block
                                              stopIds:stopIdArray
                                                names:names
                                        oppositeStops:oppositeStops
                                            taskState:taskState];
            }
            
            if (self.xmlDepartures.count > 0) {
                if (block != nil) {
                    self.title = NSLocalizedString(@"Track Trip", @"screen title");
                    self->_blockFilter = true;
                } else {
                    self->_blockFilter = false;
                }
                
                [self sortByBus];
            }
            
            if (!taskState.taskCancelled) {
                [self->_userState setLastArrivals:foundStopIds];
                
                NSMutableArray *names = [NSMutableArray array];
                
                for (XMLDepartures *deps in self.xmlDepartures) {
                    if (deps.locDesc) {
                        [names addObject:deps.locDesc];
                    }
                }
                
                if (names.count == self.xmlDepartures.count) {
                    [self->_userState setLastNames:names];
                } else {
                    [self->_userState setLastNames:nil];
                }
            }
        } else if (findOppositeToDep || xmlFindOppositeToAll) {
            [taskState taskCancel];
            [taskState taskSetErrorMsg:NSLocalizedString(@"Could not find a stop going the other way.", @"error message")];
        }
        
        return self;
    }];
}

- (void)subTaskFetchMultipleStopsAgain:(TaskState *)taskState  {
    int batches = kMultipleDepsBatches(self.xmlDepartures.count);
    [taskState taskStartWithTotal:batches title:kGettingArrivals];
    int start = 0;
    int i = 0;
    
    
    RunParallelBlocks *parallelBlocks = [RunParallelBlocks instance];
    
    for (int batch = 0; batch < batches; batch++) {
        int intbatch = 0;
        XMLMultipleDepartures *multiple = [XMLMultipleDepartures xmlWithOneTimeDelegate:taskState sharedDetours:self.allDetours sharedRoutes:self.allRoutes];
        
        multiple.blockFilter = self.xmlDepartures.firstObject.blockFilter;
        
        for (i = start; i < self.xmlDepartures.count && !taskState.taskCancelled && intbatch < kMultipleDepsMaxStops; i++) {
            XMLDepartures *deps = self.xmlDepartures[i];
            
            if (deps.stopId) {
                multiple.stops[deps.stopId] = deps;
                intbatch++;
            }
        }
        
        [parallelBlocks startBlock:^{
            [multiple reload];
            [taskState incrementItemsDoneAndDisplay];
            XML_DEBUG_RAW_DATA(multiple);
        }];
        
        start += kMultipleDepsMaxStops;
    }
    
    [parallelBlocks waitForBlocks];
    
}

- (void)subTaskFetchOneStopAgain:(TaskState *)taskState {
    [taskState startAtomicTask:kGettingArrivals];
    XMLDepartures *deps = self.xmlDepartures.firstObject;
    
    if (deps.locDesc != nil) {
        [taskState taskSubtext:deps.locDesc];
    }
    
    deps.oneTimeDelegate = taskState;
    [deps reload];
    
    XML_DEBUG_RAW_DATA(deps);
    
    [taskState atomicTaskItemDone];
}

- (void)fetchAgainAsync:(id<TaskController>)taskController {
    if (self.vehicleStops) {
        [taskController taskRunAsync:^(TaskState *taskState) {
            self.backgroundRefresh = YES;
            
            [self clearSections];
            self.xml = [NSMutableArray array];
            
            [taskState startAtomicTask:kGettingArrivals];
            
            XMLDepartures *deps = self.xmlDepartures.firstObject;
            NSString *block = deps.blockFilter;
            
            [self.xmlDepartures removeAllObjects];
            [self.allDetours removeAllObjects];
            
            [self subTaskFetchTimesForVehicleStops:block taskState:taskState];
            
            self->_blockFilter = true;
            self.blockSort = YES;
            self.allowSort = YES;
            
            [self sortByBus];
            [self clearSections];
            
            return (UIViewController *)nil;
        }];
    } else {
        [taskController taskRunAsync:^(TaskState *taskState) {
            self.backgroundRefresh = YES;
            
            [self clearSections];
            
            self.xml = [NSMutableArray array];
            
            if (self.xmlDepartures.count > 1) {
                [self subTaskFetchMultipleStopsAgain:taskState];
            } else {
                [self subTaskFetchOneStopAgain:taskState];
            }
            
            [self sortByBus];
            [self clearSections];
            
            return (UIViewController *)nil;
        }];
    }
}

- (void)fetchTimesForLocationAsync:(id<TaskController>)taskController
                            stopId:(NSString *)stopId
                             block:(NSString *)block {
    [self fetchTimesForStopId:stopId
                        block:block
                        names:nil
                     bookmark:nil
                     opposite:nil
                  oppositeAll:nil
               taskController:taskController];
}

- (void)fetchTimesForVehicleAsync:(id<TaskController>)taskController vehicleId:(NSString *)vehicleId {
    [self fetchTimesForVehicleAsync:taskController route:nil direction:nil nextStopId:nil block:nil targetDeparture:nil vehicleId:vehicleId];
}

- (void)fetchTimesForVehicleAsync:(id<TaskController>)taskController route:(NSString *)route direction:(NSString *)direction nextStopId:(NSString *)stopId block:(NSString *)block targetDeparture:(Departure *)targetDep {
    [self fetchTimesForVehicleAsync:taskController route:route direction:direction nextStopId:stopId block:block targetDeparture:targetDep vehicleId:nil];
}

- (Vehicle *)subTaskFetchVehicleInfo:(TaskState *)taskState vehicleId:(NSString *)vehicleId {
    taskState.total = 3;
    [taskState startTask:kGettingArrivals];
    XMLLocateVehicles *locator = [XMLLocateVehicles xml];
    
    locator.dist = 0.0;
    
    [locator findNearestVehicles:nil direction:nil blocks:nil vehicles:[NSSet setWithObject:vehicleId]];
    [taskState incrementItemsDoneAndDisplay];
    
    if (locator.gotData && locator.items.count > 0) {
        for (Vehicle *vehicle in locator) {
            if ([vehicle.vehicleId isEqualToString:vehicleId]) {
                return vehicle;
            }
        }
    }
    
    return nil;
}

- (void)subTaskFetchStopsAfterDeparture:(XMLStops *)stops targetDep:(Departure *)targetDep taskState:(TaskState *)taskState {
    taskState.total = 1 + targetDep.trips.count;
    taskState.itemsDone  = 0;
    
    stops.items = [NSMutableArray array];
    
    for (DepartureTrip *trip in targetDep.trips) {
        XMLStops *tripStops = [XMLStops xmlWithOneTimeDelegate:taskState];
        
        if (taskState.itemsDone == 0) {
            [tripStops getStopsAfterStopId:targetDep.nextStopId
                                     route:trip.route
                                 direction:trip.dir
                               description:@""
                               cacheAction:TrIMetXMLRouteCacheReadOrFetch];
        } else {
            [tripStops getStopsForRoute:trip.route
                              direction:trip.dir
                            description:@""
                            cacheAction:TrIMetXMLRouteCacheReadOrFetch];
        }
        
        if (stops.items.count > 0
            && tripStops.items.count > 0
            && [stops.items.lastObject.stopId isEqualToString:tripStops.items.firstObject.stopId]) {
            [stops.items removeLastObject];
        }
        
        [stops.items addObjectsFromArray:tripStops.items];
        
        XML_DEBUG_RAW_DATA(tripStops);
        [taskState incrementItemsDoneAndDisplay];
    }
}

- (void)fetchTimesForVehicleAsync:(id<TaskController>)taskController
                            route:(NSString *)route
                        direction:(NSString *)direction
                       nextStopId:(NSString *)stopId
                            block:(NSString *)block
                  targetDeparture:(Departure *)targetDep
                        vehicleId:(NSString *)vehicleId {
    [taskController taskRunAsync:^(TaskState *taskState) {
        NSString *localRoute = route;
        NSString *localDirection = direction;
        NSString *localStopId = stopId;
        NSString *localBlock = block;
        
        if (vehicleId != nil) {
            Vehicle * vehicle = [self subTaskFetchVehicleInfo:taskState vehicleId:vehicleId];
            
            if (vehicle)
            {
                localBlock = vehicle.block;
                localStopId = vehicle.nextStopId;
                localDirection = vehicle.direction;
                localRoute = vehicle.routeNumber;
            }
        }
        else
        {
            taskState.total = 2;
            [taskState startTask:kGettingArrivals];
        }
        
        if (!localBlock && targetDep != nil) {
            localBlock = targetDep.block;
        }
        
        if (!localBlock && targetDep == nil) {
            [taskState taskSetErrorMsg:NSLocalizedString(@"Vehicle not found, it may not be currently in service.  Note, Streetcar is not supported.", @"error text")];
            [taskState taskCancel];
            return self;
        } else {
            [self clearSections];
            [XMLDepartures clearCache];
            self.xml = [NSMutableArray array];
            
            XMLStops *stops = [XMLStops xmlWithOneTimeDelegate:taskState];
            
            if ((targetDep == nil || targetDep.trips == nil || targetDep.trips.count == 0) && localStopId != nil) {
                // Get stops in route after the current stop
                [stops getStopsAfterStopId:localStopId
                                     route:localRoute
                                 direction:localDirection
                               description:@""
                               cacheAction:TriMetXMLForceFetchAndUpdateRouteCache];
                
                XML_DEBUG_RAW_DATA(stops);
                [taskState incrementItemsDoneAndDisplay];
            } else if (targetDep.nextStopId != nil) {
                [self subTaskFetchStopsAfterDeparture:stops targetDep:targetDep taskState:taskState];
            }
            
            if (stops.gotData || stops.items.count > 0) {
                self.vehicleStops = stops.items;
                
                [self subTaskFetchTimesForVehicleStops:localBlock taskState:taskState];
            } else {
                [taskState taskCancel];
                [taskState taskSetErrorMsg:NSLocalizedString(@"Could not find any departures for that vehicle.", @"error message")];
            }
            
            if (self.xmlDepartures.count == 0) {
                [taskState taskCancel];
                [taskState taskSetErrorMsg:NSLocalizedString(@"Could not find any departures for that vehicle.", @"error message")];
            }
            
            self->_blockFilter = true;
            self.blockSort = YES;
            
            [self sortByBus];
            
            self.allowSort = YES;
            
            if (!taskState.taskCancelled) {
                [self->_userState setLastArrivals:localStopId];
                
                NSMutableArray *names = [NSMutableArray array];
                
                for (XMLDepartures *deps in self.xmlDepartures) {
                    if (deps.locDesc) {
                        [names addObject:deps.locDesc];
                    }
                }
                
                if (names.count == self.xmlDepartures.count) {
                    [self->_userState setLastNames:names];
                } else {
                    [self->_userState setLastNames:nil];
                }
            }
            
            return self;
        }
    }];
}

- (void)subTaskFetchArivalsForLocator:(XMLLocateStops *)locator taskState:(TaskState *)taskState {
    NSMutableString *stopsstr = [NSMutableString string];
    self.stopIds = stopsstr;
    int i = 0;
    
    NSArray *batches = [XMLMultipleDepartures batchesFromEnumerator:locator selToGetStopId:@selector(stopId) max:locator.maxToFind];
    
    [taskState taskTotalItems:batches.count + 1];  // should not change this
    
    RunParallelBlocks *parallelBlocks = [RunParallelBlocks instance];
    
    NSMutableArray<XMLMultipleDepartures *> *xmls = [NSMutableArray array];
    
    for (int batch = 0; batch < batches.count && !taskState.taskCancelled; batch++) {
        XMLMultipleDepartures *multiple = [XMLMultipleDepartures xmlWithOneTimeDelegate:taskState sharedDetours:self.allDetours sharedRoutes:self.allRoutes];
        
        [xmls addObject:multiple];
        
        [parallelBlocks startBlock:^{
            [multiple getDeparturesForStopIds:batches[batch]];
            [taskState incrementItemsDoneAndDisplay];
            XML_DEBUG_RAW_DATA(multiple);
        }];
    }
        
    [parallelBlocks waitForBlocks];
    
    for (int batch = 0; batch < batches.count && !taskState.taskCancelled; batch++) {
        XMLMultipleDepartures *multiple = xmls[batch];
        
        if (batch == 0) {
            [stopsstr appendFormat:@"%@", batches[batch]];
        } else {
            [stopsstr appendFormat:@",%@", batches[batch]];
        }
        
        for (XMLDepartures *deps in multiple) {
            deps.distance = locator[i];
            i++;
            [self.xmlDepartures addObject:deps];
        }
    }
    
    if (self.xmlDepartures.count > 0) {
        self->_blockFilter = false;
        [self sortByBus];
    }
}

- (void)fetchTimesForNearestStopsAsync:(id<TaskController>)taskController
                              location:(CLLocation *)here
                             maxToFind:(int)max
                           minDistance:(double)min
                                  mode:(TripMode)mode {
    [taskController taskRunAsync:^(TaskState *taskState) {
        XMLLocateStops *locator = [XMLLocateStops xmlWithOneTimeDelegate:taskState];
        
        locator.maxToFind = max;
        locator.location = here;
        locator.mode = mode;
        locator.minDistance = min;
        
        [self clearSections];
        [XMLDepartures clearCache];
        self.xml = [NSMutableArray array];
        
        [taskState taskStartWithTotal:kMultipleDepsBatches(locator.maxToFind) + 1 title:kGettingArrivals];
        
        [taskState taskSubtext:NSLocalizedString(@"getting locations", @"progress message")];
        [locator findNearestStops];
        
        [taskState incrementItemsDoneAndDisplay];
        
        if (![locator displayErrorIfNoneFound:taskState]) {
            [self subTaskFetchArivalsForLocator:locator taskState:taskState];
        }
        
        return self;
    }];
}

- (void)fetchTimesForStopInOtherDirectionAsync:(id<TaskController>)taskController
                                     departure:(Departure *)dep {
    [self fetchTimesForStopId:nil
                        block:nil
                        names:nil
                     bookmark:nil
                     opposite:dep
                  oppositeAll:nil
               taskController:taskController];
}

- (void)fetchTimesForStopInOtherDirectionAsync:(id<TaskController>)taskController
                                    departures:(XMLDepartures *)deps {
    [self fetchTimesForStopId:nil
                        block:nil
                        names:nil
                     bookmark:nil
                     opposite:nil
                  oppositeAll:deps
               taskController:taskController];
}

- (void)fetchTimesForNearestStopsAsync:(id<TaskController>)taskController
                                 stops:(NSArray<StopDistance *> *)stops {
    [taskController taskRunAsync:^(TaskState *taskState) {
        [self clearSections];
        [XMLDepartures clearCache];
        self.xml = [NSMutableArray array];
        
        NSMutableString *stopsstr = [NSMutableString string];
        self.stopIds = stopsstr;
        int i = 0;
        NSArray *batches = [XMLMultipleDepartures batchesFromEnumerator:stops selToGetStopId:@selector(stopId) max:INT_MAX];
        
        [taskState taskStartWithTotal:batches.count + 1 title:kGettingArrivals];
        
        RunParallelBlocks *parallelBlocks = [RunParallelBlocks instance];
        NSMutableArray<XMLMultipleDepartures *> * xmls =  [NSMutableArray array];
        
        for (int batch = 0; batch < batches.count && !taskState.taskCancelled; batch++) {
            XMLMultipleDepartures *multiple = [XMLMultipleDepartures xmlWithOneTimeDelegate:taskState sharedDetours:self.allDetours sharedRoutes:self.allRoutes];
            
            [xmls addObject:multiple];
            
            [parallelBlocks startBlock:^{
                [multiple getDeparturesForStopIds:batches[batch]];
                XML_DEBUG_RAW_DATA(multiple);
                [taskState incrementItemsDoneAndDisplay];
            }];
        }
        
        [parallelBlocks waitForBlocks];
        
        for (int batch = 0; batch < batches.count && !taskState.taskCancelled; batch++) {
            XMLMultipleDepartures *multiple = xmls[batch];
            
            for (XMLDepartures *deps in multiple) {
                StopDistance *sd = stops[i];
                deps.distance = sd;
                
                if (i == 0) {
                    [stopsstr appendFormat:@"%@", sd.stopId];
                } else {
                    [stopsstr appendFormat:@",%@", sd.stopId];
                }
                
                i++;
                [self.xmlDepartures addObject:deps];
            }
        }
        
        if (self.xmlDepartures.count > 0) {
            self->_blockFilter = false;
            [self sortByBus];
        }
        
        return (UIViewController *)self;
    }];
}

- (void)fetchTimesForLocationAsync:(id<TaskController>)taskController
                            stopId:(NSString *)stopId
                             names:(NSArray *)names {
    [self fetchTimesForStopId:stopId
                        block:nil
                        names:names
                     bookmark:nil
                     opposite:nil
                  oppositeAll:nil
               taskController:taskController];
}

- (void)fetchTimesForLocationAsync:(id<TaskController>)taskController
                            stopId:(NSString *)stopId {
    [self fetchTimesForStopId:stopId
                        block:nil
                        names:nil
                     bookmark:nil
                     opposite:nil
                  oppositeAll:nil
               taskController:taskController];
}

- (void)fetchTimesForLocationAsync:(id<TaskController>)taskController
                            stopId:(NSString *)stopId
                             title:(NSString *)title {
    [self fetchTimesForStopId:stopId
                        block:nil
                        names:nil
                     bookmark:title
                     opposite:nil
                  oppositeAll:nil
               taskController:taskController];
}

- (void)fetchTimesForBlockAsync:(id<TaskController>)taskController
                          block:(NSString *)block
                          start:(NSString *)start
                         stopId:(NSString *)stop {
    [taskController taskRunAsync:^(TaskState *taskState) {
        [taskState taskStartWithTotal:2 title:kGettingArrivals];
        
        [self clearSections];
        [XMLDepartures clearCache];
        self.xml = [NSMutableArray array];
        
        XMLDepartures *deps = [XMLDepartures xmlWithOneTimeDelegate:taskState sharedDetours:self.allDetours sharedRoutes:self.allRoutes];
                
        [self.xmlDepartures addObject:deps];
        deps.blockFilter = block;
        [taskState taskSubtext:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), start]];
        [deps getDeparturesForStopId:start];
        deps.sectionTitle = NSLocalizedString(@"Departure", @"");
        
        XML_DEBUG_RAW_DATA(deps);
        
        [taskState taskItemsDone:1];
        
        if (!taskState.taskCancelled) {
            deps = [XMLDepartures xmlWithOneTimeDelegate:taskState];
            
            [self.xmlDepartures addObject:deps];
            deps.blockFilter = block;
            [taskState taskSubtext:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), stop]];
            [deps getDeparturesForStopId:stop];
            deps.sectionTitle = NSLocalizedString(@"Departure", @"");
            [taskState taskItemsDone:2];
        }
        
        self->_blockFilter = true;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.title = NSLocalizedString(@"Trip", @"");
        });
        
        [self sortByBus];
        
        return self;
    }];
}

- (void)fetchTimesViaQrCodeRedirectAsync:(id<TaskController>)taskController
                                     URL:(NSString *)url {
    [taskController taskRunAsync:^(TaskState *taskState) {
        [taskState taskStartWithTotal:2 title:kGettingArrivals];
        
        [taskState taskSubtext:NSLocalizedString(@"getting stop ID", @"progress message")];
        
        ProcessQRCodeString *qrCode = [[ProcessQRCodeString alloc] init];
        NSString *stopId = [qrCode extractStopId:url];
        
        [taskState taskItemsDone:1];
        
        [self clearSections];
        [XMLDepartures clearCache];
        self.stopIds = stopId;
        self.xml = [NSMutableArray array];
        
        static NSString *streetcar = @"www.portlandstreetcar.org";
        
        if (!taskState.taskCancelled && stopId) {
            XMLDepartures *deps = [XMLDepartures xmlWithOneTimeDelegate:taskState sharedDetours:self.allDetours sharedRoutes:self.allRoutes];
        
            [self.xmlDepartures addObject:deps];
            [taskState taskSubtext:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@", @"TriMet Stop identifer <number>"), stopId]];
            [deps getDeparturesForStopId:stopId];
            XML_DEBUG_RAW_DATA(deps);
            [taskState taskItemsDone:2];
        } else if ([url hasPrefix:streetcar]) {
            [taskState taskCancel];
            [taskState taskSetErrorMsg:NSLocalizedString(@"That QR Code is for the Portland Streetcar web site - there should be another QR code close by that has the stop ID.",
                                                         @"error message")];
        } else {
            [taskState taskCancel];
            [taskState taskSetErrorMsg:NSLocalizedString(@"The QR Code is not for a TriMet stop.", @"error message")];
        }
        
        self->_blockFilter = false;
        [self sortByBus];
        return (UIViewController *)self;
    }];
}

#pragma mark UI Helper functions


- (UITableViewCell *)distanceCellWithReuseIdentifier:(NSString *)identifier {
    CGRect rect;
    
    UITableViewCell *cell = [self tableView:self.table cellWithReuseIdentifier:identifier];
    
#define LEFT_COLUMN_OFFSET 10.0
#define LEFT_COLUMN_WIDTH  260
    
#define MAIN_FONT_SIZE     16.0
#define LABEL_HEIGHT       26.0
    
    if ([cell viewWithTag:DISTANCE_TAG] == nil) {
        /*
         Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
         */
        UILabel *label;
        
        rect = CGRectMake(LEFT_COLUMN_OFFSET, (kDepartureCellHeight / 2.0 - LABEL_HEIGHT) / 2.0, LEFT_COLUMN_WIDTH, LABEL_HEIGHT);
        label = [[UILabel alloc] initWithFrame:rect];
        label.tag = DISTANCE_TAG;
        label.font = [UIFont boldMonospacedDigitSystemFontOfSize:MAIN_FONT_SIZE];
        label.adjustsFontSizeToFitWidth = YES;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        [cell.contentView addSubview:label];
        label.highlightedTextColor = [UIColor whiteColor];
        label.textColor = [UIColor modeAwareBlue];
        
        
        rect = CGRectMake(LEFT_COLUMN_OFFSET, kDepartureCellHeight / 2.0 + (kDepartureCellHeight / 2.0 - LABEL_HEIGHT) / 2.0, LEFT_COLUMN_WIDTH, LABEL_HEIGHT);
        label = [[UILabel alloc] initWithFrame:rect];
        label.tag = ACCURACY_TAG;
        label.font = [UIFont monospacedDigitSystemFontOfSize:MAIN_FONT_SIZE];
        label.adjustsFontSizeToFitWidth = YES;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        [cell.contentView addSubview:label];
        label.highlightedTextColor = [UIColor whiteColor];
        label.textColor = [UIColor modeAwareBlue];
    }
    
    return cell;
}

#pragma mark UI Callback methods


- (void)detailsChanged {
    _reloadWhenAppears = YES;
}

- (void)refreshAction:(id)sender {
    if (!self.backgroundTask.running) {
        [super refreshAction:sender];
        
        if (self.table.hidden || self.backgroundTask.progressModal != nil) {
            return;
        }
        
        DEBUG_LOG(@"Refreshing\n");
        
        [self fetchAgainAsync:self.backgroundTask];
    }
}

- (bool)needtoFetchStreetcarLocations:(NSArray<XMLDepartures *> *)xmlDeps {
    for (XMLDepartures *deps in xmlDeps) {
        if (deps.loc != nil) {
            for (int j = 0; j < deps.count; j++) {
                Departure *departure = deps[j];
                
                if (departure.streetcar && departure.blockPosition == nil) {
                    return YES;
                    
                    break;
                }
            }
        }
    }
    
    return NO;
}

- (void)subTaskFetchStreetcarLocations:(TaskState *)taskState {
    NSSet<NSString *> *streetcarRoutes = [XMLStreetcarLocations getStreetcarRoutesInXMLDeparturesArray:self.xmlDepartures];
    
    for (XMLDepartures *deps in self.xmlDepartures) {
        // First get the arrivals via next bus to see if we can get the correct vehicle ID
        XMLStreetcarPredictions *streetcarArrivals = [XMLStreetcarPredictions xmlWithOneTimeDelegate:taskState];
        
        [streetcarArrivals getDeparturesForStopId:deps.stopId];
        
        for (NSInteger i = 0; i < streetcarArrivals.count; i++) {
            Departure *vehicle = streetcarArrivals[i];
            
            for (Departure *departure in deps.items) {
                if ([vehicle.block isEqualToString:departure.block]) {
                    departure.streetcarId = vehicle.streetcarId;
                    departure.vehicleIds = [vehicle vehicleIdsForStreetcar];
                    break;
                }
            }
        }
        
        [taskState incrementItemsDoneAndDisplay];
    }
    
    for (NSString *route in streetcarRoutes) {
        XMLStreetcarLocations *locs = [XMLStreetcarLocations sharedInstanceForRoute:route];
        locs.oneTimeDelegate = taskState;
        [locs getLocations];
        XML_DEBUG_RAW_DATA(locs);
        [taskState incrementItemsDoneAndDisplay];
    }
    
    [XMLStreetcarLocations insertLocationsIntoXmlDeparturesArray:self.xmlDepartures forRoutes:streetcarRoutes];
}

- (void)showMapNow:(id)sender {
    MapViewWithRoutes *mapPage = [MapViewWithRoutes viewController];
    
    mapPage.stopIdStringCallback = self.stopIdStringCallback;
    bool needStreetcarLocations = NO;
    NSInteger additonalTasks = 1;
    
    if (_blockFilter) {
        mapPage.title = NSLocalizedString(@"Stops & Departures", @"screen title");
        
        needStreetcarLocations = [self needtoFetchStreetcarLocations:self.xmlDepartures];
        
        if (needStreetcarLocations) {
            NSSet<NSString *> *streetcarRoutes = [XMLStreetcarLocations getStreetcarRoutesInXMLDeparturesArray:self.xmlDepartures];
            additonalTasks = 1 + streetcarRoutes.count + ((int)self.xmlDepartures.count * (int)streetcarRoutes.count);
        }
    } else {
        mapPage.title = NSLocalizedString(@"Stops", @"screen title");
    }
    
    NSMutableArray<NSString *> *routes = [NSMutableArray array];
    NSMutableArray<NSString *> *directions = [NSMutableArray array];
    
    for (XMLDepartures *deps in self.xmlDepartures)
    {
        for (Departure *departure in deps)
        {
            bool found = NO;
            for (int i=0; i < routes.count; i++)
            {
                if ([routes[i] isEqualToString:departure.route] && [directions[i] isEqualToString:departure.dir])
                {
                    found = YES;
                    break;
                }
            }
            
            if (!found)
            {
                [routes addObject:departure.route];
                [directions addObject:departure.dir];
            }
        }
    }
    
    
    [mapPage fetchRoutesAsync:self.backgroundTask
                       routes:routes
                   directions:directions
              additionalTasks:additonalTasks
                         task:^(TaskState *taskState) {
        if (needStreetcarLocations) {
            [self subTaskFetchStreetcarLocations:taskState];
        } else {
            [taskState incrementItemsDoneAndDisplay];
        }
        
        long i, j;
        
        NSMutableSet *blocks = [NSMutableSet set];
        
        bool found = NO;
        
        for (i = self.xmlDepartures.count - 1; i >= 0; i--) {
            XMLDepartures *deps   = self.xmlDepartures[i];
            
            if (deps.loc != nil) {
                [mapPage addPin:deps];
                
                if (self->_blockFilter) {
                    for (j = 0; j < deps.count; j++) {
                        Departure *departure = deps[j];
                        
                        if (departure.hasBlock && ![blocks containsObject:departure.block] && departure.blockPosition != nil) {
                            [mapPage addPin:departure];
                            [blocks addObject:departure.block];
                        }
                        
                        if (departure.hasBlock && departure.blockPosition != nil) {
                            found = NO;
                            
                            for (int i = 0; i < routes.count; i++) {
                                if ([routes[i] isEqualToString:departure.route]
                                    && [directions[i] isEqualToString:departure.dir]) {
                                    found = YES;
                                    break;
                                }
                            }
                            
                            if (!found) {
                                [routes addObject:departure.route];
                                [directions addObject:departure.dir];
                            }
                        }
                    }
                }
            }
        }
    }];
}

- (bool)needtoFetchStreetcarLocationsForStop:(XMLDepartures *)dep {
    bool needToFetchStreetcarLocations = false;
    
    if (dep.loc != nil) {
        for (int j = 0; j < dep.count; j++) {
            Departure *departure = dep[j];
            
            if (departure.streetcar && departure.blockPosition == nil) {
                needToFetchStreetcarLocations = true;
                break;
            }
        }
    }
    
    return needToFetchStreetcarLocations;
}

- (void)showMap:(id)sender {
    [self showMapNow:nil];
}

- (void)sortButton:(id)sender {
    DepartureSortTableView *options = [DepartureSortTableView viewController];
    
    options.depView = self;
    
    [self.navigationController pushViewController:options animated:YES];
}

- (void)bookmarkButton:(UIBarButtonItem *)sender {
    NSMutableString *stopId = [NSMutableString string];
    NSMutableString *desc   = [NSMutableString string];
    int i;
    
    if (self.xmlDepartures.count == 1) {
        XMLDepartures *deps = self.xmlDepartures.firstObject;
        
        if ([self validStopDataProvider:deps]) {
            [stopId appendFormat:@"%@", deps.stopId];
            [desc appendFormat:@"%@", deps.locDesc];
        } else {
            return;
        }
    } else {
        XMLDepartures *deps = self.xmlDepartures.firstObject;
        [stopId appendFormat:@"%@", deps.stopId];
        [desc appendFormat:NSLocalizedString(@"Stop IDs: %@", @"A list of TriMet stop IDs"), deps.stopId];
        
        for (i = 1; i < self.xmlDepartures.count; i++) {
            XMLDepartures *deps = self.xmlDepartures[i];
            [stopId appendFormat:@",%@", deps.stopId];
            [desc appendFormat:@",%@", deps.stopId];
        }
    }
    
    int bookmarkItem = kNoBookmark;
    
    @synchronized (_userState) {
        for (i = 0; _userState.faves != nil &&  i < _userState.faves.count; i++) {
            NSDictionary *bm = _userState.faves[i];
            NSString *faveLoc = (NSString *)bm[kUserFavesLocation];
            
            if (bm != nil && faveLoc != nil && [faveLoc isEqualToString:stopId]) {
                bookmarkItem = i;
                desc = bm[kUserFavesChosenName];
                break;
            }
        }
    }
    
    if (bookmarkItem == kNoBookmark) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Bookmark", @"action list title")
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Add new bookmark", @"button text")
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
            EditBookMarkView *edit = [EditBookMarkView viewController];
            [edit addBookMarkFromStop:desc stopId:stopId];
            // Push the detail view controller
            [self.navigationController pushViewController:edit animated:YES];
        }]];
#if !TARGET_OS_MACCATALYST
        [alert addAction:[UIAlertAction actionWithTitle:kAddBookmarkToSiri
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
            [self addBookmarkToSiri];
        }]];
#endif
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"button text") style:UIAlertActionStyleCancel handler:nil]];
        
        
        
        alert.popoverPresentationController.barButtonItem = sender;
        
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:desc
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Delete this bookmark", @"button text")
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction *action) {
            [self->_userState.faves removeObjectAtIndex:bookmarkItem];
            [self favesChanged];
            [self->_userState cacheState];
        }]];
#if !TARGET_OS_MACCATALYST
        [alert addAction:[UIAlertAction actionWithTitle:kAddBookmarkToSiri
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
            [self addBookmarkToSiri];
        }]];
#endif
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Edit this bookmark", @"button text")
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
            EditBookMarkView *edit = [EditBookMarkView viewController];
            @synchronized (self->_userState) {
                [edit editBookMark:self->_userState.faves[bookmarkItem] item:bookmarkItem];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat result;
    id<DepartureTimesDataProvider> dd = self.visibleDepartures[indexPath.section];
    NSIndexPath *newIndexPath = [self subsection:indexPath];
    
    
    switch (newIndexPath.section) {
        case kSectionTimes:
            
            if (dd.depGetSafeItemCount == 0 && newIndexPath.row == 0 && !_blockFilter) {
                result = kNonDepartureHeight;
            } else {
                result = UITableViewAutomaticDimension;
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
            
            if (dd.depDistance.accuracy > 0.0) {
                return kDepartureCellHeight;
            } else {
                return [self narrowRowHeight];
            }
            
        default:
            result = [self narrowRowHeight];
            break;
    }
    
    return result;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.visibleDepartures.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    SectionRows *sr = [self calcSubsections:section];
    
    if ([self validStop:section] && !_blockSort) {
        id<DepartureTimesDataProvider> dd = self.visibleDepartures[section];
        [_userState addToRecentsWithStopId:dd.depStopId
                               description:dd.depGetSectionHeader];
    }
    
    //DEBUG_LOG(@"Section: %ld rows %ld expanded %d\n", (long)section, (long)sr->row[kSectionsPerStop-1],
    //          (int)_sectionExpanded[section]);
    
    
    return sr[kSectionsPerStop - 1].integerValue;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id<DepartureTimesDataProvider> dd = self.visibleDepartures[section];
    
    return dd.depGetSectionHeader;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell.reuseIdentifier isEqualToString:kActionCellId]) {
        // cell.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
        
        cell.backgroundColor = [UIColor modeAwareCellBackground];
    } else {
        [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    header.textLabel.adjustsFontSizeToFitWidth = YES;
    header.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    header.accessibilityLabel = header.textLabel.text.phonetic;
}

- (UITableViewCell *)actionCell:(UITableView *)tableView
                          image:(UIImage *)image
                           text:(NSString *)text
                      accessory:(UITableViewCellAccessoryType)accType {
    UITableViewCell *cell = [self tableView:tableView cellWithReuseIdentifier:kActionCellId];
    
    cell.textLabel.font = self.basicFont;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.textLabel.textColor = [UIColor modeAwareGrayText];
    cell.imageView.image = image;
    cell.textLabel.text = text;
    cell.accessoryType = accType;
    [self updateAccessibility:cell];
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    id<DepartureTimesDataProvider> dd = self.visibleDepartures[indexPath.section];
    NSIndexPath *newIndexPath = [self subsection:indexPath];
    
    switch (newIndexPath.section) {
        case kSectionSystemAlert: {
            Detour *detour = dd.depDetour;
            DetourTableViewCell *dcell = [self.table dequeueReusableCellWithIdentifier:detour.reuseIdentifer];
            
            [dcell populateCell:detour route:nil];
            
            __weak __typeof__(self) weakSelf = self;
            
            dcell.buttonCallback = ^(DetourTableViewCell *cell, NSInteger tag) {
                [weakSelf detourAction:cell.detour buttonType:tag indexPath:indexPath reloadSection:NO];
            };
            
            dcell.urlCallback = self.detourActionCalback;
            
            cell = dcell;
            break;
        }
            
        case kSectionDistance: {
            bool twoLines = (dd.depDistance.accuracy > 0.0);
            
            if (twoLines) {
                cell = [self distanceCellWithReuseIdentifier:kDistanceCellId2];
                
                NSString *distance = [NSString stringWithFormat:NSLocalizedString(@"Distance %@", @"stop distance"), [FormatDistance formatMetres:dd.depDistance.distanceMeters]];
                ((UILabel *)[cell.contentView viewWithTag:DISTANCE_TAG]).text = distance;
                UILabel *accuracy = (UILabel *)[cell.contentView viewWithTag:ACCURACY_TAG];
                accuracy.text = [NSString stringWithFormat:NSLocalizedString(@"Accuracy +/- %@", @"accuracy of location services"), [FormatDistance formatMetres:dd.depDistance.accuracy]];
                cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", distance, accuracy.text];
            } else {
                cell = [self tableView:tableView cellWithReuseIdentifier:kDistanceCellId];
                
                cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Distance %@", @"stop distance"), [FormatDistance formatMetres:dd.depDistance.distanceMeters]];
                cell.textLabel.textColor = [UIColor modeAwareBlue];
                cell.textLabel.font = self.basicFont;;
                cell.accessibilityLabel = cell.textLabel.text;
            }
            
            cell.imageView.image = nil;
            break;
        }
            
        case kSectionTimes: {
            int i = (int)newIndexPath.row;
            NSInteger deps = dd.depGetSafeItemCount;
            
            if (deps == 0 && i == 0) {
                cell = [self tableView:tableView cellWithReuseIdentifier:kStatusCellId];
                
                if (_blockFilter) {
                    cell.textLabel.text = NSLocalizedString(@"No departure data for that particular trip.", @"error message");
                    cell.textLabel.adjustsFontSizeToFitWidth = NO;
                    cell.textLabel.numberOfLines = 0;
                    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
                    cell.textLabel.font = self.smallFont;
                } else {
                    cell.textLabel.text = [NSString stringWithFormat:NSLocalizedString(@"(ID %@) No departures found.", @"No departures for a specific TriMet stop ID"), dd.depStopId];
                    cell.textLabel.font = self.basicFont;
                }
                
                cell.accessoryType = UITableViewCellAccessoryNone;
                
                [self updateAccessibility:cell];
                break;
            } else {
                Departure *departure = [dd depGetDeparture:newIndexPath.row];
                DepartureCell *dcell = [DepartureCell tableView:tableView cellWithReuseIdentifier:MakeCellId(kSectionTimes) tallRouteLabel:NO];
                
                [dd depPopulateCell:departure cell:dcell decorate:YES wide:LARGE_SCREEN];
                // [departure populateCell:cell decorate:YES big:YES];
                
                cell = dcell;
            }
            
            cell.imageView.image = nil;
            break;
        }
            
        case kSectionDetours: {
            NSInteger i = newIndexPath.row;
            NSNumber *detourId = dd.depDetoursPerSection[i];
            Detour *det = self.allDetours[detourId];
            
            if (det != nil) {
                DetourTableViewCell *dcell = [self.table dequeueReusableCellWithIdentifier:det.reuseIdentifer];
                dcell.includeHeaderInDescription = YES;
                [dcell populateCell:det route:nil];
                
                
                __weak __typeof__(self) weakSelf = self;
                
                dcell.buttonCallback = ^(DetourTableViewCell *cell, NSInteger tag) {
                    [weakSelf detourAction:cell.detour buttonType:tag indexPath:indexPath reloadSection:NO];
                };
                
                dcell.urlCallback = self.detourActionCalback;
                
                cell = dcell;
            } else {
                cell = [self tableView:tableView multiLineCellWithReuseIdentifier:det.reuseIdentifer];
                NSString *text = @"#D#RThe detour description is missing. ☹️";
                cell.textLabel.attributedText = text.smallAttributedStringFromMarkUp;
                cell.textLabel.accessibilityLabel = text.removeMarkUp.phonetic;
                cell.accessoryView = nil;
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            
            break;
        }
            
            
        case kSectionStatic:
            
            cell = [self disclaimerCell:tableView];
            if (newIndexPath.row == 0) {
                if (dd.depNetworkError) {
                    if (dd.depErrorMsg) {
                        [self addTextToDisclaimerCell:cell
                                                 text:kNetworkMsg];
                    } else {
                        [self addTextToDisclaimerCell:cell text:
                         [NSString stringWithFormat:kNoNetworkID, dd.depStopId]];
                    }
                } else if ([self validStop:indexPath.section]) {
                    [self addTextToDisclaimerCell:cell text:[NSString stringWithFormat:NSLocalizedString(@"%@ Updated: %@", @"text followed by time data was fetched"),
                                                             dd.depStaticText,
                                                             [NSDateFormatter localizedStringFromDate:dd.depQueryTime
                                                                                            dateStyle:NSDateFormatterNoStyle
                                                                                            timeStyle:NSDateFormatterMediumStyle]]];
                } else {
                    [self addTextToDisclaimerCell:cell text:@""];
                }
                
                if (dd.depNetworkError) {
                    cell.accessoryView = nil;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                } else if (dd.depHasDetails) {
                    UIButton *button = [[UIButton alloc] init];
                    button.frame = CGRectMake(0, 0, ACCESSORY_BUTTON_SIZE, ACCESSORY_BUTTON_SIZE);
                    
                    [button setImage:(self.sectionExpanded[indexPath.section].boolValue
                                      ? [Icons getModeAwareIcon:kIconCollapse7]
                                      : [Icons getModeAwareIcon:kIconExpand7]) forState:UIControlStateNormal];
                    button.userInteractionEnabled = NO;
                    cell.accessoryView = button;
                    
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                } else {
                    cell.accessoryView = nil;
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                }
                
                // Check disclaimers
                Departure *dep = nil;
                NSString *streetcarDisclaimer = nil;
                
                for (int i = 0; i < dd.depGetSafeItemCount && streetcarDisclaimer == nil; i++) {
                    dep = [dd depGetDeparture:i];
                    
                    if (dep.streetcar && dep.copyright != nil) {
                        streetcarDisclaimer = dep.copyright;
                    }
                }
                
                [self addStreetcarTextToDisclaimerCell:cell text:streetcarDisclaimer trimetDisclaimer:YES];
                
                [self updateDisclaimerAccessibility:cell];
            }
            break;
            
        case kSectionNearby:
            cell = [self actionCell:tableView
                              image:[Icons getModeAwareIcon:kIconLocate7]
                               text:NSLocalizedString(@"Nearby stops", @"button text")
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
            
            break;
            
        case kSectionSiri: {
            cell = [self actionCell:tableView
                              image:[Icons getIcon:kIconSiri]
                               text:NSLocalizedString(@"Add this stop to Siri", @"button text")
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
    
            break;
        }
            
        case kSectionOneStop:
            cell = [self actionCell:tableView
                              image:[Icons getIcon:kIconArrivals]
                               text:NSLocalizedString(@"Show only this stop", @"button text")
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
            
            break;
            
        case kSectionInfo:
            cell = [self actionCell:tableView
                              image:[Icons getIcon:kIconTriMetLink]
                               text:[NSString stringWithFormat:NSLocalizedString(@"Stop ID %@ info", @"button text"), dd.depStopId]
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
            
            break;
            
        case kSectionStation:
            cell = [self actionCell:tableView
                              image:[Icons getIcon:kIconRailStations]
                               text:NSLocalizedString(@"Rail station details", @"button text")
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
            break;
            
        case kSectionOpposite:
            cell = [self actionCell:tableView
                              image:[Icons getIcon:kIconArrivals]
                               text:NSLocalizedString(@"Departures going the other way ", @"button text")
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
            break;
            
        case kSectionVehicles:
            cell = [self actionCell:tableView
                              image:[Icons getIcon:kIconArrivals]
                               text:NSLocalizedString(@"Nearby vehicles ", @"button text")
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
            break;
            
        case kSectionNoDeeper:
            cell = [self actionCell:tableView
                              image:[Icons getIcon:kIconCancel]
                               text:NSLocalizedString(@"Too many windows open", @"button text")
                          accessory:UITableViewCellAccessoryNone];
            break;
            
        case kSectionFilter:
            cell = [self actionCell:tableView
                              image:[Icons getModeAwareIcon:kIconLocate7]
                               text:self.savedBlock ? NSLocalizedString(@"Show one departure", @"button text")
                                   : NSLocalizedString(@"Show all departures", @"button text")
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
            break;
            
        case kSectionProximity: {
            AlarmTaskList *taskList = [AlarmTaskList sharedInstance];
            NSString *text = nil;
            
            if ([taskList hasTaskForStopIdProximity:dd.depStopId]) {
                text = NSLocalizedString(@"Cancel proximity alarm", @"button text");
            } else if ([UIViewController locationAuthorizedOrNotDeterminedWithBackground:YES]) {
                text = kUserProximityCellText;
            } else {
                text = kUserProximityDeniedCellText;
            }
            
            cell = [self actionCell:tableView
                              image:[Icons getIcon:kIconAlarm]
                               text:text
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
            break;
        }
            
        case kSectionTrip: {
            NSString *text = nil;
            
            if (newIndexPath.row == kTripRowFrom) {
                text = NSLocalizedString(@"Plan a trip from here", @"button text");
            } else {
                text = NSLocalizedString(@"Plan a trip to here", @"button text");
            }
            
            cell = [self actionCell:tableView
                              image:[Icons getIcon:kIconTripPlanner]
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
                              image:[Icons getIcon:kIconLink]
                               text:NSLocalizedString(@"Check TriMet web site", @"button text")
                          accessory:UITableViewCellAccessoryDisclosureIndicator];
            break;
            
        default:
            cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)table siriButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    ArrivalsIntent *intent = [[ArrivalsIntent alloc] init];
    id<DepartureTimesDataProvider> dd = self.visibleDepartures[indexPath.section];
    XMLDepartures *deps = dd.depXML;
    
    intent.suggestedInvocationPhrase = [NSString stringWithFormat:@"TriMet departures at %@", deps.locDesc];
    intent.stops = deps.stopId;
    intent.locationName = deps.locDesc;
    
    INShortcut *shortCut = [[INShortcut alloc] initWithIntent:intent];
    
    INUIAddVoiceShortcutViewController *viewController = [[INUIAddVoiceShortcutViewController alloc] initWithShortcut:shortCut];
    viewController.modalPresentationStyle = UIModalPresentationFormSheet;
    viewController.delegate = self;
    
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)addBookmarkToSiri {
    INShortcut *shortCut = [[INShortcut alloc] initWithUserActivity:self.userActivity];
    
    INUIAddVoiceShortcutViewController *viewController = [[INUIAddVoiceShortcutViewController alloc] initWithShortcut:shortCut];
    viewController.modalPresentationStyle = UIModalPresentationFormSheet;
    viewController.delegate = self;
    
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<DepartureTimesDataProvider> dd = self.visibleDepartures[indexPath.section];
    NSIndexPath *newIndexPath = [self subsection:indexPath];
    
    switch (newIndexPath.section) {
        case kSectionTimes: {
            if (dd.depGetSafeItemCount != 0 && newIndexPath.row < dd.depGetSafeItemCount) {
                Departure *departure = [dd depGetDeparture:newIndexPath.row];
                
                // if (departure.hasBlock || departure.detour)
                if (departure.errorMessage == nil) {
                    DepartureDetailView *departureDetailView = [DepartureDetailView viewController];
                    departureDetailView.stopIdStringCallback = self.stopIdStringCallback;
                    departureDetailView.delegate = self;
                    
                    departureDetailView.navigationItem.prompt = self.navigationItem.prompt;
                    
                    if (depthCount < kMaxDepth && self.visibleDepartures.count > 1) {
                        departureDetailView.stops = self.stopIds;
                    }
                    
                    departureDetailView.allowBrowseForDestination = ((!_blockFilter) || Settings.vehicleLocations) && depthCount < kMaxDepth;
                    
                    [departureDetailView fetchDepartureAsync:self.backgroundTask dep:departure allDepartures:self.xmlDepartures backgroundRefresh:NO];
                }
            }
            
            break;
        }
            
        case kSectionTrip: {
            TripPlannerSummaryView *tripPlanner = [TripPlannerSummaryView viewController];
            
            @synchronized (_userState) {
                [tripPlanner.tripQuery addStopsFromUserFaves:_userState.faves];
            }
            
            // Push the detail view controller
            
            TripEndPoint *endpoint = nil;
            
            if (newIndexPath.row == kTripRowFrom) {
                endpoint = tripPlanner.tripQuery.userRequest.fromPoint;
            } else {
                endpoint = tripPlanner.tripQuery.userRequest.toPoint;
            }
            
            endpoint.useCurrentLocation = false;
            endpoint.additionalInfo = dd.depLocDesc;
            endpoint.locationDesc = dd.depStopId;
            
            
            [self.navigationController pushViewController:tripPlanner animated:YES];
            break;
        }
            
        case kSectionProximity: {
            AlarmTaskList *taskList = [AlarmTaskList sharedInstance];
            
            if ([taskList hasTaskForStopIdProximity:dd.depStopId]) {
                [taskList cancelTaskForStopIdProximity:dd.depStopId];
            } else if ([UIViewController locationAuthorizedOrNotDeterminedWithBackground:YES]) {
                id<DepartureTimesDataProvider> dd = self.visibleDepartures[indexPath.section];
                
                [taskList userAlertForProximity:self source:[tableView cellForRowAtIndexPath:indexPath]
                                     completion:^(bool cancelled, bool accurate) {
                    if (!cancelled) {
                        [taskList addTaskForStopIdProximity:dd.depStopId loc:dd.depLocation desc:dd.depLocDesc accurate:accurate];
                        [self reloadData];
                    }
                }];
            } else {
                [self locationAuthorizedOrNotDeterminedAlertWithBackground:YES];
            }
            
            [self reloadData];
            break;
        }
            
        case kSectionNearby: {
            FindByLocationView *find = [[FindByLocationView alloc] initWithLocation:dd.depLocation description:dd.depLocDesc];
            
            [self.navigationController pushViewController:find animated:YES];
            
            break;
        }
            
        case kSectionSiri:
            [self tableView:self.table siriButtonTappedForRowWithIndexPath:indexPath];
            break;
            
        case kSectionInfo: {
            [WebViewController displayNamedPage:@"TriMet Stop Info"
                                      parameter:dd.depStopId
                                      navigator:self.navigationController
                                 itemToDeselect:self
                                       whenDone:nil];
            
            break;
        }
            
        case kSectionSystemAlert:
            [self detourToggle:dd.depDetour indexPath:indexPath reloadSection:YES];
            break;
            
        case kSectionStation: {
            {
                RailStation *station = [AllRailStationView railstationFromStopId:dd.depStopId];
                
                if (station == nil) {
                    return;
                }
                
                RailStationTableView *railView = [RailStationTableView viewController];
                railView.station = station;
                railView.stopIdStringCallback = self.stopIdStringCallback;
                
                [railView maybeFetchRouteShapesAsync:self.backgroundTask];
            }
            
            break;
        }
            
        case kSectionOpposite: {
            DepartureTimesView *opposite = [DepartureTimesView viewController];
            opposite.stopIdStringCallback = self.stopIdStringCallback;
            [opposite fetchTimesForStopInOtherDirectionAsync:self.backgroundTask departures:dd.depXML];
            break;
        }
            
        case kSectionVehicles: {
            [[VehicleTableView viewController] fetchNearestVehiclesAsync:self.backgroundTask
                                                                location:dd.depLocation
                                                             maxDistance:Settings.vehicleLocatorDistance
                                                       backgroundRefresh:NO
             ];
            break;
        }
            
        case kSectionNoDeeper:
            [self.navigationController popViewControllerAnimated:YES];
            break;
            
        case kSectionAccuracy:
            [WebViewController displayNamedPage:@"TriMet Arrivals"
                                      parameter:dd.depStopId
                                      navigator:self.navigationController
                                 itemToDeselect:self
                                       whenDone:nil];
            
            break;
    
        case kSectionOneStop: {
            DepartureTimesView *departureViewController = [DepartureTimesView viewController];
            
            departureViewController.stopIdStringCallback = self.stopIdStringCallback;
            [departureViewController fetchTimesForLocationAsync:self.backgroundTask
                                                         stopId:dd.depStopId
                                                          title:dd.depLocDesc];
            break;
        }
            
        case kSectionFilter: {
            if ([dd respondsToSelector:@selector(depXML)]) {
                XMLDepartures *deps = (XMLDepartures *)dd.depXML;
                
                if (self.savedBlock) {
                    deps.blockFilter = self.savedBlock;
                    self.savedBlock = nil;
                } else {
                    self.savedBlock = deps.blockFilter;
                    deps.blockFilter = nil;
                }
                
                [self refreshAction:nil];
            }
            
            [self.table deselectRowAtIndexPath:indexPath animated:YES];
            break;
        }
            
        case kSectionStatic: {
            if (dd.depNetworkError) {
                [self networkTips:dd.depHtmlError networkError:dd.depErrorMsg];
                [self clearSelection];
            } else if (!_blockSort) {
                int sect = (int)indexPath.section;
                [self.table deselectRowAtIndexPath:indexPath animated:YES];
                self.sectionExpanded[sect] = self.sectionExpanded[sect].boolValue ? @NO : @YES;
                
                
                // copy this struct
                SectionRows *oldRows = self.sectionRows[sect].copy;
                
                SectionRows *newRows = self.sectionRows[sect];
                
                newRows[0] = @(kSectionRowInit);
                
                [self calcSubsections:sect];
                
                NSMutableArray *changingRows = [NSMutableArray array];
                
                int row;
                
                SectionRows *additionalRows;
                
                if (self.sectionExpanded[sect].boolValue) {
                    additionalRows = newRows;
                } else {
                    additionalRows = oldRows;
                }
                
                for (int i = 0; i < kSectionsPerStop; i++) {
                    // DEBUG_LOG(@"index %d\n",i);
                    // DEBUG_LOG(@"row %d\n", newRows->row[i+1]-newRows->row[i]);
                    // DEBUG_LOG(@"old row %d\n", oldRows.row[i+1]-oldRows.row[i]);
                    
                    if (newRows[i + 1].integerValue - newRows[i].integerValue != oldRows[i + 1].integerValue - oldRows[i].integerValue) {
                        for (row = additionalRows[i].intValue; row < additionalRows[i + 1].intValue; row++) {
                            [changingRows addObject:[NSIndexPath indexPathForRow:row
                                                                       inSection:sect]];
                        }
                    }
                }
                
                UITableViewCell *staticCell = [self.table cellForRowAtIndexPath:indexPath];
                
                if (staticCell != nil) {
                    UIButton *button = [[UIButton alloc] init];
                    button.frame = CGRectMake(0, 0, ACCESSORY_BUTTON_SIZE, ACCESSORY_BUTTON_SIZE);
                    [button setImage:self.sectionExpanded[indexPath.section].boolValue
                     ? [Icons getModeAwareIcon:kIconCollapse7]
                                    : [Icons getModeAwareIcon:kIconExpand7] forState:UIControlStateNormal];
                    button.userInteractionEnabled = NO;
                    staticCell.accessoryView = button;
                    [staticCell setNeedsDisplay];
                }
                
                [self.table beginUpdates];
                
                if (self.sectionExpanded[sect].boolValue) {
                    [self.table insertRowsAtIndexPaths:changingRows withRowAnimation:UITableViewRowAnimationRight];
                } else {
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
    
    [self.table registerNib:[DetourTableViewCell nib] forCellReuseIdentifier:kSystemDetourResuseIdentifier];
    [self.table registerNib:[DetourTableViewCell nib] forCellReuseIdentifier:kDetourResuseIdentifier];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //Configure and enable the accelerometer
    
    [self cacheWarningRefresh:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    DEBUG_FUNC();
    
    // [UIView setAnimationsEnabled:NO];
    self.navigationItem.prompt = nil;
    // [UIView setAnimationsEnabled:YES];
    
    if (self.userActivity != nil) {
        [self.userActivity invalidate];
        self.userActivity = nil;
    }
    
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    DEBUG_FUNC();
    [super viewDidDisappear:animated];
}

#pragma mark TableViewWithToolbar methods

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    // match each of the toolbar item's style match the selection in the "UIBarButtonItemStyle" segmented control
    UIBarButtonItemStyle style = UIBarButtonItemStylePlain;
    
    // create the system-defined "OK or Done" button
    UIBarButtonItem *bookmark = [[UIBarButtonItem alloc]
                                 initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                                 target:self action:@selector(bookmarkButton:)];
    
    bookmark.style = style;
    
    
    
    [toolbarItems addObject:bookmark];
    [toolbarItems addObject:[UIToolbar flexSpace]];
    
    if (((!(_blockFilter || self.xmlDepartures.count == 1)) || _allowSort) && (Settings.groupByArrivalsIcon)) {
        UIBarButtonItem *sort = [[UIBarButtonItem alloc]
                                 // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                                 initWithImage:[Icons getToolbarIcon:kIconSort7]
                                 style:UIBarButtonItemStylePlain
                                 target:self action:@selector(sortButton:)];
        
        sort.accessibilityLabel = NSLocalizedString(@"Group Departures", @"Accessibility text");
        
        TOOLBAR_PLACEHOLDER(sort, @"G");
        
        [toolbarItems addObject:sort];;
        [toolbarItems addObject:[UIToolbar flexSpace]];
    }
    
    if (Settings.debugXML) {
        [toolbarItems addObject:[self debugXmlButton]];
        [toolbarItems addObject:[UIToolbar flexSpace]];
    }
    
    [toolbarItems addObject:[UIToolbar mapButtonWithTarget:self action:@selector(showMap:)]];
    
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

#pragma mark Accelerometer methods

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
    
    if (_reloadWhenAppears) {
        _reloadWhenAppears = NO;
        [self reloadData];
    }
    
    if (!_updatedWatch) {
        _updatedWatch = YES;
        [self updateWatch];
    }
    
    ;
    
    for (XMLDepartures *deps in self.xmlDepartures) {
        ArrivalsIntent *intent = [[ArrivalsIntent alloc] init];
        
        intent.suggestedInvocationPhrase = [NSString stringWithFormat:@"TriMet departures at %@", deps.locDesc];
        intent.stops = deps.stopId;
        
        if (deps.locDesc) {
            intent.locationName = deps.locDesc;
        }
        
        INInteraction *interaction = [[INInteraction alloc] initWithIntent:intent response:nil];
        
        [interaction donateInteractionWithCompletion:^(NSError *_Nullable error) {
            LOG_NSERROR(error);
        }];
    }
    
    Class userActivityClass = (NSClassFromString(@"NSUserActivity"));
    
    if (userActivityClass != nil) {
        NSMutableString *stopIds = [NSString commaSeparatedStringFromEnumerator:self.xmlDepartures selToGetString:@selector(stopId)];
        
        if (self.userActivity != nil) {
            [self.userActivity invalidate];
        }
        
        self.userActivity = [[NSUserActivity alloc] initWithActivityType:kHandoffUserActivityBookmark];
        
        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        
        if (self.xmlDepartures.count >= 1) {
            XMLDepartures *deps = self.xmlDepartures.firstObject;
            
            self.userActivity.webpageURL = [NSURL URLWithString:[WebViewController namedURL:@"TriMet Arrivals" param:deps.stopId]];
            
            if (self.xmlDepartures.count == 1 && deps.locDesc != nil) {
                info[kUserFavesChosenName] = deps.locDesc;
            } else if (self.bookmarkDesc != nil) {
                info[kUserFavesChosenName] = self.bookmarkDesc;
            } else {
                info[kUserFavesChosenName] = @"unknown stops";
            }
            
            if (self.bookmarkDesc != nil) {
                self.userActivity.title = [NSString stringWithFormat:kUserFavesDescription,  self.bookmarkDesc];
            } else {
                self.userActivity.title = [NSString stringWithFormat:@"Launch PDX Bus & show departures for stops %@",  stopIds];
            }
            
            self.userActivity.eligibleForSearch = YES;
            self.userActivity.eligibleForPrediction = YES;
        }
        
        info[kUserFavesLocation] = stopIds;
        self.userActivity.userInfo = info;
        [self.userActivity becomeCurrent];
    }
    
    [self iOS7workaroundPromptGap];
}

- (bool)neverAdjustContentInset {
    return YES;
}

- (void)handleChangeInUserSettingsOnMainThread:(NSNotification *)notification {
    [super handleChangeInUserSettingsOnMainThread:notification];
    [self stopTimer];
    [self startTimer];
}

#pragma mark BackgroundTask methods

- (void)reloadData {
    [super reloadData];
    [self cacheWarningRefresh:YES];
}

@end
