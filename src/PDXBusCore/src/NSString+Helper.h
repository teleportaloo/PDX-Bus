//
//  NSString+Helper.h
//  PDXBusCore
//
//  Created by Andrew Wallace on 11/7/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import <Foundation/NSEnumerator.h>

@class UIFont;

@interface  NSString (Helper)

@property (nonatomic, readonly, copy) NSMutableAttributedString *_Nonnull mutableAttributedString;
@property (nonatomic, readonly, copy) NSAttributedString *_Nonnull attributedString;
@property (nonatomic, readonly) NSString *_Nonnull stringWithTrailingSpaceIfNeeded;
@property (nonatomic, readonly) NSString *_Nonnull stringByTrimmingWhitespace;
@property (nonatomic, readonly) unichar firstUnichar;
@property (nonatomic, readonly) unichar lastUnichar;

// A simple markup for basic text formatting.
// Use # as escape characters
// #b - bold text on or off
// #i - italic text on or off
// #h is used to escape - e.g. #h becomes #
// ## is also an escape
// #+ increases font size by 1 point
// #( decreases font size by 2 points
// #[ decreases font size by 4 points
// #- decreases font size by 1 point
// #) increases font size by 2 points
// #] increases font size by 4 points
// #f small font
// #F larger font (basic font)

// Colors:

//  #D - dark mode aware text (black or white)
//  #! - dark mode aware system-wide alert color (yellow or black)
//  #U - dark mode aware blue.

//  #0 - black
//  #O - orange
//  #G - green
//  #A - gray
//  #R - red
//  #B - blue
//  #C - cyan
//  #Y - yellow
//  #N - brown
//  #M - magenta
//  #W - white
//  #> - indent all by font point size
//  #< - decrease indentatation

// Links - there is a space after the URL to indicate the end
// #Lhttp://apple.com Text#T

- (NSMutableAttributedString *_Nonnull)attributedStringFromMarkUp;      // Uses large font
- (NSMutableAttributedString *_Nonnull)smallAttributedStringFromMarkUp;
- (NSMutableAttributedString *_Nonnull)attributedStringFromMarkUpWithFont:(UIFont *_Nullable)font;
- (NSString *_Nonnull)safeEscapeForMarkUp;
- (NSString *_Nonnull)removeMarkUp;
- (NSString * _Nonnull)markedUpLinkToStopId;

// URL encoding helpers
- (NSString *_Nonnull)percentEncodeUrl;
- (NSString *_Nonnull)fullyPercentEncodeString;

// Search helpers
- (bool)hasCaseInsensitiveSubstring:(NSString *_Nonnull)search;


// UI helpers
- (NSMutableString *_Nonnull)phonetic;
- (NSString *_Nonnull)justNumbers;

// Breaking down into arrays and back

- (NSMutableArray<NSString *> *_Nonnull)mutableArrayFromCommaSeparatedString;
+ (NSMutableString *_Nonnull)commaSeparatedStringFromStringEnumerator:(id<NSFastEnumeration> _Nonnull)container;

+ (NSMutableString *_Nonnull)commaSeparatedStringFromEnumerator:(id<NSFastEnumeration> _Nonnull)container
                                                 selToGetString:(SEL _Nonnull)selToGetString;

+ (NSMutableString *_Nonnull)textSeparatedStringFromEnumerator:(id<NSFastEnumeration> _Nonnull)container
                                                selToGetString:(SEL _Nonnull)selToGetString
                                                     separator:(NSString *_Nonnull)separator;

- (NSAttributedString *_Nonnull)attributedStringWithAttributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attrs;




@end
