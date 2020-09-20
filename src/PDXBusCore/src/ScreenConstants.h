//
//  ScreenConstants.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/5/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


/* Screen Widths of Devices
 
 
 iPad 2                  768
 iPad Air                768
 iPad Retina             768
 
 iPad Wide               1024
 
 iPhone 4 / 4S           320
 iPhone 5 / 5S           320
 iPhone 6                375
 iPhone 6 Plus           414

*/

#define kLargeScreenWidth   694

#ifdef PDXBUS_EXTENSION
#define LARGE_SCREEN        NO
#else
#define LARGE_SCREEN        ([UIApplication sharedApplication].delegate.window.bounds.size.width >= kLargeScreenWidth)
#endif

#define SMALL_SCREEN            !(LARGE_SCREEN)


typedef enum {
	WidthiPhone         = 320,
    WidthiPhone6        = 375,
    WidthiPhone6Plus    = 414,
    MaxiPhoneWidth      = 414,
	WidthBigVariable	= 768,
	WidthiPadWide	    = 1024
} ScreenWidth;

#define ScaleFromiPhone(X, W) ((( (double)X) / (double)WidthiPhone) * (double)(W) )

typedef struct _ScreenInfo
{
    ScreenWidth screenWidth;
    CGFloat     appWinWidth;
} ScreenInfo;

#define VerdanaScale(PT) ((PT)*0.9)
