//
//  FlashViewController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 1/31/09.



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import <UIKit/UIKit.h>
#import "TorchController.h"
#import "ViewControllerBase.h"
#include "UserPrefs.h"

@interface FlashViewController : ViewControllerBase {
    int                 _color;
    TorchController *   _torch;
}

@property (nonatomic, strong) NSTimer *flashTimer;


@end
