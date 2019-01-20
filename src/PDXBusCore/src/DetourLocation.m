//
//  DetourLocation.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/7/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DetourLocation.h"
#import "StringHelper.h"

@implementation DetourLocation


- (void)setPassengerCodeFromString:(NSString*)string
{
    if (string == nil || string.length==0)
    {
        self.passengerCode = PassengerCodeUnknown;
    }
    else
    {
        self.passengerCode = string.firstUnichar;
    }
}


@end
