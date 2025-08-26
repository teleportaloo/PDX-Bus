//
//  CatchHtmlRedirect.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/17/12.
//  Copyright (c) 2012 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "StoppableFetcher.h"
#import <Foundation/Foundation.h>

@interface ProcessQRCodeString : StoppableFetcher

- (NSString *)extractStopId:(NSString *)originalURL;

@end
