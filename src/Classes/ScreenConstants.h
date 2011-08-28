//
//  ScreenConstants.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/5/10.
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