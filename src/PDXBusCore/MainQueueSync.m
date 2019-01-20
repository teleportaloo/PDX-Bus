//
//  MainQueueSync.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/5/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//

#import "MainQueueSync.h"

@implementation MainQueueSync


+ (void)runSyncOnMainQueueWithoutDeadlocking:(void (^)(void))block
{
    static dispatch_once_t onceTokenAndKey;
    static void *contextValue = (void*)1;
    
    dispatch_once(&onceTokenAndKey, ^{
        dispatch_queue_main_t queue = dispatch_get_main_queue();
        dispatch_queue_set_specific (queue, &onceTokenAndKey, contextValue, NULL);
    });
    
    if (dispatch_get_specific (&onceTokenAndKey) == contextValue)
    {
        block ();
    }
    else
    {
        dispatch_sync (dispatch_get_main_queue(), block);
    }
}

@end
