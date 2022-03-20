//
//  ViewControllerBase+MapPinAction.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/15/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ViewControllerBase.h"
#import "MapPin.h"

NS_ASSUME_NONNULL_BEGIN

@interface ViewControllerBase (MapPinAction)

- (bool (^__nullable)(id<MapPin> pin, NSURL *url, UIView *source))linkActionForPin;


@end

NS_ASSUME_NONNULL_END
