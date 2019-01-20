//
//  CatchHtmlRedirect.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/17/12.
//  Copyright (c) 2012 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "StoppableFetcher.h"

@interface ProcessQRCodeString : StoppableFetcher

@property (nonatomic, copy)   NSString *stopId;

- (NSString *)extractStopId:(NSString *)originalURL;

@end



