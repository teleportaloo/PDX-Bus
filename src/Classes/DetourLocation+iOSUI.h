//
//  DetourLocation+iOSUI.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/7/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DetourLocation.h"
#import "MapPinColor.h"

@interface DetourLocation (iOSUI) <MapPinColor>

// From Annotation
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;

// From MapPinColor
@property (nonatomic, readonly) MapPinColorValue pinColor;
@property (nonatomic, readonly) bool showActionMenu;

@end
