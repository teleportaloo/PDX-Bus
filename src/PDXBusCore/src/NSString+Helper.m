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


#define DEBUG_LEVEL_FOR_FILE kLogUserInterface

#import "NSString+Helper.h"
#import "DebugLogging.h"
#import "PDXBusCore.h"
#import "UIColor+DarkMode.h"
#import "UIFont+Utility.h"

@implementation NSString (Helper)


- (unichar)firstUnichar {
    if (self.length > 0) {
        // This used to be called firstCharacter but when that is called it fails after creating a UIDocumentInteractionController.  Super weird.
        return [self characterAtIndex:0];
    }

    return 0;
}

- (unichar)lastUnichar {
    if (self.length > 0) {
        // This used to be called firstCharacter but when that is called it fails after creating a UIDocumentInteractionController.  Super weird.
        return [self characterAtIndex:self.length-1];
    }

    return 0;
}


- (NSMutableAttributedString *)mutableAttributedString {
    return [[NSMutableAttributedString alloc] initWithString:self];
}

- (NSString *)stringByTrimmingWhitespace {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)stringWithTrailingSpaceIfNeeded {
    if (self.length == 0) {
        return self;
    }

    return [self stringByAppendingString:@" "];
}

- (NSString *)phonetic {
    NSMutableString *ms = [NSMutableString stringWithString:self];

#define REG_WORD(X) @"\\b" X @"\\b"
#define CLEAR(X)    X, @""
    static NSArray *replacements;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        replacements = @[
            @[ CLEAR(@"\\(Stop ID \\d+\\)") ],
            @[ REG_WORD(@"SW"), @"southwest"],
            @[ REG_WORD(@"NW"), @"northwest"],
            @[ REG_WORD(@"SE"), @"southeast"],
            @[ REG_WORD(@"NE"), @"northeast"],
            @[ REG_WORD(@"N"), @"north"],
            @[ REG_WORD(@"S"), @"South"],
            @[ REG_WORD(@"E"), @"east"],
            @[ REG_WORD(@"W"), @"west"],
            @[ REG_WORD(@"ave"), @"avenue"],
            @[ REG_WORD(@"dr"), @"drive"],
            @[ REG_WORD(@"st"), @"street"],
            @[ REG_WORD(@"pkwy"), @"parkway"],
            @[ REG_WORD(@"ln"), @"lane"],
            @[ REG_WORD(@"ct"), @"court"],
            @[ REG_WORD(@"stn"), @"station"],
            @[ REG_WORD(@"TC"), @"transit center"],
            @[ REG_WORD(@"MAX"), @"max"],
            @[ REG_WORD(@"WES"), @"wes"],
            @[ REG_WORD(@"TriMet"), @"trymet"],
            @[ REG_WORD(@"Clackamas"), @"clack-a-mas"],
            @[ REG_WORD(@"Ctr"),    @"center"],
            @[ REG_WORD(@"ID"), @" I-D " ]
        ];
    });

    for (NSArray<NSString *> *rep in replacements) {
#define isUpper(X) ((X) >= 'A' && (X) <= 'Z')

        unichar decider = rep.lastObject.firstUnichar;
        NSRegularExpressionOptions opts = isUpper(decider) ? 0 : NSRegularExpressionCaseInsensitive;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:rep.firstObject
                                                                               options:opts
                                                                                 error:nil];
        [regex replaceMatchesInString:ms options:0
                                range:NSMakeRange(0, ms.length)
                         withTemplate:rep.lastObject];
    }

    return ms;
}

