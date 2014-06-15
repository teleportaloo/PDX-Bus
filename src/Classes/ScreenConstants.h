//
//  ScreenConstants.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/5/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



typedef enum {
	WidthiPhoneNarrow = 0x01,
	//	WidthiPhoneWide   = 0x02,
	WidthiPadNarrow	  = 0x04,
	WidthiPadWide	  = 0x08,
	WidthiPad		  = 0x0C,
	WidthiPhone		  = 0x03,
	WidthWide		  = 0x0A
} ScreenType;

#define kLargestSmallScreenDimension	480
#define kSmallestSmallScreenDimension   320

#define SMALL_SCREEN(X) (((X) & WidthiPhone) !=0)
#define LARGE_SCREEN(X) (((X) & WidthiPad) !=0)
