//
//  Detour+DTData.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/7/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Detour+DTData.h"
#import "UserPrefs.h"

@implementation Detour (DTData)


- (id)depXML
{
    return self;
}

- (Departure *)depGetDeparture:(NSInteger)i
{
    return nil;
}
- (NSInteger)depGetSafeItemCount
{
    return 0;
}
- (NSString *)depGetSectionHeader
{
    if ([[UserPrefs sharedInstance] isHiddenSystemWideDetour:self.detourId])
    {
        return nil;
    }
    return self.headerText;
}
- (NSString *)depGetSectionTitle
{
    return nil;
}

- (void)depPopulateCell:(Departure *)dd cell:(DepartureCell *)cell decorate:(BOOL)decorate wide:(BOOL)wide
{
    // [dd populateCell:cell decorate:decorate busName:YES wide:wide];
}
- (NSString *)depStaticText
{
    return nil;
}

- (StopDistance*)depDistance
{
    return nil;
}

- (NSDate *)depQueryTime
{
     return nil;
}

- (CLLocation *)depLocation
{
     return nil;
}

- (NSString *)depLocDesc
{
     return nil;
}

- (NSString *)depLocId
{
     return nil;
}

- (bool)depHasDetails
{
    return NO;
}

- (bool)depNetworkError
{
    return NO;
}

- (NSString *)depNetworkErrorMsg
{
    return nil;
}

- (NSString *)depDir
{
    return nil;
}

- (NSData *)depHtmlError
{
    return nil;
}


- (Detour *)depDetour
{
    return self;
}

-(NSOrderedSet<NSNumber*>*)depDetoursPerSection
{
    return [NSOrderedSet orderedSet];
}

@end
