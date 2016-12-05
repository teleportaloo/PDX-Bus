//
//  WatchArrivalsInterfaceController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/16/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
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
#import "TriMetRouteColors.h"
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

#define kRefreshTime 30


@interface WatchArrivalsInterfaceController ()

@end

@implementation WatchArrivalsInterfaceController

@synthesize arrivalsContext     = _arrivalsContext;
@synthesize refreshTimer        = _refreshTimer;
@synthesize departures          = _departures;
@synthesize lastUpdate          = _lastUpdate;
@synthesize detours             = _detours;

- (void)dealloc
{
    self.arrivalsContext = nil;
    self.departures = nil;
    self.detours = nil;
    self.lastUpdate = nil;
    
    if (self.refreshTimer)
    {
        [self.refreshTimer invalidate];
        self.refreshTimer = nil;
    }
    
    self.arrivalsTable      = nil;
    self.detailDeparture    = nil;
    self.detailStreetcarId  = nil;
    self.distanceLabel      = nil;
    self.labelRefreshing    = nil;
    self.loadingGroup       = nil;
    self.loadingLabel       = nil;
    self.navGroup           = nil;
    self.nextButton         = nil;
    self.progressTitle      = nil;
    self.stopDescription    = nil;
    
    
    [super dealloc];
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

- (NSMutableAttributedString*)detailText
{
    NSMutableString *detourText = [NSMutableString string];

    NSInteger mins = self.detailDeparture.minsToArrival;
    NSDate *depatureDate = TriMetToNSDate(self.detailDeparture.departureTime);
    NSMutableString *timeText = [NSMutableString string];
    NSMutableString *scheduledText = [NSMutableString string];
    NSMutableString *distanceText = [NSMutableString string];
    
    
    
    UIColor *timeColor = nil;
    
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    
    // If date is tomorrow and more than 12 hours away then put the full date
    if (([[dateFormatter stringFromDate:depatureDate] isEqualToString:[dateFormatter stringFromDate:[NSDate date]]])
        || ([depatureDate timeIntervalSinceDate:[NSDate date]] < 12 * 60 * 60)
        || self.detailDeparture.status == kStatusEstimated)
    {
        dateFormatter.dateStyle = NSDateFormatterNoStyle;
    }
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    
    
    if ((mins < 0 || self.detailDeparture.invalidated) && self.detailDeparture.status != kStatusCancelled)
    {
        [timeText appendString:NSLocalizedString(@"Gone - ", @"first part of text to display on a single line if a bus has gone")];
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];
        timeColor = [UIColor redColor];
    }
    else if (mins == 0 && self.detailDeparture.status != kStatusCancelled)
    {
        [timeText appendString:NSLocalizedString(@"Due - ", @"first part of text to display on a single line if a bus is due")];
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];
        timeColor = [UIColor redColor];
    }
    else if (mins == 1 && self.detailDeparture.status != kStatusCancelled)
    {
        [timeText appendString:NSLocalizedString(@"1 min - ", @"first part of text to display on a single line if a bus is due in 1 minute")];
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];
        timeColor = [UIColor redColor];
    }
    else if (mins < 6 && self.detailDeparture.status != kStatusCancelled)
    {
        [timeText appendFormat:NSLocalizedString(@"%d mins - ", @"first part of text to display on a single line if a bus is due in several minutes"), (int)mins];
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];
        timeColor = [UIColor redColor];
    }
    else if (mins < 60 && self.detailDeparture.status != kStatusCancelled)
    {
        [timeText appendFormat:NSLocalizedString(@"%d mins - ", @"first part of text to display on a single line if a bus is due in several minutes"), (int)mins];
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];
        timeColor = [UIColor blueColor];
    }
    else
    {
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];
        timeColor = [UIColor blueColor];
    }
    
    // [timeText appendFormat:@"\nTime adjusted by %d:%02d ", (int)(self.detailDeparture.timeAdjustment) / 60, (int)(self.detailDeparture.timeAdjustment) % 60];
    
    
    switch (self.detailDeparture.status)
    {
        case kStatusEstimated:
            break;
        case kStatusScheduled:
            [scheduledText appendString:NSLocalizedString(@"🕔Scheduled - no location information available. ", @"info about arrival time")];
            timeColor = [UIColor grayColor];
            break;
        case kStatusCancelled:
            [scheduledText appendString:NSLocalizedString(@"❌Canceled ", @"info about arrival time")];
            timeColor = [UIColor redColor];
            break;
        case kStatusDelayed:
            [detourText appendString:NSLocalizedString(@"Delayed ",  @"info about arrival time")];
            timeColor = [UIColor yellowColor];
            break;
    }
    
    if (self.detailDeparture.status != kStatusScheduled && self.detailDeparture.scheduledTime !=0 && (self.detailDeparture.scheduledTime/60000) != (self.detailDeparture.departureTime/60000))
    {
        NSDate *scheduledDate = TriMetToNSDate(self.detailDeparture.scheduledTime);
        [scheduledText appendFormat:NSLocalizedString(@"scheduled %@ ",@"info about arrival time"), [dateFormatter stringFromDate:scheduledDate]];;
    }
    
    NSMutableAttributedString * string = @"".mutableAttributedString;
    
    NSString *location = [NSString stringWithFormat:@"%@\n", self.detailDeparture.locationDesc];
    NSDictionary *attributes = @{NSForegroundColorAttributeName: [UIColor cyanColor]};
    NSAttributedString *subString = [[[NSAttributedString alloc] initWithString:location attributes:attributes] autorelease];
    [string appendAttributedString:subString];
    
    NSString *fullsign = [NSString stringWithFormat:@"%@\n", self.detailDeparture.fullSign];
    attributes =  @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    subString = [[[NSAttributedString alloc] initWithString:fullsign attributes:attributes] autorelease];
    [string appendAttributedString:subString];
    
    if (scheduledText.length>0)
    {
        [timeText appendString:@"\n"];
    }
    
    attributes = @{NSForegroundColorAttributeName: timeColor};
    subString = [[[NSAttributedString alloc] initWithString:timeText attributes:attributes] autorelease];
    [string appendAttributedString:subString];
    
    if (detourText.length>0)
    {
        [scheduledText appendString:@"\n"];
    }
    
    attributes = @{NSForegroundColorAttributeName: [UIColor grayColor]};
    subString = [[[NSAttributedString alloc] initWithString:scheduledText attributes:attributes] autorelease];
    [string appendAttributedString:subString];
    
    attributes = @{NSForegroundColorAttributeName: [UIColor orangeColor]};
    subString = [[[NSAttributedString alloc] initWithString:detourText attributes:attributes] autorelease];
    [string appendAttributedString:subString];
    
    if (self.detailDeparture.blockPosition && self.detailDeparture.blockPositionFeet > 0)
    {
        [distanceText appendFormat:@"\n%@ away\n", [FormatDistance formatFeet:self.detailDeparture.blockPositionFeet]];
        [distanceText appendString:[VehicleData locatedSomeTimeAgo:TriMetToNSDate(self.detailDeparture.blockPositionAt)]];
        attributes = @{NSForegroundColorAttributeName: [UIColor yellowColor]};
        subString = [[[NSAttributedString alloc] initWithString:distanceText attributes:attributes] autorelease];
        [string appendAttributedString:subString];
    }
    
    return string;
}

