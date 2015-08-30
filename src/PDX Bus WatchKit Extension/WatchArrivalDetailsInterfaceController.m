//
//  WatchArrivalDetailsInterfaceController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/17/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

#import "WatchArrivalDetailsInterfaceController.h"
#import "XMLDetour.h"
#import "Detour.h"
#import "WatchMapHelper.h"
#import "WatchDetour.h"
#import "XMLStreetcarLocations.h"
#import "XMLStreetcarPredictions.h"

@interface WatchArrivalDetailsInterfaceController ()

@end

@implementation WatchArrivalDetailsInterfaceController

@synthesize dep = _dep;

- (void)dealloc
{
    self.dep = nil;
    
    [super dealloc];
}

- (void)networkTimeout
{
    [self.detourTable setNumberOfRows:1 withRowType:@"Detour"];
    WatchDetour *detUI = [self.detourTable rowControllerAtIndex:0];
    detUI.detourText.text = @"Network timeout";
}

- (void)noDetours
{
    [self.detourTable setNumberOfRows:1 withRowType:@"Detour"];
    WatchDetour *detUI = [self.detourTable rowControllerAtIndex:0];
    detUI.detourText.text = @"No detours for this route";
}

- (id)backgroundTask
{
    DepartureData *dep = self.dep.data;
    XMLDetour *detour = [[[XMLDetour alloc] init] autorelease];
    NSError *error=nil;
    [detour getDetourForRoute:self.dep.data.route parseError:&error];
    
    if (dep.needToFetchStreetcarLocation)
    {
        NSString *streetcarRoute = dep.route;
        NSError *parseError = nil;
        
        if (dep.streetcarId == nil)
        {
            // First get the arrivals via next bus to see if we can get the correct vehicle ID
            XMLStreetcarPredictions *streetcarArrivals = [[XMLStreetcarPredictions alloc] init];
            
            NSError *error = nil;
            
            [streetcarArrivals getDeparturesForLocation:[NSString stringWithFormat:@"predictions&a=portland-sc&r=%@&stopId=%@", streetcarRoute,dep.locid]
                                             parseError:&error];
            
            for (NSInteger i=0; i< streetcarArrivals.safeItemCount; i++)
            {
                DepartureData *vehicle = [streetcarArrivals itemAtIndex:i];
                
                if ([vehicle.block isEqualToString:dep.block])
                {
                    dep.streetcarId = vehicle.streetcarId;
                    break;
                }
            }
            
            [streetcarArrivals release];
        }
        
        // Now get the locations of the steetcars and find ours
        XMLStreetcarLocations *locs = [XMLStreetcarLocations getSingletonForRoute:streetcarRoute];
        [locs getLocations:&parseError];
        
        if (dep.streetcar && [dep.route isEqualToString:streetcarRoute])
        {
            [locs insertLocation:dep];
        }
        
    }
    return detour;
}

- (void)updateMap
{
    if (self.dep.data.blockPositionLat!=nil || self.dep.data.stopLat!=nil)
    {
        CLLocation *stopLocation = [[[CLLocation alloc] initWithLatitude:[self.dep.data.stopLat doubleValue] longitude:[self.dep.data.stopLng doubleValue]] autorelease];
        NSArray *redPins = nil;
        
        if (self.dep.data.blockPositionLat!=nil)
        {
            CLLocation *carLocation = [[[CLLocation alloc] initWithLatitude:[self.dep.data.blockPositionLat doubleValue] longitude:[self.dep.data.blockPositionLng doubleValue]] autorelease];
            
            redPins = [NSArray arrayWithObjects:carLocation, nil];
            
        }
        
        [WatchMapHelper displayMap:self.map purplePin:stopLocation redPins:redPins];
        
    }
    else
    {
        self.map.hidden = YES;
    }
}


