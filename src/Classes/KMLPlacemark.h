//
//  KMLPlacemark.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/21/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "ShapeRoutePath.h"
#import "DataFactory.h"

@interface KMLPlacemark : DataFactory

@property (nonatomic, copy) NSString *xroute_number;
@property (nonatomic, copy) NSString *xdirection;
@property (nonatomic, copy) NSString *xroute_description;
@property (nonatomic, copy) NSString *xpublic_route_number;
@property (nonatomic, copy) NSString *xdirection_description;
@property (nonatomic, strong) ShapeRoutePath *path;

// Not used - could be later
// @property (nonatomic, copy) NSString *xfrequent;
// @property (nonatomic, copy) NSString *xtype;


@end
