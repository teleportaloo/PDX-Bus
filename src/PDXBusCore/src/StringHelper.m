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


#import "StringHelper.h"
#import "DebugLogging.h"
#import "PDXBusCore.h"

@implementation NSString(StringHelper)

- (unichar)firstUnichar
{
    if (self.length>0)
    {
        // This used to be called firsCharacter but when that is called it fails after creating a UIDocumentInteractionController.  Super weird.
        return [self characterAtIndex:0];
    }
    return 0;
}

- (NSMutableAttributedString *)mutableAttributedString
{
   return [[NSMutableAttributedString alloc] initWithString:self];
}

- (NSString *)stringWithTrailingSpacesRemoved
{
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSInteger i = 0;
    
    for (i = self.length-1 ; i>0; i--)
    {
        if (![whitespace characterIsMember:[self characterAtIndex:i]])
        {
            break;
        }
    }
    
    return [self substringToIndex:i+1];
}

- (NSString *)stringWithLeadingSpacesRemoved
{
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSInteger i = 0;
    
    for (i = 0 ; i< self.length; i++)
    {
        if (![whitespace characterIsMember:[self characterAtIndex:i]])
        {
            break;
        }
    }
    
    return [self substringFromIndex:i];
}

- (NSString *)stringWithTrailingSpaceIfNeeded
{
    if (self.length == 0)
    {
        return self;
    }
    return [self stringByAppendingString:@" "];
}

- (NSString *)phonetic
{
    NSMutableString *ms = [NSMutableString stringWithString:self];
    
#define REG_WORD(X) @"\\b" X @"\\b"
#define CLEAR(X) X , @""
    static NSArray *replacements;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        replacements = @[
                          @[ CLEAR(@"\\(Stop ID \\d+\\)") ],
                          @[ REG_WORD(@"SW")    , @"southwest"],
                          @[ REG_WORD(@"NW")    , @"northwest"],
                          @[ REG_WORD(@"SE")    , @"southeast"],
                          @[ REG_WORD(@"NE")    , @"northeast"],
                          @[ REG_WORD(@"N")     , @"north"],
                          @[ REG_WORD(@"S")     , @"South"],
                          @[ REG_WORD(@"E")     , @"east"],
                          @[ REG_WORD(@"W")     , @"west"],
                          @[ REG_WORD(@"ave")   , @"avenue"],
                          @[ REG_WORD(@"dr")    , @"drive"],
                          @[ REG_WORD(@"st")    , @"street"],
                          @[ REG_WORD(@"pkwy")  , @"parkway"],
                          @[ REG_WORD(@"ln")    , @"lane"],
                          @[ REG_WORD(@"ct")    , @"court"],
                          @[ REG_WORD(@"stn")   , @"station"],
                          @[ REG_WORD(@"TC")    , @"transit center"],
                          @[ REG_WORD(@"MAX")   , @"max"],
                          @[ REG_WORD(@"WES")   , @"wes"],
                          @[ REG_WORD(@"TriMet"), @"trymet"],
                          @[ REG_WORD(@"Clackamas"), @"clack-a-mas"],
                          @[ REG_WORD(@"Ctr"),    @"center"],
                          @[ REG_WORD(@"ID")    , @" I-D " ]
                        ];
    });
    
    
    for (NSArray<NSString*> *rep in replacements)
    {
#define isUpper(X) ((X)>='A' && (X)<='Z')
         
         unichar decider = rep.lastObject.firstUnichar;
         NSRegularExpressionOptions opts = isUpper(decider) ? 0 : NSRegularExpressionCaseInsensitive;
         NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:rep.firstObject
                                                                                options:opts
                                                                                  error:nil];
         [regex replaceMatchesInString:ms options:0
                                 range:NSMakeRange(0, ms.length)
                          withTemplate:rep.lastObject];
    };
    
    return ms;
}

