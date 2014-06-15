//
//  RouteColorBlobView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/6/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TriMetRouteColors.h"


#define COLOR_STRIPE_WIDTH 10.0

@interface RouteColorBlobView : UIView {
	CGFloat _red;
	CGFloat _green;
	CGFloat _blue;
    bool    _square;
}

@property (nonatomic) CGFloat red;
@property (nonatomic) CGFloat green;
@property (nonatomic) CGFloat blue;
@property (nonatomic) bool square;

- (void)setRouteColor:(NSString *)route;
- (bool)setRouteColorLine:(RAILLINES)line;

@end
