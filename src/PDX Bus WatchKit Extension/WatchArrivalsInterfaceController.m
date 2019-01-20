//
//  WatchArrivalsInterfaceController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/16/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchArrivalsInterfaceController.h"
#import "XMLDepartures.h"
#import "XMLDetours.h"
#import "WatchArrival.h"
#import "DepartureData+watchOSUI.h"
#import "XMLStreetcarLocations.h"
#import "TriMetInfo.h"
#import "WatchArrivalInfo.h"
#import "StopNameCacheManager.h"
#import "WatchMapHelper.h"
#import "UserFaves.h"
#import "WatchNoArrivals.h"
#import "WatchDetour.h"
#import "WatchArrivalMap.h"
#import "WatchArrivalScheduleInfo.h"
#import "Detour.h"
#import "DebugLogging.h"
#import "XMLLocateVehicles.h"
#import "FormatDistance.h"
#import "WatchNearbyInterfaceController.h"
#import "StringHelper.h"
#import "ArrivalColors.h"
#import "WatchSystemWideDetour.h"
#import "WatchSystemWideHeader.h"

#define kRefreshTime 30

@implementation WatchArrivalsInterfaceController

- (void)dealloc
{
    
    if (self.refreshTimer)
    {
        [self.refreshTimer invalidate];
    }
    
    
}

- (void)resetTitle
{
    if (self.arrivalsContext.stopDesc)
    {
        [self.stopDescription setText:self.arrivalsContext.stopDesc];
        self.stopDescription.hidden = NO;
        self.title = self.arrivalsContext.stopDesc;
    }
    else if (self.departures!=nil && self.departures.gotData)
    {
        self.stopDescription.hidden = YES;
        self.title = self.departures.locDesc;
    }
    else
    {
        self.title = @"Arrivals";
    }
}



