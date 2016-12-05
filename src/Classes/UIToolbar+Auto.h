//
//  CustomToolbar.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/22/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>


@interface UIToolbar (Auto) {

}

+ (UIBarButtonItem *)autoFlexSpace;
+ (UIBarButtonItem *)autoDoneButtonWithTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)autoRedoButtonWithTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)autoFlashButtonWithTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)autoMapButtonWithTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)autoMagnifyButtonWithTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)autoNoSleepWithTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)autoCommuteWithTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)autoLocateWithTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)autoQRScanner:(id)target action:(SEL)action;


@end