+ (NSMutableString *)textSeparatedStringFromEnumerator:(id<NSFastEnumeration>)container
                                        selToGetString:(SEL)selToGetString
                                             separator:(NSString *)separator {
    NSMutableString *string = [NSMutableString string];

    static Class stringClass;

    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        stringClass = [NSString class];
    });

    for (NSObject *obj in container) {
        if ([obj respondsToSelector:selToGetString]) {
            NSObject *(*getStringFromObj)(id, SEL) = (void *)[obj methodForSelector:selToGetString];
            NSObject *maybeString = getStringFromObj(obj, selToGetString);

            // NSObject *item = [obj performSelector:selector];
            if (maybeString != nil) {
                if ([maybeString isKindOfClass:stringClass]) {
                    if (string.length > 0) {
                        [string appendString:separator];
                    }

                    [string appendString:(NSString *)maybeString];
                } else {
                    ERROR_LOG(@"commaSeparatedStringFromEnumerator - selector did not return string %@\n",
                              NSStringFromSelector(selToGetString));
                }
            }
        } else {
            ERROR_LOG(@"commaSeparatedStringFromEnumerator - item does not respond to selector %@\n",
                      NSStringFromSelector(selToGetString));
        }
    }

    return string;
}

+ (NSMutableString *)commaSeparatedStringFromStringEnumerator:(id<NSFastEnumeration>)container; {
    return [NSString textSeparatedStringFromEnumerator:container selToGetString:@selector(self) separator:@","];
}

+ (NSMutableString *)commaSeparatedStringFromEnumerator:(id<NSFastEnumeration>)container selToGetString:(SEL)selToGetString; {
    return [NSString textSeparatedStringFromEnumerator:container selToGetString:selToGetString separator:@","];
}

- (NSMutableArray<NSString *> *)mutableArrayFromCommaSeparatedString {
    NSCharacterSet *comma = [NSCharacterSet characterSetWithCharactersInString:@","];
    NSMutableArray<NSString *> *array = [NSMutableArray array];
    NSScanner *scanner = [NSScanner scannerWithString:self];
    NSString *item;

    while ([scanner scanUpToCharactersFromSet:comma intoString:&item]) {
        [array addObject:item];

        if (!scanner.atEnd) {
            scanner.scanLocation++;
        }
    }
    return array;
}

- (UIFont *)updateFont:(UIFont *)font
             pointSize:(CGFloat)pointSize
                  bold:(bool)boldText
                italic:(bool)italicText {
    UIFontDescriptor *fontDescriptor = font.fontDescriptor;
    uint32_t traits = (boldText ? UIFontDescriptorTraitBold : 0) | (italicText ? UIFontDescriptorTraitItalic : 0);

    fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:traits];
    font = [UIFont fontWithDescriptor:fontDescriptor size:pointSize];

    DEBUG_LOGLX(traits);
    DEBUG_LOGF(pointSize);
    DEBUG_LOGP(font);

    return font;
}

- (void)addSegmentToString:(UIFont *)font
                     style:(NSParagraphStyle *)style
                     color:(UIColor *)color
                      link:(NSString *)link
                    string:(NSMutableAttributedString **)string {
// DEBUG_LOGS(substring);
    if (font == nil) {
        NSAttributedString *segment = self.attributedString;
        [*string appendAttributedString: segment];
        return;
    }

    NSAttributedString *segment = nil;
    NSMutableDictionary *attr = [NSMutableDictionary dictionary];

    attr[NSFontAttributeName] = font;
    attr[NSForegroundColorAttributeName] = color;

    if (style) {
        attr[NSParagraphStyleAttributeName] = style;
    }

    if (link) {
        attr[NSLinkAttributeName] = [NSURL URLWithString:link];
    }

    segment = [self attributedStringWithAttributes:attr];

    [*string appendAttributedString: segment];
}

- (NSMutableParagraphStyle *)indentStyle:(NSMutableParagraphStyle *)style size:(CGFloat)size {
    static NSMutableParagraphStyle *indentedStyle;

    static NSMutableData *syncObject;

    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        syncObject = [[NSMutableData alloc] initWithLength:1];
    });


// This is a cache of just one indented style, as we use only one
// indentation level.  If mulitple then it will keep creating new objects.
    @synchronized (syncObject) {
        if (size == 0) {
            return nil;
        }

        if (indentedStyle == nil || indentedStyle.headIndent != size) {
            indentedStyle = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
            indentedStyle.headIndent = size;
            indentedStyle.firstLineHeadIndent = size;
        }

        return indentedStyle;
    }
}

