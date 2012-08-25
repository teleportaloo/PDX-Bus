//
//  CustomToolbar.h
//  PDX Bus
//
//  Created by Andrew Wallace on 6/22/09.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import <UIKit/UIKit.h>


@interface CustomToolbar : UIToolbar {

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
