//
//  KMLPlacemark.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/21/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "ShapeRoutePath.h"

@interface KMLPlacemark : NSObject

@property (nonatomic, copy, setter = setXml_route_number:) NSString *strInternalRouteNumber;
@property (nonatomic) NSInteger internalRouteNumber;
@property (nonatomic, copy, setter = setXml_direction:) NSString *dir;
@property (nonatomic, copy, setter = setXml_route_description:) NSString *routeDescription;
@property (nonatomic, copy, setter = setXml_public_route_number:) NSString *displayRouteNumber;
@property (nonatomic, copy, setter = setXml_direction_description:) NSString *dirDesc;
@property (nonatomic, strong) ShapeRoutePath *path;

// Not used - could be later
// @property (nonatomic, copy) NSString *xfrequent;
// @property (nonatomic, copy) NSString *xtype;


@end