- (NSString *)percentEncodeUrl {
    return [self stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];
}

- (NSString *)fullyPercentEncodeString {
    return [self stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.alphanumericCharacterSet];
}

#define MARKUP_STRING @"#"

- (NSString *)safeEscapeForMarkUp {
    if (![self containsString:MARKUP_STRING]) {
        return self;
    }

    NSMutableString *string = [[NSMutableString alloc] init];
    NSScanner *escapeScanner = [NSScanner scannerWithString:self];

    escapeScanner.charactersToBeSkipped = nil;
    NSString *substring = nil;

    while (!escapeScanner.isAtEnd) {
        [escapeScanner scanUpToString:MARKUP_STRING intoString:&substring];

        if (substring != nil) {
            [string appendString:substring];
            substring = nil;
        }

        if (!escapeScanner.isAtEnd) {
            [string appendString:MARKUP_STRING @"h"];
            escapeScanner.scanLocation++;
        }
    }

    return string;
}

- (NSMutableAttributedString *)smallAttributedStringFromMarkUp {
    return [self attributedStringFromMarkUpWithFont:UIFont.smallFont];
}

- (NSMutableAttributedString *)attributedStringFromMarkUp {
    return [self attributedStringFromMarkUpWithFont:UIFont.basicFont];
}

#define FONT_DELTA_S (1.0)
#define FONT_DELTA_M (2.0)
#define FONT_DELTA_L (4.0)