- (void)loadTableWithDepartures:(XMLDepartures *)newDepartures detailedDeparture:(DepartureData*)newDetailDep
{
    bool extrapolate = (newDepartures == nil && self.diff > kStaleTime);
    bool mapShown = NO;
    self.loadingGroup.hidden = YES;

    self.navGroup.hidden = NO;
    
    if (self.arrivalsContext.navText)
    {
        if (self.arrivalsContext.hasNext)
        {
            self.nextButton.hidden = NO;
            [self.nextButton setTitle:self.arrivalsContext.navText];
        }
        else
        {
            self.nextButton.hidden = YES;
        }
    }
    else
    {
        self.nextButton.hidden = YES;
    }
    
    if (newDepartures == nil)
    {
        newDepartures = self.departures;
    }
    
    if (newDetailDep == nil)
    {
        newDetailDep = self.detailDeparture;
    }
    
    NSArray<DepartureData *> *deps = nil;
    
    if (newDetailDep)
    {
        deps = @[newDetailDep];
    }
    else
    {
        deps = newDepartures.items;
    }
    
    if (newDepartures.gotData && newDepartures.itemFromCache)
    {
        self.labelRefreshing.hidden = NO;
        self.labelRefreshing.text = @"Network error - extrapolated times";
    }
    //else if (extraploate)
    //{
    //    self.labelRefreshing.hidden = NO;
    //    self.labelRefreshing.text = @"Updating stale times";
    //}
    else
    {
        self.labelRefreshing.hidden = YES;
    }
    
    NSMutableArray<NSString *> *rowTypes   = [NSMutableArray array];
    NSMutableArray<NSNumber *> *rowIndices = [NSMutableArray array];
    
    switch (deps.count)
    {
        case 0:
            [rowTypes addObject:[WatchNoArrivals identifier]];
            [rowIndices addObject:@(0)];
            break;
        case 1:
        {
            DepartureData *first = deps.firstObject;
            if (first.errorMessage)
            {
                [rowTypes addObject:[WatchNoArrivals identifier]];
                [rowIndices addObject:@(0)];
            }
            else
            {
                for (NSInteger i=0; i<self.systemWideDetours.count; i++)
                {
                    [rowTypes addObject:[WatchSystemWideHeader identifier]];
                    [rowIndices addObject:self.systemWideDetours[i].detourId];
                }
                
                [rowTypes addObject:[WatchArrival identifier]];
                [rowIndices addObject:@(0)];
                if (extrapolate)
                {
                    [first extrapolateFromNow];
                }
            
                if (first.blockPosition!=nil && newDepartures.loc!=nil)
                {
                    [rowTypes addObject:[WatchArrivalMap identifier]];
                    [rowIndices addObject:@(0)];
                    mapShown = YES;
                }
                [rowTypes addObject:[WatchArrivalScheduleInfo identifier]];
                [rowIndices addObject:@(0)];
            
                self.detailDeparture = deps.firstObject;
                
                if (deps.firstObject.detours && deps.firstObject.detours.count > 0)
                {
                    NSInteger i;
                    DepartureData *first = deps.firstObject;
                    for (i=0; i< first.systemWideDetours; i++)
                    {
                        [rowTypes addObject:[WatchSystemWideDetour identifier]];
                        [rowIndices addObject:first.detours[i]];
                    }
                    
                    for (; i< first.detours.count; i++)
                    {
                        [rowTypes addObject:[WatchDetour identifier]];
                        [rowIndices addObject:first.detours[i]];
                    }
                }
            }
            break;
        }
        default:
        {
            for (Detour *det in self.systemWideDetours)
            {
                [rowTypes addObject:[WatchSystemWideHeader identifier]];
                [rowIndices addObject:det.detourId];
            }
            
            for (NSInteger i=0; i<deps.count; i++)
            {
                [rowTypes addObject:[WatchArrival identifier]];
                [rowIndices addObject:@(i)];
                if (extrapolate)
                {
                    [deps[i] extrapolateFromNow];
                }
            }
            
            for (Detour *det in self.systemWideDetours)
            {
                [rowTypes addObject:[WatchSystemWideDetour identifier]];
                [rowIndices addObject:det.detourId];
            }
            
            for (Detour *det in self.stopDetours)
            {
                [rowTypes addObject:[WatchDetour identifier]];
                [rowIndices addObject:det.detourId];
            }
            break;
        }
            
    }
    
    [rowTypes addObject:[WatchArrivalInfo identifier]];
    [rowIndices addObject:@(0)];
    
    if (self.arrivalsContext.showMap && newDepartures.loc !=nil && !mapShown)
    {
        [rowTypes addObject:[WatchArrivalMap identifier]];
        [rowIndices addObject:@(0)];
    }
    
    [self.arrivalsTable setRowTypes:rowTypes];
    
    self.departures = newDepartures;
    
    for (int i=0; i<self.arrivalsTable.numberOfRows; i++)
    {
        WatchRow *item = [self.arrivalsTable rowControllerAtIndex:i];
        item.index = rowIndices[i];
        [item populate:newDepartures departures:deps];
    }
    
    if (self.arrivalsContext.showDistance)
    {
        self.distanceLabel.text = [FormatDistance formatMetres:self.arrivalsContext.distance];
        
        self.distanceLabel.hidden = NO;
    }
    else
    {
        self.distanceLabel.hidden = YES;
    }
    
    if (newDepartures.gotData)
    {
        SafeUserData *userData = [SafeUserData sharedInstance];
        userData.readOnly = FALSE;
        NSString * longDesc = [NSString stringWithFormat:@"%@ (%@)", self.departures.locDesc, self.departures.locDir];
        NSDictionary *recent = [userData addToRecentsWithLocation:self.arrivalsContext.locid description:longDesc];
        
        if ([WCSession isSupported] && recent)
        {
            NSDictionary *userInfo = @{@"recent": recent};
            WCSession *session = [WCSession defaultSession];
            [session  activateSession];
            [session transferUserInfo:userInfo];
        }

        userData.readOnly = TRUE;
    }
    
    if (!extrapolate)
    {
        [self resetTitle];
    }
    else
    {
        self.title = @"Stale - Refreshing";
    }
}


