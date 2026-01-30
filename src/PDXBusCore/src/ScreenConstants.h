//
//  ScreenConstants.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/5/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define kLargeScreenWidth 694

#ifdef PDXBUS_EXTENSION
#define LARGE_SCREEN NO
#else

#define SCREEN_WIDTH (UIApplication.appRect.size.width ?: UIScreen.mainScreen.bounds.size.width)
#define LARGE_SCREEN                                                                               \
    ((UIApplication.appRect.size.width >= kLargeScreenWidth) ||                                    \
     (UIApplication.appRect.size.width == 0 &&                                                     \
      UIScreen.mainScreen.bounds.size.width >= kLargeScreenWidth))
#endif // PDXBUS_EXTENSION

#define SMALL_SCREEN !(LARGE_SCREEN)
