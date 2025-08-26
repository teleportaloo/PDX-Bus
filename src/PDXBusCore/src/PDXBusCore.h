//
//  PDXBusCore.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/12/17.
//  Copyright © 2017 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#ifndef PDXBusCore_h
#define PDXBusCore_h

#ifdef PDXBUS_WATCH
#import <WatchKit/WatchKit.h>
#else

#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#define PDXBUS_NO_UIKIT
#endif

#endif

#endif /* PDXBusCore_h */
