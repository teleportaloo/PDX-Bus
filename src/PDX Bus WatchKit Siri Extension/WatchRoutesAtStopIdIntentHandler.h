//
//  WatchRoutesAtStopIdIntentHandler.h
//  PDX Bus WatchKit Siri Extension
//
//  Created by Andrew Wallace on 5/24/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "RoutesAtStopIdIntent.h"

NS_ASSUME_NONNULL_BEGIN

@interface WatchRoutesAtStopIdIntentHandler<RoutesAtStopIdIntentHandling> : NSObject

- (void)handleRoutesAtStopId:(RoutesAtStopIdIntent *)intent
                  completion:(void (^)(RoutesAtStopIdIntentResponse *response))completion API_AVAILABLE(ios(12.0));


@end

NS_ASSUME_NONNULL_END
