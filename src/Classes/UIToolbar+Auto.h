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

#define TOOLBAR_PLACEHOLDER(X, Y) if (X.image == nil) { X.title = Y; }


@interface UIToolbar (Auto) {
}

+ (UIBarButtonItem *)flexSpace;
+ (UIBarButtonItem *)doneButtonWithTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)redoButtonWithTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)flashButtonWithTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)mapButtonWithTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)magnifyButtonWithTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)noSleepButtonWithTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)commuteButtonWithTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)settingsButtonWithTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)locateButtonWithTarget:(id)target action:(SEL)action;
+ (UIBarButtonItem *)qrScannerButtonWithTarget:(id)target action:(SEL)action;


@end
