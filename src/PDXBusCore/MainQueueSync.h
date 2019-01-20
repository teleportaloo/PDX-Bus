//
//  MainQueueSync.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/5/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MainQueueSync : NSObject

+(void) runSyncOnMainQueueWithoutDeadlocking:(void (^)(void))block;

@end

NS_ASSUME_NONNULL_END