+ (NSMutableString *)commaSeparatedStringFromEnumerator:(id<NSFastEnumeration>)container selector:(SEL)selector;
{
    NSMutableString *string = [NSMutableString string];
    
    for (NSObject *obj in container)
    {
        if ([obj respondsToSelector:selector])
        {
            IMP imp = [obj methodForSelector:selector];
            NSObject * (*func)(id, SEL) = (void *)imp;

            NSObject *item = func(obj, selector);
            
            // NSObject *item = [obj performSelector:selector];
            if (item!=nil)
            {
                if ([item isKindOfClass:[NSString class]])
                {
                    if (string.length>0)
                    {
                        [string appendString:@","];
                    }
                    [string appendString:(NSString*)item];
                }
                else
                {
                    ERROR_LOG(@"commaSeparatedStringFromEnumerator - selector did not return string %@\n",
                              NSStringFromSelector(selector));
                }
            }
        }
        else
        {
            ERROR_LOG(@"commaSeparatedStringFromEnumerator - item does not respond to selector %@\n",
                      NSStringFromSelector(selector));
        }
    }
    
    return string;
}

- (NSMutableArray<NSString*> *)arrayFromCommaSeparatedString
{
    NSCharacterSet *comma = [NSCharacterSet characterSetWithCharactersInString:@","];
    NSMutableArray<NSString*> *array = [NSMutableArray array];
    NSScanner *scanner  = [NSScanner scannerWithString:self];
    NSString *item;
    
    while ([scanner scanUpToCharactersFromSet:comma intoString:&item])
    {
        [array addObject:item];
        if (!scanner.atEnd)
        {
            scanner.scanLocation++;
        }
    }
    
    return array;
}

+ (void)addSegmentToString:(UIFont *)font pointSize:(CGFloat)pointSize style:(NSParagraphStyle*)style bold:(bool)boldText italic:(bool)italicText color:(UIColor *)color substring:(NSString *)substring string:(NSMutableAttributedString**)string
{
    // DEBUG_LOGS(substring);
    if (font == nil)
    {
        NSAttributedString  *segment =  [[NSAttributedString alloc] initWithString:substring];
        [*string appendAttributedString:segment];
        return;
    }

    if ((boldText || italicText || pointSize!=font.pointSize))
    {
        UIFontDescriptor *fontDescriptor = font.fontDescriptor;
        uint32_t traits = (boldText ? UIFontDescriptorTraitBold : 0 ) | (italicText ? UIFontDescriptorTraitItalic : 0);
        fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:traits];
        font = [UIFont fontWithDescriptor:fontDescriptor size:pointSize];
    }
    
    NSAttributedString  *segment = nil;
    
    if (style)
    {
        segment =  [[NSAttributedString alloc] initWithString:substring attributes:@{NSForegroundColorAttributeName :color,
                                                                                     NSFontAttributeName            :font,
                                                                                     NSParagraphStyleAttributeName  :style
                                                                                     }];
    }
    else
    {
  
        
        segment =  [[NSAttributedString alloc] initWithString:substring attributes:@{NSForegroundColorAttributeName :color,
                                                                                     NSFontAttributeName            :font}];
    }
        
    [*string appendAttributedString:segment];
}

- (NSMutableParagraphStyle *)indentStyle:(NSMutableParagraphStyle *)style size:(CGFloat)size
{
    if (style == nil)
    {
        style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    }
    
    CGFloat indentation = style.headIndent + size;
    
    style.headIndent = indentation;
    style.firstLineHeadIndent = indentation;
    
    return style;
}

