//
//  iOSCompat.h
//  PDXBusCore
//
//  Created by Andrew Wallace on 2/29/16.
//  Copyright © 2016 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#ifndef iOSCompat_h
#define iOSCompat_h

#define compatSetIfExists(O, S, V)                                             \
    if ([O respondsToSelector:@selector(S)]) {                                 \
        [O S V];                                                               \
    }
#define compatCallIfExists(O, S)                                               \
    if ([O respondsToSelector:@selector(S)]) {                                 \
        [O S];                                                                 \
    }

#endif /* iOSCompat_h */
