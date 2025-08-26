//
//  DetourUI.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/5/16.
//  Copyright © 2016 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Detour.h"

#define kDetourResuseIdentifier @"Detour"
#define kSystemDetourResuseIdentifier @"SystemAlert"

@interface Detour (iOSUI)

- (NSString *)reuseIdentifer;
- (NSString *)markedUpHeader;
- (NSString *)markedUpDescription:(NSString *)additionalText;
- (NSString *)markedUpDescriptionWithHeader:(NSString *)additionalText;
- (NSString *)markedUpDescriptionWithoutInfo:(NSString *)additionalText;
- (bool)hasInfo;

+ (UILabel *)create_UITextView:(UIFont *)font;

@end
