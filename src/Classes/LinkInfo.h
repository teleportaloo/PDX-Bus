//
//  LinkInfo.h
//  PDX Bus
//
//  Created by Andy Wallace on 2/23/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "PlistParams.h"

NS_ASSUME_NONNULL_BEGIN


@interface LinkInfo : PlistParams

@property(readonly, nonatomic, copy) NSString *valLinkFull;
@property(readonly, nonatomic, copy) NSString *valLinkMobile;
@property(readonly, nonatomic, copy) NSString *valLinkTitle;
@property(readonly, nonatomic, copy) NSString *valLinkIcon;

@end

@interface NSDictionary (LinkInfo)
- (LinkInfo *)linkInfo;
@end

NS_ASSUME_NONNULL_END