- (NSTimeInterval)diff
{
    if (self.lastUpdate)
    {
        return -self.lastUpdate.timeIntervalSinceNow;
    }
    return 0;
}

- (void)startTimer
{
    NSTimeInterval diff = [self diff];
    
    // NSLog(@"Starting timer\n");
    
    if (self.departures != nil)
    {
        // NSLog(@"Starting timer diff %f\n", diff);

        
        if (diff >= kRefreshTime)
        {
            [self refresh:nil];
        }
        else
        {
            if (self.refreshTimer)
            {
                [self.refreshTimer invalidate];
            }
            
            self.refreshTimer  = [NSTimer scheduledTimerWithTimeInterval:kRefreshTime-diff
                                                                  target:self
                                                                selector:@selector(refresh:)
                                                                userInfo:nil
                                                                 repeats:NO];
        }
    }
}

- (void)taskFinishedMainThread:(id)result
{
    NSDictionary *data = result;
    
    if (data!=nil)
    {
    
        XMLDepartures *departures  = [data objectForKey:NSStringFromClass([XMLDepartures class])];
        DepartureData *detailedDep = [data objectForKey:NSStringFromClass([DepartureData class])];
    
        [self loadTableWithDepartures:departures detailedDeparture:detailedDep];
    }
    else
    {
        [self loadTableWithDepartures:nil detailedDeparture:nil];
    }
    
    [self startTimer];
}




- (void)TriMetXML:(TriMetXML*)xml startedFetchingData:(bool)fromCache
{
    if (!fromCache)
    {
        [self sendProgress:_tasksDone total:++_tasks];
    }
}

- (void)TriMetXML:(TriMetXML*)xml finishedFetchingData:(bool)fromCache
{
    if (!fromCache)
    {
        [self sendProgress:++_tasksDone total:_tasks];
    }
}


// static NSDate *startTime = nil;

#define kThreashold 2000

- (void)TriMetXML:(TriMetXML*)xml startedParsingData:(NSUInteger)size fromCache:(bool)fromCache
{
    // startTime = [[NSDate date] retain];
    
    if (size > kThreashold)
    {
        [self sendProgress:_tasksDone total:++_tasks];
    }
}

- (void)TriMetXML:(TriMetXML*)xml finishedParsingData:(NSUInteger)size fromCache:(bool)fromCache
{
   // NSTimeInterval parseTime = -startTime.timeIntervalSinceNow;
   // [startTime release];
   // startTime = nil;
    
   // DEBUG_LOGF(parseTime);
   DEBUG_LOGL(size);
   // DEBUG_LOGF(parseTime/(float)size);
    
    if (size > kThreashold)
    {
        [self sendProgress:++_tasksDone total:_tasks];
    }
}

- (void)TriMetXML:(TriMetXML *)xml expectedSize:(long long)expected { 
    
}


- (void)TriMetXML:(TriMetXML *)xml progress:(long long)progress of:(long long)expected { 
    
}


- (void)extractDetours:(XMLDepartures *)departures
{
    self.systemWideDetours = [NSMutableArray array];
    self.stopDetours = [NSMutableArray array];
    
    [departures.allDetours enumerateKeysAndObjectsUsingBlock: ^void (NSNumber* detourId, Detour* detour, BOOL *stop)
     {
         if (detour.systemWideFlag)
         {
             [self.systemWideDetours addObject:detour];
         }
         
         for (NSString *stop in detour.extractStops)
         {
             if ([stop isEqualToString:departures.locid])
             {
                 [self.stopDetours addObject:detour];
             }
         }
         for (DetourLocation *loc in detour.locations)
         {
             if ([loc.locid isEqualToString:departures.locid])
             {
                 [self.stopDetours addObject:detour];
             }
         }
     }];
}

