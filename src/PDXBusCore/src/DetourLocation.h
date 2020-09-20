//
//  DetourLocation.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/7/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <CoreLocation/CoreLocation.h>
#import "DataFactory.h"

typedef enum DetourPassengerCode {
    PassengerCodeUnknown       = 0,
    PassengerCodeEither        = 'E',
    PassengerCodeAlightingOnly = 'A',
    PassengerCodeBoardingOnly  = 'B',
    PassengerCodeNeither       = 'N'
} DetourPassengerCode;

@interface DetourLocation : DataFactory

@property (nonatomic)         DetourPassengerCode passengerCode;
@property (nonatomic)         bool noServiceFlag;
@property (nonatomic, strong) CLLocation *location;
@property (nonatomic, copy)   NSString *stopId;
@property (nonatomic, copy)   NSString *desc;
@property (nonatomic, copy)   NSString *dir;

- (void)setPassengerCodeFromString:(NSString *)string;

@end
