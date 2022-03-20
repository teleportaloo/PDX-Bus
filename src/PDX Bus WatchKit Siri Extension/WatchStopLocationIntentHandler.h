//
//  WatchStopLocationIntentHandler.h
//  PDX Bus WatchKit Siri Extension
//
//  Created by Andrew Wallace on 5/24/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StopLocationIntent.h"

NS_ASSUME_NONNULL_BEGIN

@interface WatchStopLocationIntentHandler<StopLocationIntentHandling> : NSObject

- (void)handleStopLocation:(StopLocationIntent *)intent
                completion:(void (^)(StopLocationIntentResponse *response))completion API_AVAILABLE(ios(12.0));


@end

NS_ASSUME_NONNULL_END
