//
//  ArrivalsIntentHandler.h
//  PDXBus Siri Extension
//
//  Created by Andrew Wallace on 9/23/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ArrivalsIntent.h"
#import "XMLDepartures.h"

#define kMaxRoutesToSpeak 6


@interface ArrivalsIntentHandler : NSObject

@property (strong, nonatomic) NSMutableArray<XMLDepartures *> *departures;
@property (atomic) bool responded;

- (void)handleArrivals:(ArrivalsIntent *)intent completion:(void (^)(ArrivalsIntentResponse *response))completion API_AVAILABLE(ios(12.0));
@end

