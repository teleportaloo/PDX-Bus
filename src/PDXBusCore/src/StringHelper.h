//
//  StringHelper.h
//  PDXBusCore
//
//  Created by Andrew Wallace on 11/7/15.
//  Copyright © 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import <Foundation/NSEnumerator.h>

@class UIFont;

@interface  NSString(PDXBus)

@property (nonatomic, readonly) unichar firstUnichar;
@property (nonatomic, readonly, copy) NSMutableAttributedString *mutableAttributedString;
@property (nonatomic, readonly) NSString *stringWithTrailingSpacesRemoved;
@property (nonatomic, readonly) NSMutableArray *arrayFromCommaSeparatedString;

- (NSAttributedString*)formatAttributedStringWithFont:(UIFont *)regularFont;
- (NSMutableArray *)arrayFromCommaSeparatedString;
+ (NSMutableString *)commaSeparatedStringFromEnumerator:(id<NSFastEnumeration>)container selector:(SEL)selector;

@end

