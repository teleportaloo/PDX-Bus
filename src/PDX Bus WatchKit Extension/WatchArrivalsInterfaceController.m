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
#import "XMLDetour.h"
#import "WatchArrival.h"
#import "DepartureData.h"
#import "WatchDepartureUI.h"
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

#define kRefreshTime 20
#define kStaleTime   59


@interface WatchArrivalsInterfaceController ()

@end

@implementation WatchArrivalsInterfaceController

@synthesize arrivalsContext     = _arrivalsContext;
@synthesize refreshTimer        = _refreshTimer;
@synthesize departures          = _departures;
@synthesize lastUpdate          = _lastUpdate;

- (void)dealloc
{
    self.arrivalsContext = nil;
    self.departures = nil;
    self.lastUpdate = nil;
    
    if (self.refreshTimer)
    {
        [self.refreshTimer invalidate];
        self.refreshTimer = nil;
    }
    
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
    WatchDepartureUI *ui = [WatchDepartureUI createFromData:self.detailDeparture];
    NSMutableString *detourText = [[[NSMutableString alloc] init] autorelease];

    NSInteger mins = ui.data.minsToArrival;
    NSDate *depatureDate = TriMetToNSDate(ui.data.departureTime);
    NSMutableString *timeText = [[[NSMutableString alloc] init] autorelease];
    NSMutableString *scheduledText = [[[NSMutableString alloc] init] autorelease];
    NSMutableString *distanceText = [[[NSMutableString alloc] init] autorelease];
    
    
    
    UIColor *timeColor = nil;
    
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    // If date is tomorrow and more than 12 hours away then put the full date
    if (([[dateFormatter stringFromDate:depatureDate] isEqualToString:[dateFormatter stringFromDate:[NSDate date]]])
        || ([depatureDate timeIntervalSinceDate:[NSDate date]] < 12 * 60 * 60)
        || ui.data.status == kStatusEstimated)
    {
        [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    }
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    
    if ((mins < 0 || ui.data.invalidated) && ui.data.status != kStatusCancelled)
    {
        [timeText appendString:NSLocalizedString(@"Gone - ", @"first part of text to display on a single line if a bus has gone")];
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];
        timeColor = [UIColor redColor];
    }
    else if (mins == 0 && ui.data.status != kStatusCancelled)
    {
        [timeText appendString:NSLocalizedString(@"Due - ", @"first part of text to display on a single line if a bus is due")];
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];
        timeColor = [UIColor redColor];
    }
    else if (mins == 1 && ui.data.status != kStatusCancelled)
    {
        [timeText appendString:NSLocalizedString(@"1 min - ", @"first part of text to display on a single line if a bus is due in 1 minute")];
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];
        timeColor = [UIColor redColor];
    }
    else if (mins < 6 && ui.data.status != kStatusCancelled)
    {
        [timeText appendFormat:NSLocalizedString(@"%lld mins - ", @"first part of text to display on a single line if a bus is due in several minutes"), mins];
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];
        timeColor = [UIColor redColor];
    }
    else if (mins < 60 && ui.data.status != kStatusCancelled)
    {
        [timeText appendFormat:NSLocalizedString(@"%lld mins - ", @"first part of text to display on a single line if a bus is due in several minutes"), mins];
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
    
    switch (ui.data.status)
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
    
    if (ui.data.status != kStatusScheduled && ui.data.scheduledTime !=0 && (ui.data.scheduledTime/60000) != (ui.data.departureTime/60000))
    {
        NSDate *scheduledDate = TriMetToNSDate(ui.data.scheduledTime);
        [scheduledText appendFormat:NSLocalizedString(@"scheduled %@ ",@"info about arrival time"), [dateFormatter stringFromDate:scheduledDate]];;
    }
    
    NSMutableAttributedString * string = [[[NSMutableAttributedString alloc] initWithString:@""] autorelease];
    
    NSString *location = [NSString stringWithFormat:@"%@\n", ui.data.locationDesc];
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:[UIColor cyanColor] forKey:NSForegroundColorAttributeName];
    NSAttributedString *subString = [[[NSAttributedString alloc] initWithString:location attributes:attributes] autorelease];
    [string appendAttributedString:subString];
    
    NSString *fullsign = [NSString stringWithFormat:@"%@\n", ui.data.fullSign];
    attributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    subString = [[[NSAttributedString alloc] initWithString:fullsign attributes:attributes] autorelease];
    [string appendAttributedString:subString];
    
    if (scheduledText.length>0)
    {
        [timeText appendString:@"\n"];
    }
    
    attributes = [NSDictionary dictionaryWithObject:timeColor forKey:NSForegroundColorAttributeName];
    subString = [[[NSAttributedString alloc] initWithString:timeText attributes:attributes] autorelease];
    [string appendAttributedString:subString];
    
    if (detourText.length>0)
    {
        [scheduledText appendString:@"\n"];
    }
    
    attributes = [NSDictionary dictionaryWithObject:[UIColor grayColor] forKey:NSForegroundColorAttributeName];
    subString = [[[NSAttributedString alloc] initWithString:scheduledText attributes:attributes] autorelease];
    [string appendAttributedString:subString];
    
    attributes = [NSDictionary dictionaryWithObject:[UIColor orangeColor] forKey:NSForegroundColorAttributeName];
    subString = [[[NSAttributedString alloc] initWithString:detourText attributes:attributes] autorelease];
    [string appendAttributedString:subString];
    
    if (self.detailDeparture.blockPosition && self.detailDeparture.blockPositionFeet > 0)
    {
        [distanceText appendFormat:@"\n%@ away\n", [FormatDistance formatFeet:self.detailDeparture.blockPositionFeet]];
        [distanceText appendString:[VehicleData locatedSomeTimeAgo:TriMetToNSDate(self.detailDeparture.blockPositionAt)]];
        attributes = [NSDictionary dictionaryWithObject:[UIColor yellowColor] forKey:NSForegroundColorAttributeName];
        subString = [[[NSAttributedString alloc] initWithString:distanceText attributes:attributes] autorelease];
        [string appendAttributedString:subString];
        
        
        
    }
    
    return string;
}

