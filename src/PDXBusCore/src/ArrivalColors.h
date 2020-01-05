//
//  ArrivalColors.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/24/17.
//  Copyright © 2017 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#ifndef ArrivalColors_h
#define ArrivalColors_h

#define ArrivalColorSoon        [UIColor redColor]
#define ArrivalColorLate        [UIColor magentaColor]
#ifdef PDXBUS_WATCH
#define ArrivalColorOK          [UIColor blueColor]
#else
#define ArrivalColorOK          [UIColor modeAwareBlue]
#endif
#define ArrivalColorScheduled   [UIColor grayColor]
#define ArrivalColorCanceled   [UIColor orangeColor]
#ifdef PDXBUS_WATCH
#define ArrivalColorDeparted    [UIColor blackColor]
#else
#define ArrivalColorDeparted    [UIColor modeAwareText]
#endif
#define ArrivalColorDelayed     [UIColor orangeColor]
#define ArrivalColorOffRoute    [UIColor orangeColor]

#endif /* ArrivalColors_h */