- (void)loadTableWithDepartures:(XMLDepartures *)newDepartures detours:(XMLDetours*)detours detailedDeparture:(DepartureData*)newDetailDep
{
    bool extrapolate = (newDepartures == nil && self.diff > kStaleTime);
    bool mapShown = NO;
    NSInteger detourStartRow = 0;
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
    
    NSMutableArray *rowTypes = [NSMutableArray array];
    
    
    if (newDetailDep)
    {
        [rowTypes addObject:@"Arrival"];
        
        if (newDetailDep.blockPosition!=nil && newDepartures.loc!=nil)
        {
            [rowTypes addObject:@"Map"];
            mapShown = YES;
        }
        [rowTypes addObject:@"Schedule Info"];
        
        self.detailDeparture = newDetailDep;
    }
    else if (newDepartures.count == 0 )
    {
        [rowTypes addObject:@"No arrivals"];
        _arrivalsStartRow = -1;
    }
    else
    {
        _arrivalsStartRow = rowTypes.count;
        for (NSInteger i=0; i<newDepartures.count; i++)
        {
            [rowTypes addObject:@"Arrival"];
        }
    }
    
    detourStartRow = rowTypes.count;
    
    if (detours !=nil)
    {
        for (NSInteger i=0; i< detours.count; i++)
        {
            [rowTypes addObject:@"Detour"];
        }
        self.detours = detours;
    }
    else if (newDetailDep && newDetailDep.detour)
    {
        [rowTypes addObject:@"Detour"];
    }
    
    [rowTypes addObject:@"Static Info"];
    
    if (self.arrivalsContext.showMap && newDepartures.loc !=nil && !mapShown)
    {
        [rowTypes addObject:@"Map"];
    }
    
    
    [self.arrivalsTable setRowTypes:rowTypes];
    
    self.departures = newDepartures;
    
    for (int i=0; i<self.arrivalsTable.numberOfRows; i++)
    {
        id item = [self.arrivalsTable rowControllerAtIndex:i];
        Class rowClass = [item class];
        
        if (rowClass == WatchNoArrivals.class)
        {
            WatchNoArrivals* row = item;
            
            if (newDepartures.gotData)
            {
                row.errorMsg.text = @"No arrivals";
            }
            else
            {
                row.errorMsg.text = @"Network timeout";
            }
        }
        else if (rowClass == WatchArrival.class && self.detailDeparture)
        {
            WatchArrival *row = item;
            
            if (extrapolate)
            {
                [self.detailDeparture extrapolateFromNow];
            }
            
            [row displayDeparture:self.detailDeparture];
        }
        else if (rowClass == WatchArrival.class)
        {
            WatchArrival *row = item;
            
            DepartureData *dep = newDepartures[i-_arrivalsStartRow];
            
            if (extrapolate)
            {
                [dep extrapolateFromNow];
            }
            
            [row displayDeparture:dep];
        }
        else if (rowClass == WatchDetour.class)
        {
            WatchDetour *detUI = item;
            if (detours!=nil)
            {
                Detour *det = detours[i-detourStartRow];
                detUI.detourText.text = det.detourDesc;
            }
            else
            {
                detUI.detourText.text = @"Loading detour description...";
            }
        }
        else if (rowClass == WatchArrivalInfo.class)
        {
            WatchArrivalInfo *info = item;
            
            if (newDepartures.gotData)
            {
                NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
                dateFormatter.dateStyle = NSDateFormatterNoStyle;
                dateFormatter.timeStyle = NSDateFormatterMediumStyle;
                // NSString *shortDir = [StopNameCacheManager shortDirection:newDepartures.locDir];
                
            
                if (newDepartures.locDir.length > 0)
                {
                    info.arrivalInfoText.text = [NSString stringWithFormat:@"🆔%@\n⤵️%@\n➡️%@", newDepartures.locid, [dateFormatter stringFromDate:newDepartures.cacheTime], newDepartures.locDir];
                }
                else
                {
                    info.arrivalInfoText.text = [NSString stringWithFormat:@"🆔%@\n⤵️%@", newDepartures.locid, [dateFormatter stringFromDate:newDepartures.cacheTime]];
                }
            }
            else
            {
                info.arrivalInfoText.text = [NSString stringWithFormat:@"🆔%@", newDepartures.locid];
            }
        }
        else if (rowClass == WatchArrivalMap.class && self.detailDeparture)
        {
            WatchArrivalMap *row = item;
            NSArray *otherPins = nil;
            
            if (self.detailDeparture.blockPosition!=nil)
            {
                otherPins = @[self.detailDeparture];
            }
            
            [WatchMapHelper displayMap:row.map purplePin:newDepartures.loc otherPins:otherPins];
        }
        else if (rowClass == WatchArrivalMap.class)
        {
            WatchArrivalMap *row = item;
            if (!_mapUpdated)
            {
                [WatchMapHelper displayMap:row.map purplePin:newDepartures.loc otherPins:nil];
            }
            _mapUpdated = YES;
        }
        else if (rowClass == WatchArrivalScheduleInfo.class)
        {
            WatchArrivalScheduleInfo *row = item;
            
            row.scheduleInfoText.attributedText = [self detailText];
        }
        else
        {
            ERROR_LOG(@"Unexpected row class\n");
        }
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
        SafeUserData *userData = [SafeUserData singleton];
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
        XMLDetours    *detours     = [data objectForKey:NSStringFromClass([XMLDetours class])];
        DepartureData *detailedDep = [data objectForKey:NSStringFromClass([DepartureData class])];
    
        [self loadTableWithDepartures:departures detours:detours detailedDeparture:detailedDep];
    }
    else
    {
        [self loadTableWithDepartures:nil detours:nil detailedDeparture:nil];
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

- (void)TriMetXML:(TriMetXML*)xml startedParsingData:(NSUInteger)size
{
    // startTime = [[NSDate date] retain];
    
    if (size > kThreashold)
    {
        [self sendProgress:_tasksDone total:++_tasks];
    }
}

- (void)TriMetXML:(TriMetXML*)xml finishedParsingData:(NSUInteger)size
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


- (id)backgroundTask
{
    _tasks = 0;
    _tasksDone = 0;
    
    [self sendProgress:_tasksDone total:_tasks];
    
    XMLDepartures *departures = [XMLDepartures xml];
    XMLDetours *detours = nil;
    DepartureData *newDetailDep = nil;
    
    departures.oneTimeDelegate = self;
    [departures getDeparturesForLocation:self.arrivalsContext.locid];
    
    [self sendProgress:++_tasksDone total:_tasks];
    
    if (_arrivalsContext.detailBlock && !self.backgroundThread.cancelled)
    {
        newDetailDep = [departures departureForBlock:_arrivalsContext.detailBlock];
        
        if (newDetailDep==nil && self.detailDeparture)
        {
            newDetailDep = [self.detailDeparture.copy autorelease];
            [newDetailDep makeInvalid:departures.queryTime];
        }
        
        if (newDetailDep)
        {
            if (newDetailDep.detour && !self.backgroundThread.cancelled)
            {
                [self sendProgress:_tasksDone total:++_tasks];
                detours = [XMLDetours xml];
                detours.oneTimeDelegate = self;
                [detours getDetoursForRoute:newDetailDep.route];
            }
        
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
                    [streetcarArrivals getDeparturesForLocation:[NSString stringWithFormat:@"predictions&a=portland-sc&r=%@&stopId=%@", streetcarRoute,newDetailDep.locid]];
                    
                    for (DepartureData *vehicle in streetcarArrivals)
                    {                        
                        if ([vehicle.block isEqualToString:newDetailDep.block])
                        {
                            newDetailDep.streetcarId = vehicle.streetcarId;
                            self.detailStreetcarId = newDetailDep.streetcarId;
                            break;
                        }
                    }
                    
                    [streetcarArrivals release];
                }
                
                // Now get the locations of the steetcars and find ours
                XMLStreetcarLocations *locs = [XMLStreetcarLocations singletonForRoute:streetcarRoute];
                
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
                [vehicles findNearestVehicles:nil direction:nil blocks:[NSSet setWithObject:newDetailDep.block]];
                
                if (vehicles.count > 0)
                {
                    VehicleData *data = vehicles.itemArray.firstObject;
                        
                    [newDetailDep insertLocation:data];
                }
            }
        }
        
    }
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    
    if (!self.backgroundThread.cancelled)
    {
        [result setObject:departures forKey:NSStringFromClass(departures.class)];
    }
    
    if (detours && !self.backgroundThread.cancelled)
    {
        [result setObject:detours forKey:NSStringFromClass(detours.class)];
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
    
    if ([arg isKindOfClass:hideRefreshLabel.class])
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
            [self loadTableWithDepartures:nil detours:nil detailedDeparture:nil];
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
                              detours:_arrivalsContext.detours
                    detailedDeparture:[_arrivalsContext.departures departureForBlock:_arrivalsContext.detailBlock]];
        _arrivalsContext.departures = nil;
        _arrivalsContext.detours = nil;
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
    _mapUpdated = NO;
    
    [self refresh:@YES];

}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex
{
    
    
    if (rowIndex < self.departures.count && _arrivalsContext.detailBlock == nil)
    {
        WatchArrivalsContext *detailContext = [self.arrivalsContext clone];
        
        if (detailContext == nil)
        {
            detailContext = [WatchArrivalsContext alloc].init.autorelease;
        }
        DepartureData *data = self.departures[rowIndex];
        
        detailContext.detailBlock   = data.block;
        detailContext.locid         = _arrivalsContext.locid;
        detailContext.stopDesc      = _arrivalsContext.stopDesc;
        detailContext.navText       = _arrivalsContext.navText;
        detailContext.departures    = self.departures;
        detailContext.detours       = self.detours;
        
        [detailContext pushFrom:self];
    }
    else
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
        WatchArrivalsContext *next = [self.arrivalsContext getNext];
        [next pushFrom:self];
    }
}
- (IBAction)homeButtonTapped {
    [self popToRootController];
}
@end



