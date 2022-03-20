//
//  RunParallelBlocks.m
//  PDX Bus
//
//  Created by Andrew Wallace on 5/30/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RunParallelBlocks.h"
#import "DebugLogging.h"
#import "Settings.h"

#define DEBUG_LEVEL_FOR_FILE kLogTask

@interface RunParallelBlocks ()

@property (nonatomic, strong)       NSMutableSet<NSThread *> *runningThreads;
@property (nonatomic, strong)       NSMutableSet<NSNumber *> *runningBlocks;
@property (nonatomic)               NSInteger items;
@property (nonatomic, strong)       dispatch_semaphore_t allDone;

@end

@implementation RunParallelBlocks

+ (instancetype)instance {
    return [[[self class] alloc] init];
}

- (instancetype)init {
    if ((self = [super init])) {
        self.runningThreads = [[NSMutableSet alloc] init];
        self.runningBlocks = [[NSMutableSet alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    DEBUG_FUNC();
}

- (void)runBlock:(ParallelBlock)block {
    block();
}

- (void)startBlock:(ParallelBlock)block {
    @synchronized (self) {
        if (![NSThread currentThread].cancelled) {
            if (Settings.networkInParallel) {
                NSInteger key = self.items;
                self.items++;
                
                ParallelBlock wrapper = ^{
                    NSThread *thread = [NSThread currentThread];
                    
                    @synchronized (self) {
                        [self.runningThreads addObject:thread];
                    }
                    
                    block();
                    
                    @synchronized (self) {
                        [self.runningBlocks removeObject:@(key)];
                        [self.runningThreads removeObject:thread];
                        
                        if (self.runningBlocks.count == 0 && self.allDone != nil) {
                            dispatch_semaphore_signal(self.allDone);
                            DEBUG_LOGO(self.allDone);
                        }
                    }
                };
                
                [self.runningBlocks addObject:@(key)];
                [self performSelectorInBackground:@selector(runBlock:) withObject:[wrapper copy]];
            } else {
                self.items++;
                block();
            }
        }
    }
}

- (void)waitForBlocks {
    DEBUG_FUNC();
    @synchronized (self) {
        DEBUG_LOGL(self.runningBlocks.count);
        
        if (self.runningBlocks.count == 0) {
            DEBUG_FUNCEX();
            return;
        }
        
        self.allDone = dispatch_semaphore_create(0);
    }
    
    while (dispatch_semaphore_wait(self.allDone, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 0.2)) != 0) {
        
        DEBUG_LOGO(self.allDone);
        
        @synchronized (self) {
            DEBUG_LOGL(self.runningBlocks.count);
            
            if ([NSThread currentThread].cancelled) {
                DEBUG_LOG(@"Cancelled");
                
                for (NSThread *thread in self.runningThreads) {
                    [thread cancel];
                }
            }
        }
    }
    DEBUG_FUNCEX();
}

@end
