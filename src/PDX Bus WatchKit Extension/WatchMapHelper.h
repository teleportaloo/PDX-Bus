//
//  WatchMapHelper.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/24/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface WatchMapHelper : NSObject

+ (void)displayMap:(WKInterfaceMap*)map purplePin:(CLLocation*)purplePin redPins:(NSArray*)redPins;

@end