- (void)taskFinishedMainThread:(id)arg
{
    XMLDetour *detour = arg;
    
    if (detour.safeItemCount > 0)
    {
        [self.detourTable setNumberOfRows:detour.safeItemCount withRowType:@"Detour"];
        
        for (NSInteger i = 0; i< detour.safeItemCount; i++)
        {
            Detour *det = [detour itemAtIndex:i];
            WatchDetour *detUI = [self.detourTable rowControllerAtIndex:i];
            detUI.detourText.text = det.detourDesc;
        }
    }
    else if (!detour.gotData)
    {
        [self networkTimeout];
    }
    else
    {
        [self noDetours];
    }
    
    [self updateMap];
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.dep = context;
    
    // Configure interface objects here.
    
    bool needsToFetch = NO;
    
    NSMutableString *detourText = [[[NSMutableString alloc] init] autorelease];
    
    if (self.dep.data.detour)
    {
        [detourText appendFormat:@"⚠️Detour(s):"];
        
        [self.detourTable setNumberOfRows:1 withRowType:@"Detour"];
        WatchDetour *detUI = [self.detourTable rowControllerAtIndex:0];
        detUI.detourText.text = @"Loading";
        
        needsToFetch = YES;
        
    }
    else
    {
        [self noDetours];
    }
    
    if (self.dep.data.needToFetchStreetcarLocation)
    {
        needsToFetch = YES;
    }
    
    if (needsToFetch)
    {
        [self startBackgroundTask];
    }
    else
    {
        [self updateMap];
    }
    
    NSInteger mins = self.dep.data.minsToArrival;
    NSDate *depatureDate = [NSDate dateWithTimeIntervalSince1970: TriMetToUnixTime(self.dep.data.departureTime)];
    NSMutableString *timeText = [[[NSMutableString alloc] init] autorelease];
    NSMutableString *scheduledText = [[[NSMutableString alloc] init] autorelease];
    UIColor *timeColor = nil;
    
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    // If date is tomorrow and more than 12 hours away then put the full date
    if (([[dateFormatter stringFromDate:depatureDate] isEqualToString:[dateFormatter stringFromDate:[NSDate date]]])
        || ([depatureDate timeIntervalSinceDate:[NSDate date]] < 12 * 60 * 60)
        || self.dep.data.status == kStatusEstimated)
    {
        [dateFormatter setDateStyle:NSDateFormatterNoStyle];
    }
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    
    if (mins < 0 && self.dep.data.status != kStatusCancelled)
    {
        [timeText appendString:NSLocalizedString(@"Gone - ", @"first part of text to display on a single line if a bus has gone")];
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];
        timeColor = [UIColor redColor];
    }
    else if (mins == 0 && self.dep.data.status != kStatusCancelled)
    {
        [timeText appendString:NSLocalizedString(@"Due - ", @"first part of text to display on a single line if a bus is due")];
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];
        timeColor = [UIColor redColor];
    }
    else if (mins == 1 && self.dep.data.status != kStatusCancelled)
    {
        [timeText appendString:NSLocalizedString(@"1 min - ", @"first part of text to display on a single line if a bus is due in 1 minute")];
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];
        timeColor = [UIColor redColor];
    }
    else if (mins < 6 && self.dep.data.status != kStatusCancelled)
    {
        [timeText appendFormat:NSLocalizedString(@"%lld mins - ", @"first part of text to display on a single line if a bus is due in several minutes"), mins];
        [timeText appendString:[dateFormatter stringFromDate:depatureDate]];
        [timeText appendString:@" "];
        timeColor = [UIColor redColor];
    }
    else if (mins < 60 && self.dep.data.status != kStatusCancelled)
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
    
    switch (self.dep.data.status)
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
    
    if (self.dep.data.status != kStatusScheduled && self.dep.data.scheduledTime !=0 && (self.dep.data.scheduledTime/60000) != (self.dep.data.departureTime/60000))
    {
        NSDate *scheduledDate = [NSDate dateWithTimeIntervalSince1970: TriMetToUnixTime(self.dep.data.scheduledTime)];
        [scheduledText appendFormat:NSLocalizedString(@"scheduled %@ ",@"info about arrival time"), [dateFormatter stringFromDate:scheduledDate]];;
    }
    
    NSMutableAttributedString * string = [[[NSMutableAttributedString alloc] initWithString:@""] autorelease];
    NSString *fullsign = [NSString stringWithFormat:@"%@\n", self.dep.data.fullSign];
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    NSAttributedString *subString = [[[NSAttributedString alloc] initWithString:fullsign attributes:attributes] autorelease];
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
    
    self.labelScheduleInfo.attributedText = string;
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)menuItemHome {
    [self popToRootController];
}
@end