- (id)backgroundTask
{
    _tasks = 0;
    _tasksDone = 0;
    
    [self sendProgress:_tasksDone total:_tasks];
    
    XMLDepartures *departures = [XMLDepartures xml];
    DepartureData *newDetailDep = nil;
    
    departures.oneTimeDelegate = self;
    [departures getDeparturesForLocation:self.arrivalsContext.locid];
    
    [self sendProgress:++_tasksDone total:_tasks];
    
    if (_arrivalsContext.detailBlock && !self.backgroundThread.cancelled)
    {
        newDetailDep = [departures departureForBlock:_arrivalsContext.detailBlock];
        
        if (newDetailDep==nil && self.detailDeparture)
        {
            newDetailDep = self.detailDeparture.copy;
            [newDetailDep makeInvalid:departures.queryTime];
        }
        
        if (newDetailDep)
        {
            if (newDetailDep.needToFetchStreetcarLocation && !self.backgroundThread.cancelled)
            {
                [self sendProgress:_tasksDone total:++_tasks];
                
                NSString *streetcarRoute = newDetailDep.route;
                
                newDetailDep.streetcarId = self.detailStreetcarId;
                
                
                if (newDetailDep.streetcarId == nil)
                {
                    // First get the arrivals via next bus to see if we can get the correct vehicle ID
                    XMLStreetcarPredictions *streetcarArrivals = [[XMLStreetcarPredictions alloc] init];
                    
                    streetcarArrivals.oneTimeDelegate = self;
                    [streetcarArrivals getDeparturesForLocation:[NSString stringWithFormat:@"predictions&a=portland-sc&stopId=%@",newDetailDep.locid]];
                    
                    for (DepartureData *vehicle in streetcarArrivals)
                    {
                        if ([vehicle.block isEqualToString:newDetailDep.block])
                        {
                            newDetailDep.streetcarId = vehicle.streetcarId;
                            self.detailStreetcarId = newDetailDep.streetcarId;
                            break;
                        }
                    }
                    
                }
                
                // Now get the locations of the steetcars and find ours
                XMLStreetcarLocations *locs = [XMLStreetcarLocations sharedInstanceForRoute:streetcarRoute];
                
                locs.oneTimeDelegate = self;
                [locs getLocations];
                
                if (newDetailDep.streetcar && [newDetailDep.route isEqualToString:streetcarRoute])
                {
                    [locs insertLocation:newDetailDep];
                }
            }
            else if ((newDetailDep.blockPosition==nil || newDetailDep.invalidated) && !self.backgroundThread.cancelled)
            {
                XMLLocateVehicles *vehicles = [XMLLocateVehicles xml];
                
                vehicles.oneTimeDelegate = self;
                [vehicles findNearestVehicles:nil direction:nil blocks:[NSSet setWithObject:newDetailDep.block] vehicles:nil];
                
                if (vehicles.count > 0)
                {
                    VehicleData *data = vehicles.items.firstObject;
                    
                    [newDetailDep insertLocation:data];
                }
            }
        }
        
    }
    
    [self extractDetours:departures];

    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    if (!self.backgroundThread.cancelled)
    {
        [result setObject:departures forKey:NSStringFromClass(departures.class)];
    }
    
    
    if (newDetailDep)
    {
        [result setObject:newDetailDep forKey:NSStringFromClass(newDetailDep.class)];
    }
    
    if (!self.backgroundThread.cancelled)
    {
        self.lastUpdate = [NSDate date];
    }
    
    return  result;
}


