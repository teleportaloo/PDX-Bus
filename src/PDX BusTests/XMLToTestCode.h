//
//  XMLToTestCode.h
//  PDX BusTests
//
//  Created by Andrew Wallace on 10/4/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */




#import "../PDXBusCore/src/TriMetXML.h"

NS_ASSUME_NONNULL_BEGIN

@interface XMLToTestCode : TriMetXML

@property (nonatomic, strong) NSMutableString *result;

@end

NS_ASSUME_NONNULL_END
