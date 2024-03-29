//
//  ViewControllerBase+DetourTableViewCell.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/6/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ViewControllerBase.h"
#import "DetourTableViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface ViewControllerBase (DetourTableViewCell)

- (bool)detourLink:(NSString *)link detour:(Detour *)detour source:(UIView*)view;

- (DetourUrlAction)detourActionCalback;


@end

NS_ASSUME_NONNULL_END