- (void)progress:(int)state total:(int)total
{
    NSMutableString * progress = [NSMutableString string];
    
    const int max_state = 3;
    
    if (state > max_state)
    {
        total = total - (state-max_state);
        state = max_state;
    }
    
    
    if (total > 1)
    {
        int i;
    
        for (i = 0; i<state; i++)
        {
            [progress appendString:@"◉"];
        }
    
        for (; i<total; i++)
        {
            [progress appendString:@"◎"];
        }
        
        [self setTitle:[NSString stringWithFormat:@"%@ %@", progress, self.progressTitle]];
    }
    else
    {
        [self setTitle:self.progressTitle];
    }
}

- (void)extentionForgrounded
{
    [self refresh:nil];
}

- (void)refresh:(id)arg
{
    NSNumber *hideRefreshLabel = nil;
    
    if ([arg isKindOfClass:[NSNumber class]])
    {
        hideRefreshLabel = arg;
    }
    
    if (self.refreshTimer)
    {
        [self.refreshTimer invalidate];
        self.refreshTimer = nil;
    }
    
    if (hideRefreshLabel==nil || !hideRefreshLabel.boolValue)
    {
        DEBUG_LOGL(self.diff);
        if (self.diff > kStaleTime)
        {
            [self loadTableWithDepartures:nil detailedDeparture:nil];
        }
        else
        {
            self.title = @"Refreshing";
        }
    }
    else
    {
        [self resetTitle];
        self.labelRefreshing.hidden = YES;
    }
    
    
    if (self.lastUpdate==nil && _arrivalsContext.departures == nil)
    {
        self.loadingGroup.hidden = NO;
        self.loadingLabel.hidden = NO;
        self.loadingLabel.text = [NSString stringWithFormat:@"Loading\nStop ID %@", _arrivalsContext.locid];
        self.navGroup.hidden     = YES;
        
        if (_arrivalsContext.detailBlock)
        {
            self.progressTitle = @"Details";
        }
        else
        {
            self.progressTitle = @"Arrivals";
        }
    }
    else if (_arrivalsContext.departures !=nil)
    {
        self.progressTitle = @"Refreshing";
        [self loadTableWithDepartures:_arrivalsContext.departures
                    detailedDeparture:[_arrivalsContext.departures departureForBlock:_arrivalsContext.detailBlock]];
        _arrivalsContext.departures = nil;
    }
    else
    {
        self.loadingGroup.hidden = YES;
        self.progressTitle = @"Refreshing";
    }
    
    [self startBackgroundTask];
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.arrivalsContext = context;
    
    if (self.arrivalsContext.departures!=nil)
    {
        [self extractDetours:self.arrivalsContext.departures];
    }
    
    [self refresh:@YES];

}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex
{
    WatchRow *item = [self.arrivalsTable rowControllerAtIndex:rowIndex];
    NSString *block = _arrivalsContext.detailBlock;
    if ((block == nil && ![item select:self.departures from:self context:_arrivalsContext])
        || block != nil)
    {
       [self refresh:nil];
    }
}



- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    
    if (![self autoCommute])
    {
        [self startTimer];
        [self.arrivalsContext updateUserActivity:self];
    }
    
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
    
    [super didDeactivate];
}

- (IBAction)doRefreshMenuItem {
    [self refresh:nil];
}

- (IBAction)menuItemNearby {
    if (self.departures.loc)
    {
        [self pushControllerWithName:kNearbyScene context:self.departures.loc];
    }
}

- (IBAction)menuItemCommute {
    [self forceCommute];
}
- (IBAction)menuItemHome {
    [self popToRootController];
}


- (IBAction)nextButtonTapped
{
    if (self.arrivalsContext.hasNext)
    {
        WatchArrivalsContext *next = self.arrivalsContext.next;
        [next pushFrom:self];
    }
}
- (IBAction)homeButtonTapped {
    [self popToRootController];
}

- (IBAction)swipeLeft:(id)sender {
    if (self.arrivalsContext.hasNext)
    {
        WatchArrivalsContext *next = self.arrivalsContext.next;
        [next pushFrom:self];
    }
}

- (IBAction)swipeDown:(id)sender {
    [self popToRootController];
}
@end