// See header for formatting markup
- (NSMutableAttributedString*)formatAttributedStringWithFont:(UIFont *)regularFont
{
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    NSScanner *escapeScanner = [NSScanner scannerWithString:self];
    CGFloat pointSize = regularFont ? regularFont.pointSize : 10;
    UIColor *currentColor = [UIColor blackColor];
    NSString *substring = nil;
    bool italicText = NO;
    bool boldText = NO;
    NSMutableParagraphStyle *style = nil;
    unichar c;
    
    escapeScanner.charactersToBeSkipped = nil;
    
    while (!escapeScanner.isAtEnd)
    {
        @autoreleasepool {
            
            [escapeScanner scanUpToString:@"#" intoString:&substring];
            
            // DEBUG_LOGS(substring);
            
            if (!escapeScanner.isAtEnd)
            {
                escapeScanner.scanLocation++;
            }
            
            if (!escapeScanner.isAtEnd)
            {
                c = [self characterAtIndex:escapeScanner.scanLocation];
                escapeScanner.scanLocation++;
                
                if (c=='h')
                {
                    if (substring)
                    {
                        substring = [substring stringByAppendingString:@"#"];
                    }
                    else
                    {
                        substring = @"#";
                    }
                }
                
                if (substring && substring.length > 0)
                {
                    [NSString addSegmentToString:regularFont pointSize:pointSize style:style bold:boldText italic:italicText color:currentColor substring:substring string:&string];
                    substring = nil;
                }
                
                switch (c)
                {
                    default: break;
                    case 'h': break;
                    case 'b': boldText   = !boldText;    break;
                    case 'i': italicText = !italicText;  break;
                    case '-': if (pointSize>1.0) { pointSize--; } break;
                    case '(': if (pointSize>2.0) { pointSize-=2; } break;
                    case '[': if (pointSize>4.0) { pointSize-=4; } break;
                    case '+': pointSize++; break;
                    case ')': pointSize+=2; break;
                    case ']': pointSize+=4; break;
                    case '0': currentColor = [UIColor blackColor];  break;
                    case 'O': currentColor = [UIColor orangeColor]; break;
                    case 'G': currentColor = [UIColor greenColor];  break;
                    case 'A': currentColor = [UIColor grayColor];   break;
                    case 'R': currentColor = [UIColor redColor];    break;
                    case 'B': currentColor = [UIColor blueColor];   break;
                    case 'Y': currentColor = [UIColor yellowColor]; break;
                    case 'N': currentColor = [UIColor brownColor];  break;
                    case 'M': currentColor = [UIColor magentaColor];break;
                    case 'W': currentColor = [UIColor whiteColor];  break;
                    case '>': style = [self indentStyle:style size:pointSize]; break;
                    case '<': style = [self indentStyle:style size:-pointSize]; break;
                }
            }
            else
            {
                [NSString addSegmentToString:regularFont pointSize:pointSize style:style bold:boldText italic:italicText color:currentColor substring:substring string:&string];
                substring = nil;
            }
        }
    }
    
    return string;
}


- (NSString*)removeFormatting
{
    return [self formatAttributedStringWithFont:nil].string;
}

- (NSMutableAttributedString *)appendToAttributedString:(NSMutableAttributedString *)attr;
{
    if (attr.length > 0)
    {
        NSDictionary *formatting = [attr attributesAtIndex:attr.length-1 effectiveRange:nil];
        
        if (formatting)
        {
            [attr appendAttributedString:[[NSAttributedString alloc] initWithString:self attributes:formatting]];
        }
        else
        {
            [attr appendAttributedString:[[NSAttributedString alloc] initWithString:self]];
        }
    }
    else
    {
        [attr appendAttributedString:[[NSAttributedString alloc] initWithString:self]];
    }
    return attr;
}

- (bool)hasCaseInsensitiveSubstring:(NSString *)search
{
    return [self rangeOfString:search options:NSCaseInsensitiveSearch].location != NSNotFound;
}


- (NSString *)justNumbers
{
    NSMutableString *res = [NSMutableString string];
    
    int i=0;
    unichar c;
    
    for (i=0; i< self.length; i++)
    {
        c = [self characterAtIndex:i];
        
        if (isnumber(c))
        {
            [res appendFormat:@"%C", c];
        }
    }
    
    return res;
}

@end
