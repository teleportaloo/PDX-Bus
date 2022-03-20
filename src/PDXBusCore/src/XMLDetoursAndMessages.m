//
//  XMLDetoursAndMessages.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/29/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "XMLDetoursAndMessages.h"
#import "RunParallelBlocks.h"

@implementation XMLDetoursAndMessages


- (void)checkRoutesForStreetcar:(NSArray<NSString *> *)routes {
    bool needMessages = NO;
    
    self.routes = routes;
    
    if (self.routes == nil) {
        needMessages = YES;
    } else {
        NSSet<NSString *> *streetcarRoutes = [TriMetInfo streetcarRoutes];
        
        for (NSString *route in self.routes) {
            if ([streetcarRoutes containsObject:route]) {
                needMessages = YES;
                break;
            }
        }
    }
    
    if (needMessages) {
        self.messages = [XMLStreetcarMessages sharedInstance];
        self.messages.allRoutes = self.detours.allRoutes;
    } else {
        self.messages = nil;
    }
}

+ (instancetype)xmlWithRoutes:(NSArray<NSString *> *)routes {
    return [[[self class] alloc] initWithRoutes:routes];
}

- (instancetype)initWithRoutes:(NSArray *)routes {
    if (self = [super init]) {
        self.detours = [XMLDetours xml];
        [self checkRoutesForStreetcar:routes];
    }
    
    return self;
}

- (NSInteger)itemsNeeded {
    NSInteger items = 1;
    
    if (self.messages && self.messages.needToGetMessages) {
        items++;
    }
    
    return items;
}

- (void)fetchDetoursAndMessages {
    _hasData = NO;
    
    self.detours.oneTimeDelegate = self.oneTimeDelegate;
    self.messages.oneTimeDelegate = self.oneTimeDelegate;
    self.oneTimeDelegate = nil;
    
    RunParallelBlocks *parallelBlocks = [RunParallelBlocks instance];
    
    [parallelBlocks startBlock:^{
        if (self.routes && self.routes.count == 1) {
            [self.detours getDetoursForRoute:self.routes.firstObject];
        } else if (self.routes && self.routes.count > 1) {
            [self.detours getDetoursForRoutes:self.routes];
        } else if (self.routes == nil) {
            [self.detours getDetours];
        }
    }];
    
    if (self.messages) {
        [parallelBlocks startBlock:^{
            [self.messages getMessages];
        }];
    }
    
    [parallelBlocks waitForBlocks];
    
    _hasData = self.detours.gotData;
    
    self.items = self.detours.items;
    
    if (self.messages)
    {
        _hasData = _hasData | self.messages.gotData;
        
        if (self.routes == nil) {
            [self.items addObjectsFromArray:self.messages.items];
        } else {
            NSSet<NSString *> *routeSet = [NSSet setWithArray:self.routes];
            
            for (Detour *detour in self.messages) {
                for (Route *route in detour.routes) {
                    if ([routeSet containsObject:route.route]) {
                        [self.items addObject:detour];
                        break;
                    }
                }
            }
        }
    }
}

- (void)appendQueryAndData:(NSMutableData *)buffer {
    [self.detours appendQueryAndData:buffer];
    
    if (self.messages) {
        [self.messages appendQueryAndData:buffer];
    }
}

@end
