//
//  StringHelper.m
//  PDXBusCore
//
//  Created by Andrew Wallace on 11/7/15.
//  Copyright © 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "StringHelper.h"
#import "DebugLogging.h"
#import "UIKit/UIKit.h"

@implementation StringHelper

+ (NSMutableString *)commaSeparatedStringFromEnumerator:(id<NSFastEnumeration>)container selector:(SEL)selector;
{
    NSMutableString *string = [[[NSMutableString alloc] init] autorelease];
    
    for (NSObject *obj in container)
    {
        if ([obj respondsToSelector:selector])
        {
             NSObject *item = [obj performSelector:selector];
            
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
        else
        {
            ERROR_LOG(@"commaSeparatedStringFromEnumerator - item does not respond to selector %@\n",
                      NSStringFromSelector(selector));
        }
    }
    
    return string;
}

+ (NSMutableArray *)arrayFromCommaSeparatedString:(NSString *)string
{
    NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];
    NSScanner *scanner = [NSScanner scannerWithString:string];
    NSCharacterSet *comma = [NSCharacterSet characterSetWithCharactersInString:@","];
    NSString *item;
    
    while ([scanner scanUpToCharactersFromSet:comma intoString:&item])
    {
        [array addObject:item];
        if (![scanner isAtEnd])
        {
            scanner.scanLocation++;
        }
    }
    
    return array;
}

+ (void)addSegmentToString:(UIFont *)font bold:(bool)boldText italic:(bool)italicText color:(UIColor *)color substring:(NSString *)substring string:(NSMutableAttributedString**)string
{
    UIFont *newFont = font;
    
    Class fontDesc = (NSClassFromString(@"UIFontDescriptor"));

    if ((boldText || italicText) && fontDesc !=nil)
    {
        UIFontDescriptor *fontDescriptor = font.fontDescriptor;
        // DEBUG_LOGO(fontDescriptor);
        uint32_t existingTraitsWithNewTrait = (boldText ? UIFontDescriptorTraitBold : 0 ) | (italicText ? UIFontDescriptorTraitItalic : 0);
        fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:existingTraitsWithNewTrait];
        // DEBUG_LOGO(fontDescriptor);
        UIFont *updatedFont = [UIFont fontWithDescriptor:fontDescriptor size:font.pointSize];
        newFont = updatedFont;
    }
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                color,      NSForegroundColorAttributeName,
                                newFont,    NSFontAttributeName,  nil];
    
    
    NSAttributedString  *segment =  [[NSAttributedString alloc] initWithString:substring attributes:attributes];
    [*string appendAttributedString:segment];
    [segment release];
}


// Use # as escape characters
// #b - bold text on or off
// #i - italic text on or off
// #X For colors see the items just below

+ (NSAttributedString*)formatAttributedString:(NSString*)initialString font:(UIFont *)regularFont
{
    NSMutableAttributedString *string = [NSMutableAttributedString alloc].init.autorelease;
    NSString *substring = nil;
    NSDictionary *colors = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [UIColor blackColor],    @"0",
                                    [UIColor orangeColor],   @"O",
                                    [UIColor greenColor],    @"G",
                                    [UIColor grayColor],     @"A",
                                    [UIColor redColor],      @"R",
                                    [UIColor blueColor],     @"B",
                                    [UIColor yellowColor],   @"Y", nil];

    bool boldText   = NO;
    bool italicText = NO;
    unichar c;
    UIColor *currentColor = [UIColor blackColor];
    
    NSScanner *escapeScanner = [NSScanner scannerWithString:initialString];
    
    escapeScanner.charactersToBeSkipped = nil;
    
    while (!escapeScanner.isAtEnd)
    {
        [escapeScanner scanUpToString:@"#" intoString:&substring];
        
        // DEBUG_LOGS(substring);
        
        if (!escapeScanner.isAtEnd)
        {
            escapeScanner.scanLocation++;
        }
        
        if (!escapeScanner.isAtEnd)
        {
            c = [initialString characterAtIndex:escapeScanner.scanLocation];
            escapeScanner.scanLocation++;
            
            if (c=='#')
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
                [StringHelper addSegmentToString:regularFont bold:boldText italic:italicText color:currentColor substring:substring string:&string];
                substring = nil;
            }
                
            if (c=='b')
            {
                boldText = !boldText;
            }
            else if (c=='i')
            {
                italicText = !italicText;
            }
            else if (c!='#')
            {
                NSString *colorKey = [NSString stringWithCharacters:&c length:1];
                    
                UIColor *newColor = [colors objectForKey:colorKey];
                    
                if (newColor!=nil)
                {
                    currentColor = newColor;
                }
            }
        }
        else
        {
            [StringHelper addSegmentToString:regularFont bold:boldText italic:italicText color:currentColor substring:substring string:&string];
            substring = nil;
        }
    }

    return string;
}

@end
