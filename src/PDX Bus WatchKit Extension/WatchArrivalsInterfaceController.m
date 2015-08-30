//
//  WatchArrivalsInterfaceController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/16/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

/* INSERT_LICENSE */

#import "WatchArrivalsInterfaceController.h"
#import "XMLDepartures.h"
#import "WatchArrival.h"
#import "DepartureData.h"
#import "WatchDepartureUI.h"
#import "TriMetRouteColors.h"
#import "WatchArrivalInfo.h"
#import "StopNameCacheManager.h"
#import "WatchMapHelper.h"
#import "UserFaves.h"
#import "WatchNoArrivals.h"

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

- (void)loadTableWithDepartures:(XMLDepartures *)newDepartures
{
    bool extraploate = (newDepartures == nil && self.diff > kStaleTime);
    
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
        self.labelRefreshing.hidden = NO;
        self.labelRefreshing.text = @"Updating stale times";
    }
    else
    {
        self.labelRefreshing.hidden = YES;
    }
    
    NSMutableArray *rowTypes = [[[NSMutableArray alloc] init] autorelease];
    
    if (newDepartures.safeItemCount == 0 )
    {
        [rowTypes addObject:@"No arrivals"];
    }
    else for (NSInteger i=0; i<newDepartures.safeItemCount; i++)
    {
        [rowTypes addObject:@"Arrival"];
    }

    [rowTypes addObject:@"Static Info"];
    
    _infoRow = rowTypes.count - 1;
    
    [self.arrivalsTable setRowTypes:rowTypes];
    self.departures = newDepartures;
    
    if (newDepartures.safeItemCount == 0)
    {
        WatchNoArrivals* row = [self.arrivalsTable rowControllerAtIndex:0];
        
        if (newDepartures.gotData)
        {
            row.errorMsg.text = @"No arrivals";
        }
        else
        {
            row.errorMsg.text = @"Network timeout";
        }
    }
    else for (NSInteger i = 0; i <newDepartures.safeItemCount; i++) {
        
        WatchArrival *row = [self.arrivalsTable rowControllerAtIndex:i];
        
        DepartureData *dep = [newDepartures itemAtIndex:i];
        
        if (extraploate)
        {
            [dep extrapolateFromNow];
        }
        WatchDepartureUI *ui = [WatchDepartureUI createFromData:dep];
        
        [row displayDepature:ui];
    }
    
    WatchArrivalInfo *info = [self.arrivalsTable rowControllerAtIndex:_infoRow];
    
    if (newDepartures.gotData)
    {
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateStyle:NSDateFormatterNoStyle];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        // NSString *shortDir = [StopNameCacheManager shortDirection:newDepartures.locDir];
        
        info.arrivalInfoText.text = [NSString stringWithFormat:@"🆔%@\n⤵️%@\n➡️%@", newDepartures.locid, [dateFormatter stringFromDate:newDepartures.cacheTime], newDepartures.locDir];
    }
    else
    {
        info.arrivalInfoText.text = [NSString stringWithFormat:@"🆔%@", newDepartures.locid];
    }
    
    if (self.arrivalsContext.showMap && newDepartures.locLat !=nil)
    {
        if (!_mapUpdated)
        {
            [WatchMapHelper displayMap:self.map purplePin:[newDepartures getLocation] redPins:nil];
        }
        _mapUpdated = YES;
    }
    else
    {
        self.map.hidden = YES;
        _mapUpdated = NO;
    }
    
    if (self.arrivalsContext.showDistance)
    {
        NSString *str = nil;
        if (self.arrivalsContext.distance < 500)
        {
            str = [NSString stringWithFormat:NSLocalizedString(@"%d ft (%d meters)", @"distance in <feet> then in <metres>"), (int)(self.arrivalsContext.distance * 3.2808398950131235),
                   (int)(self.arrivalsContext.distance) ];
        }
        else
        {
            str = [NSString stringWithFormat:NSLocalizedString(@"%.2f miles (%.2f km)", @"distance in <miles> then in <kilometres>"), (float)(self.arrivalsContext.distance / 1609.344),
                   (float)(self.arrivalsContext.distance / 1000) ];
        }
        
        self.distanceLabel.text = str;
        
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
        NSString * longDesc = [NSString stringWithFormat:@"%@ - %@", self.departures.locDesc, self.departures.locDir];
        [userData addToRecentsWithLocation:self.arrivalsContext.locid description:longDesc];
        userData.readOnly = TRUE;
    }
    
    [self resetTitle];
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
    XMLDepartures *departures = arg;
    [self loadTableWithDepartures:departures];
    [self startTimer];
}

- (id)backgroundTask
{
    XMLDepartures *departures = [[[XMLDepartures alloc] init] autorelease];
    [departures getDeparturesForLocation:self.arrivalsContext.locid parseError:nil];
    self.lastUpdate = [NSDate date];
    return  departures;
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
        self.title = @"Refreshing";
        
        if (self.diff > kStaleTime)
        {
            
            [self loadTableWithDepartures:nil];
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
    _infoRow    = -1;
    
    NSNumber *hidden = [NSNumber numberWithBool:YES];
    [self refresh:hidden];

}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex
{
    if (rowIndex < self.departures.safeItemCount)
    {
        WatchDepartureUI *ui = [WatchDepartureUI createFromData:[self.departures itemAtIndex:rowIndex]];
        [self pushControllerWithName:@"Arrival Details" context:ui];
    }
    else
    {
        [self refresh:nil];
    }
}



- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    
    [self startTimer];

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
    if (self.departures.locLat)
    {
        [self pushControllerWithName:@"Nearby" context:[self.departures getLocation]];
    }
}
- (IBAction)menuItemHome {
    [self popToRootController];
}
@end



