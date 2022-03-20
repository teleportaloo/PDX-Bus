//
//  DepartureTimesByBus.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/2/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DepartureTimesByBus.h"
#import "Departure.h"
#import "DepartureData+iOSUI.h"

@interface DepartureTimesByBus ()

@end

@implementation DepartureTimesByBus


- (instancetype)init {
    if ((self = [super init])) {
        self.departureItems = [NSMutableArray array];
    }
    
    return self;
}

#pragma mark Data Accessors

- (Departure *)depGetDeparture:(NSInteger)i {
    return self.departureItems[i];
}

- (NSInteger)depGetSafeItemCount {
    if (self.departureItems == nil) {
        return 0;
    }
    
    return self.departureItems.count;
}

- (NSString *)depGetSectionHeader {
    return self.departureItems.lastObject.shortSign;
}

- (NSString *)depGetSectionTitle {
    return nil;
}

- (void)depPopulateCell:(Departure *)dd cell:(DepartureCell *)cell decorate:(BOOL)decorate wide:(BOOL)wide {
    [dd populateCell:cell decorate:decorate busName:NO fullSign:wide];
}

- (NSString *)depStaticText {
    Departure *d = [self depGetDeparture:0];
    
    if (d.block != nil) {
        if (d.vehicleIds && d.vehicleIds.count > 0) {
            return [NSString stringWithFormat:NSLocalizedString(@"(Vehicle ID %@) ", @"trip info small text"), d.vehicleIds[0]];
        }
        
        return @"(No Vehicle ID)";
    }
    
    return NSLocalizedString(@"(" kBlockNameC "Trip ID unavailable)", @"error text");
}

- (StopDistance *)depDistance {
    return nil;
}

- (NSDate *)depQueryTime {
    return [self depGetDeparture:0].queryTime;
}

- (NSString *)depLocation {
    return nil;
}

- (NSString *)depLocDesc {
    Departure *dep = [self depGetDeparture:0];
    
    return dep.locationDesc;
}

- (NSString *)depStopId {
    return [self depGetDeparture:0].stopId;
}

- (NSString *)depDir {
    return [self depGetDeparture:0].locationDir;
}

- (bool)depHasDetails {
    return FALSE;
}

- (bool)depNetworkError {
    return self.departureItems == nil;
}

- (NSString *)depErrorMsg {
    return nil;
}

- (Detour *)depDetour {
    return nil;
}

- (NSData *)depHtmlError {
    return nil;
}

- (NSOrderedSet<NSNumber *> *)depDetoursPerSection {
    return [NSOrderedSet orderedSet];
}

@end
