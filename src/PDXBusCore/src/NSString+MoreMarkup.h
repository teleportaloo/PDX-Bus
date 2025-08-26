//
//  NSString+Markup.h
//  PDXBusCore
//
//  Created by Andrew Wallace on 11/7/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "NSString+Markup.h"
#import <Foundation/Foundation.h>
#import <Foundation/NSEnumerator.h>

@class UIFont;

@interface NSString (MoreMarkup)

// Uses large font
- (NSMutableAttributedString *_Nonnull)attributedStringFromMarkUp;
- (NSMutableAttributedString *_Nonnull)smallAttributedStringFromMarkUp;
- (NSString *_Nonnull)markedUpLinkToStopId;

@end
