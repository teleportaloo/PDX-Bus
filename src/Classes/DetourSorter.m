//
//  DetourSorter.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/7/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//

#import "DetourSorter.h"

@implementation DetourSorter


- (instancetype)init {
    if ((self = [super init])) {
        self.detourIds = [NSMutableOrderedSet orderedSet];
        self.allDetours = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)add:(Detour *)detour
{
    if (![self.detourIds containsObject:detour.detourId])
    {
        [self.detourIds addObject:detour.detourId];
        if (detour.systemWide)
        {
            self.systemWideCount++;
        }
    }
    
    if (self.allDetours[detour.detourId] == nil)
    {
        [self.allDetours setObject:detour forKey:detour.detourId];
    }
}

- (void)clear
{
    self.detourIds = [NSMutableOrderedSet orderedSet];
    self.systemWideCount = 0;
}

- (void)sort
{
    [self.detourIds sortUsingComparator:^NSComparisonResult(NSNumber * _Nonnull detourId1, NSNumber * _Nonnull detourId2) {
        Detour *d1 = self.allDetours[detourId1];
        Detour *d2 = self.allDetours[detourId2];
        
        return [d1 compare:d2];
    }];
    
    self.systemWideCount = 0;
    
    for (NSNumber *detourId in self.detourIds)
    {
        if (_allDetours[detourId].systemWide)
        {
            self.systemWideCount++;
        }
    }
}

@end