- (void)loadTableWithDepartures:(XMLDepartures *)newDepartures detour:(XMLDetour*)detour
{
    bool extraploate = (newDepartures == nil && self.diff > kStaleTime);
    NSInteger detourStartRow = 0;

    if (self.arrivalsContext.navText)
    {
        if (self.arrivalsContext.hasNext)
        {
            self.navGroup.hidden = NO;
            [self.nextButton setTitle:self.arrivalsContext.navText];
        }
        else
        {
            self.navGroup.hidden = YES;
        }
    }
    
    if (newDepartures == nil)
    {
        newDepartures = self.departures;
    }
    
    if (newDepartures.gotData && newDepartures.itemFromCache)
    {
        self.labelRefreshing.hidden = NO;
        self.labelRefreshing.text = @"Network error - extrapolated times";
    }
    else if (extraploate)
    {
        // self.labelRefreshing.hidden = NO;
        // self.labelRefreshing.text = @"Updating stale times";
    }
    else
    {
        self.labelRefreshing.hidden = YES;
    }
    
    NSMutableArray *rowTypes = [[[NSMutableArray alloc] init] autorelease];
    
    
    if (self.detailDeparture)
    {
        [rowTypes addObject:@"Arrival"];
        
        if (self.detailDeparture.blockPosition!=nil && newDepartures.loc!=nil)
        {
            [rowTypes addObject:@"Map"];
        }
        [rowTypes addObject:@"Schedule Info"];
    }
    else if (newDepartures.safeItemCount == 0 )
    {
        [rowTypes addObject:@"No arrivals"];
        _arrivalsStartRow = -1;
    }
    else
    {
        _arrivalsStartRow = rowTypes.count;
        for (NSInteger i=0; i<newDepartures.safeItemCount; i++)
        {
            [rowTypes addObject:@"Arrival"];
        }
    }
    
    detourStartRow = rowTypes.count;
    
    for (NSInteger i=0; i< detour.safeItemCount; i++)
    {
        [rowTypes addObject:@"Detour"];
    }
    
    [rowTypes addObject:@"Static Info"];
    
    if (self.arrivalsContext.showMap && newDepartures.loc !=nil)
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
            
            if (extraploate)
            {
                [self.detailDeparture extrapolateFromNow];
            }
            WatchDepartureUI *ui = [WatchDepartureUI createFromData:self.detailDeparture];
            
            [row displayDepature:ui];
        }
        else if (rowClass == WatchArrival.class)
        {
            WatchArrival *row = item;
            
            DepartureData *dep = [newDepartures itemAtIndex:i-_arrivalsStartRow];
            
            if (extraploate)
            {
                [dep extrapolateFromNow];
            }
            WatchDepartureUI *ui = [WatchDepartureUI createFromData:dep];
            
            [row displayDepature:ui];
        }
        else if (rowClass == WatchDetour.class)
        {
            Detour *det = [detour itemAtIndex:i-detourStartRow];
            WatchDetour *detUI = item;
            detUI.detourText.text = det.detourDesc;
        }
        else if (rowClass == WatchArrivalInfo.class)
        {
            WatchArrivalInfo *info = item;
            
            if (newDepartures.gotData)
            {
                NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
                [dateFormatter setDateStyle:NSDateFormatterNoStyle];
                [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
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
                otherPins = [NSArray arrayWithObjects:[WatchDepartureUI createFromData:self.detailDeparture], nil];
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
        SafeUserData *userData = [SafeUserData getSingleton];
        userData.readOnly = FALSE;
        NSString * longDesc = [NSString stringWithFormat:@"%@ (%@)", self.departures.locDesc, self.departures.locDir];
        [userData addToRecentsWithLocation:self.arrivalsContext.locid description:longDesc];
        userData.readOnly = TRUE;
    }
    
    if (!extraploate)
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
        return -[self.lastUpdate timeIntervalSinceNow];
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


- (void)taskFinishedMainThread:(id)arg
{
    NSArray *data = arg;
    
    XMLDepartures *departures = data.firstObject;
    XMLDetour     *detour     = nil;
    
    if (data.count > 1)
    {
        detour = data.lastObject;
    }
    
    [self loadTableWithDepartures:departures detour: detour];
    [self startTimer];
}

- (id)backgroundTask
{
    XMLDepartures *departures = [[[XMLDepartures alloc] init] autorelease];
    [departures getDeparturesForLocation:self.arrivalsContext.locid];
    self.lastUpdate = [NSDate date];
    
    XMLDetour *detour = nil;
    
    if (_arrivalsContext.detailBlock)
    {
        bool found = NO;
        for (NSInteger i = 0; i <departures.safeItemCount; i++) {
            
            DepartureData *dep = [departures itemAtIndex:i];
            
            if ([dep.block isEqualToString:_arrivalsContext.detailBlock])
            {
                self.detailDeparture = dep;
                found = YES;
                break;
            }
        }
        
        if (!found && self.detailDeparture)
        {
            [self.detailDeparture makeInvalid:departures.queryTime];
        }
        
        
        DepartureData *dep = self.detailDeparture;
        
        if (self.detailDeparture)
        {
            detour = [[[XMLDetour alloc] init] autorelease];
            [detour getDetourForRoute:dep.route];
            
            if (dep.needToFetchStreetcarLocation)
            {
                NSString *streetcarRoute = dep.route;
                
                dep.streetcarId = self.detailStreetcarId;
                
                if (dep.streetcarId == nil)
                {
                    // First get the arrivals via next bus to see if we can get the correct vehicle ID
                    XMLStreetcarPredictions *streetcarArrivals = [[XMLStreetcarPredictions alloc] init];
                    
                    [streetcarArrivals getDeparturesForLocation:[NSString stringWithFormat:@"predictions&a=portland-sc&r=%@&stopId=%@", streetcarRoute,dep.locid]];
                    for (NSInteger i=0; i< streetcarArrivals.safeItemCount; i++)
                    {
                        DepartureData *vehicle = [streetcarArrivals itemAtIndex:i];
                        
                        if ([vehicle.block isEqualToString:dep.block])
                        {
                            dep.streetcarId = vehicle.streetcarId;
                            self.detailStreetcarId = dep.streetcarId;
                            break;
                        }
                    }
                    
                    [streetcarArrivals release];
                }
                
                // Now get the locations of the steetcars and find ours
                XMLStreetcarLocations *locs = [XMLStreetcarLocations getSingletonForRoute:streetcarRoute];
                [locs getLocations];

                if (dep.streetcar && [dep.route isEqualToString:streetcarRoute])
                {
                    [locs insertLocation:dep];
                }
            }
            else if ([UserPrefs getSingleton].watchUseBetaVehicleLocator && (dep.blockPosition==nil || dep.invalidated))
            {
                XMLLocateVehicles *vehicles = [[[XMLLocateVehicles alloc] init] autorelease];
                
                    
                [vehicles findNearestVehicles:nil direction:nil blocks:[NSSet setWithObject:dep.block]];
                    
                if (vehicles.safeItemCount > 0)
                {
                    VehicleData *data = vehicles.itemArray.firstObject;
                        
                    [dep insertLocation:data];
                }
            }
        }
        
    }
    
    NSArray *result = nil;
    
    if (detour)
    {
        result = [NSArray arrayWithObjects:departures, detour, nil];
    }
    else
    {
        result = [NSArray arrayWithObject:departures];
    }
    
    return  result;
}





- (void)refresh:(id)arg
{
    if (self.refreshTimer)
    {
        [self.refreshTimer invalidate];
        self.refreshTimer = nil;
    }
    
    if (arg==nil || ([arg isKindOfClass:[NSNumber class]] && ![(NSNumber *)arg boolValue]))
    {
        
        
        if (self.diff > kStaleTime)
        {
            
            [self loadTableWithDepartures:nil detour:nil];
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
    
    [self startBackgroundTask];
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.arrivalsContext = context;
    _mapUpdated = NO;
    
    
    
    NSNumber *hidden = [NSNumber numberWithBool:YES];
    [self refresh:hidden];

}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex
{
    if (rowIndex < self.departures.safeItemCount && _arrivalsContext.detailBlock == nil)
    {
        WatchArrivalsContext *detailContext = [WatchArrivalsContext alloc].init.autorelease;
        DepartureData *data = [self.departures itemAtIndex:rowIndex];
        
        detailContext.detailBlock   = data.block;
        detailContext.locid         = _arrivalsContext.locid;
        detailContext.stopDesc      = _arrivalsContext.stopDesc;
        detailContext.navText       = _arrivalsContext.navText;
        
        [detailContext pushFrom:self];
    }
    else
    {
        [self refresh:nil];
    }
}



- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    
    if (![self autoCommuteAlreadyHome:NO])
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
    [self forceCommuteAlreadyHome:NO];
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
@end