// See header for formatting markup
- (NSMutableAttributedString *)attributedStringFromMarkUpWithFont:(UIFont *)font {
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    NSScanner *escapeScanner = [NSScanner scannerWithString:self];
    CGFloat pointSize = font ? font.pointSize : 10;
    CGFloat indent = pointSize * 2;
    CGFloat currentIndent = 0;
    UIColor *currentColor = [UIColor modeAwareText];
    NSString *substring = nil;
    bool italicText = NO;
    bool boldText = NO;
    bool fontChanged = YES;
    NSMutableParagraphStyle *style = nil;
    unichar c;
    NSString *link = nil;
    UIFont *currentFont = font;


    escapeScanner.charactersToBeSkipped = nil;

    while (!escapeScanner.isAtEnd) {
        @autoreleasepool {
            substring = nil;
            [escapeScanner scanUpToString:MARKUP_STRING intoString:&substring];

            // DEBUG_LOGS(substring);

            if (!escapeScanner.isAtEnd) {
                escapeScanner.scanLocation++;
            }

            if (!escapeScanner.isAtEnd) {
                c = [self characterAtIndex:escapeScanner.scanLocation];
                escapeScanner.scanLocation++;

                if (c == 'h' || c == '#') {
                    if (substring) {
                        substring = [substring stringByAppendingString:MARKUP_STRING];
                    } else {
                        substring = MARKUP_STRING;
                    }
                }

                if (substring && substring.length > 0) {
                    if (fontChanged && currentFont) {
                        currentFont = [self updateFont:currentFont pointSize:pointSize bold:boldText italic:italicText];
                        fontChanged = NO;
                    }

                    [substring addSegmentToString:currentFont
                                            style:style
                                            color:currentColor
                                             link:link
                                           string:&string];
                    substring = nil;
                }

                switch (c) {
                    default: break;

                    case 'f':

                        if (font) {
                            font = UIFont.smallFont;
                            pointSize = font.pointSize;
                            fontChanged = YES;
                        }

                        break;

                    case 'F':

                        if (font) {
                            font = UIFont.basicFont;
                            pointSize = font.pointSize;
                            fontChanged = YES;
                        }

                        break;

                    case 'h': break;

                    case '#': break;

                    case 'b':
                        boldText = !boldText;
                        fontChanged = YES;
                        break;

                    case 'i':
                        italicText = !italicText;
                        fontChanged = YES;
                        break;
                        
                    case '-':

                        if (pointSize > FONT_DELTA_S) {
                            pointSize -= FONT_DELTA_S;
                            fontChanged = YES;
                        }

                        break;

                    case '+':
                        pointSize += FONT_DELTA_S;
                        fontChanged = YES;
                        break;
                        
                        
                    case '(':

                        if (pointSize > FONT_DELTA_M) {
                            pointSize -= FONT_DELTA_M;
                            fontChanged = YES;
                        }

                        break;

                    case ')':
                        pointSize += FONT_DELTA_M;
                        fontChanged = YES;
                        break;
                        
                        
                    case '[':

                        if (pointSize > FONT_DELTA_L) {
                            pointSize -= FONT_DELTA_L;
                            fontChanged = YES;
                        }

                        break;

                    case ']':
                        pointSize += FONT_DELTA_L;
                        fontChanged = YES;
                        break;

                    case '0': currentColor = [UIColor blackColor];  break;

                    case 'O': currentColor = [UIColor orangeColor]; break;

                    case 'G': currentColor = [UIColor greenColor];  break;

                    case 'A': currentColor = [UIColor grayColor];   break;

                    case 'R': currentColor = [UIColor redColor];    break;

                    case 'B': currentColor = [UIColor blueColor];   break;

                    case 'C': currentColor = [UIColor cyanColor];   break;

                    case 'Y': currentColor = [UIColor yellowColor]; break;

                    case 'N': currentColor = [UIColor brownColor];  break;

                    case 'M': currentColor = [UIColor magentaColor]; break;

                    case 'W': currentColor = [UIColor whiteColor];  break;

                    case 'D': currentColor = [UIColor modeAwareText]; break;

                    case '!': currentColor = [UIColor modeAwareSystemWideAlertText]; break;

                    case 'U': currentColor = [UIColor modeAwareBlue]; break;

                    case '>': {
                        currentIndent += indent;
                        style = [self indentStyle:style size:currentIndent];
                        break;
                    }

                    case '<': {
                        currentIndent -= indent;
                        style = [self indentStyle:style size:currentIndent];
                        break;
                    }

                    case 'L': {
                        NSString *linkScan = nil;
                        [escapeScanner scanUpToString:@" " intoString:&linkScan];

                        if (linkScan) {
                            link = linkScan.stringByRemovingPercentEncoding;
                        } else {
                            link = nil;
                        }

                        if (!escapeScanner.isAtEnd) {
                            escapeScanner.scanLocation++;
                        }

                        break;
                    }

                    case 'T': {
                        link = nil;
                    } break;
                }
            } else if (substring != nil && substring.length > 0) {
                if (fontChanged && currentFont) {
                    currentFont = [self updateFont:currentFont pointSize:pointSize bold:boldText italic:italicText];
                    fontChanged = NO;
                }

                [substring addSegmentToString:currentFont
                                        style:style
                                        color:currentColor
                                         link:nil
                                       string:&string];
                substring = nil;
            } else {
                substring = nil;
            }
        }
    }

    return string;
}

- (NSString *)removeMarkUp {
    return [self attributedStringFromMarkUpWithFont:nil].string;
}

- (bool)hasCaseInsensitiveSubstring:(NSString *)search {
    return [self rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound;
}

- (NSString *)justNumbers {
    NSMutableString *res = [NSMutableString string];

    int i = 0;
    unichar c;

    for (i = 0; i < self.length; i++) {
        c = [self characterAtIndex:i];

        if (isnumber(c)) {
            [res appendFormat:@"%C", c];
        }
    }

    return res;
}

- (NSAttributedString *)attributedString {
    return [[NSAttributedString alloc] initWithString:self];
}

- (NSAttributedString *)attributedStringWithAttributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attrs {
    return [[NSAttributedString alloc] initWithString:self attributes:attrs];
}

- (NSString *)markedUpLinkToStopId {
    return [NSString stringWithFormat:@"Stop ID #Lid:%@ %@#T", self, self];
}

@end
