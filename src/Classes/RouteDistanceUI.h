//
//  RouteDistanceUI.h
//  PDX Bus
//
//  Created by Andrew Wallace on 1/9/11.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import <Foundation/Foundation.h>
#import "ScreenConstants.h"
#import "RouteDistanceData.h"


#define kRouteCellHeight	 55
#define kRouteWideCellHeight 85

@interface RouteDistanceUI : NSObject {
    RouteDistanceData *_data;
}


+ (RouteDistanceUI*)createFromData:(RouteDistanceData*)data;
- (NSString *)cellReuseIdentifier:(NSString *)identifier width:(ScreenWidth)width;
- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier width:(ScreenWidth)width;
- (void)populateCell:(UITableViewCell *)cell wide:(BOOL)wide;

@property (nonatomic, retain) RouteDistanceData *data;


@end
