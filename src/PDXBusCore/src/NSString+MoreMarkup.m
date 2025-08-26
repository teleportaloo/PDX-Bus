//
//  StringHelper.m
//  PDXBusCore
//
//  Created by Andrew Wallace on 11/7/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "DebugLogging.h"
#import "NSString+Markup.h"
#import "NSString+MoreMarkup.h"
#import "PDXBusCore.h"

#import "TaskDispatch.h"
#import "UIColor+MoreDarkMode.h"
#import "UIFont+Utility.h"

@implementation NSString (MoreMarkup)

- (NSMutableAttributedString *)smallAttributedStringFromMarkUp {
    return [self attributedStringFromMarkUpWithFont:UIFont.smallFont];
}

- (NSMutableAttributedString *)attributedStringFromMarkUp {
    return [self attributedStringFromMarkUpWithFont:UIFont.basicFont];
}

- (NSString *)markedUpLinkToStopId {
    return [NSString stringWithFormat:@"Stop ID #Lid:%@ %@#T", self, self];
}
@end
