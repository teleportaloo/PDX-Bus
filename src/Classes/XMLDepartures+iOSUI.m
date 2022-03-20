//
//  XMLDeparturesUI.m
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLDepartures+iOSUI.h"
#import "Departure.h"
#import "DebugLogging.h"
#import "DepartureData+iOSUI.h"

@implementation XMLDepartures (iOSUI)

#pragma mark Map Pin callbacks


- (NSString *)pinStopId {
    return self.stopId;
}

- (bool)pinActionMenu {
    return YES;
}

- (NSString *)pinMarkedUpType
{
    return nil;
}

// MK Annotate
- (CLLocationCoordinate2D)coordinate {
    return self.loc.coordinate;
}

- (NSString *)title {
    return self.locDesc;
}

- (MapPinColorValue)pinColor {
    return MAP_PIN_COLOR_PURPLE;
}

#pragma mark Data accessors

- (id)depXML {
    return self;
}

- (Departure *)depGetDeparture:(NSInteger)i {
    return self[i];
}

- (NSInteger)depGetSafeItemCount {
    return self.count;
}

- (NSString *)depGetSectionHeader {
    if (self.locDir != nil && self.locDir.length != 0) {
        return [NSString stringWithFormat:@"%@ (%@)", self.locDesc, self.locDir];
    }
    
    return self.locDesc;
}

- (NSString *)depGetSectionTitle {
    return self.sectionTitle;
}

- (void)depPopulateCell:(Departure *)dd cell:(DepartureCell *)cell decorate:(BOOL)decorate wide:(BOOL)wide {
    [dd populateCell:cell decorate:decorate busName:YES fullSign:wide];
}

- (NSString *)depStaticText {
    return [NSString stringWithFormat:@"Stop ID %@.", self.stopId];
}

- (StopDistance *)depDistance {
    return self.distance;
}

- (NSDate *)depQueryTime {
    return self.queryTime;
}

- (CLLocation *)depLocation {
    return self.loc;
}

- (NSString *)depLocDesc {
    return self.locDesc;
}

- (NSString *)depStopId {
    return self.stopId;
}

- (bool)depHasDetails {
    return TRUE;
}

- (bool)depNetworkError {
    return !self.gotData;
}

- (NSString *)depErrorMsg {
    return self.networkErrorMsg;
}

- (NSString *)depDir {
    return self.locDir;
}

- (NSData *)depHtmlError {
    return self.htmlError;
}

- (UIColor *)pinTint {
    return nil;
}

- (bool)pinHasBearing {
    return NO;
}

- (Detour *)depDetour {
    return nil;
}

- (NSOrderedSet<NSNumber *> *)depDetoursPerSection {
    return self.detourSorter.detourIds;
}

@end
