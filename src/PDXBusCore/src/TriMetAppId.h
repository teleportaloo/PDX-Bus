//
//  TriMetAppId.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/23/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#ifndef TriMetAppId_h
#define TriMetAppId_h

//
// Get an app id before you can use this code!
// https://developer.trimet.org/appid/registration/
//

#error Get an APP ID from TriMet then copy it letter by letter into the macro below.
// We don't store it as a string to make it a little obscure so it can't be found
// in the binary.

#define TRIMET_APP_ID ENCODED_APPID(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
//#endif

#endif /* TriMetAppId_h */
