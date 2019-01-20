//
//  DetourUI.m
//  PDX Bus
//
//  Created by Andrew Wallace on 7/5/16.
//  Copyright © 2016 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "Detour+iOSUI.h"
#import <UIKit/UIStringDrawing.h>
#import "UserPrefs.h"
#import "StringHelper.h"

@implementation Detour (iOSUI)

+ (UILabel *)create_UITextView:(UIFont *)font
{
    CGRect frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
    
    UILabel *textView = [[UILabel alloc] initWithFrame:frame];
    textView.textColor = [UIColor blackColor];
    textView.font = font;
    textView.backgroundColor = [UIColor clearColor];
    textView.lineBreakMode =   NSLineBreakByWordWrapping;
    textView.adjustsFontSizeToFitWidth = YES;
    textView.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    textView.numberOfLines = 0;
    
    return textView;
}


- (bool)hasInfo
{
    return (self.infoLinkUrl !=nil || self.locations.count!=0 || self.extractStops.count!=0 );
}

- (NSString*)reuseIdentifer
{
    if (self.systemWideFlag)
    {
        return kSystemDetourResuseIdentifier;
    }
    
    return kDetourResuseIdentifier;
}

- (NSString *)dateString
{
    NSString *date = @"";
    if (self.beginDate)
    {
        date = [NSString stringWithFormat:@"\n#A#(Effective as of %@#)", [NSDateFormatter localizedStringFromDate:self.beginDate
                                                                                                            dateStyle:NSDateFormatterMediumStyle
                                                                                                            timeStyle:NSDateFormatterShortStyle]];
        
    }
    
    if (self.endDate)
    {
        NSString *gap = @"";
        if (date.length >0)
        {
            gap = @"\n";
        }
        
        if (date.length == 0)
        {
            date = @"\n";
        }
        date = [NSString stringWithFormat:@"%@%@#A#(Ends %@#)", date, gap, [NSDateFormatter localizedStringFromDate:self.endDate
                                                                                                      dateStyle:NSDateFormatterMediumStyle
                                                                                                      timeStyle:NSDateFormatterShortStyle]];
    }
    
    return date;
}



- (NSString *)alertColor
{
    return self.systemWideFlag ? @"#0" : @"#O";
}

- (NSString*)formattedDescriptionWithHeader
{
    NSString *header = self.formattedHeaderNewl;
    
    return [NSString stringWithFormat:@"%@%@#b%@#b%@",
            header,
            self.alertColor ,
            self.detourDesc,
            self.dateString];
}

- (NSString*)formattedDescription
{
    NSString *header = @"";
    
    if (!self.systemWideFlag)
    {
        header = self.formattedHeaderNewl;
    }
    
    return [NSString stringWithFormat:@"%@%@#b%@#b%@", header, self.systemWideFlag ? @"#0" : @"#O" ,self.detourDesc, self.dateString];
}

- (NSString *)formattedHeaderNewl
{
    if (self.headerText && self.headerText.length > 0 && ![self.headerText isEqualToString:self.detourDesc])
    {
        return [NSString stringWithFormat:@"#0#b%@#b\n", self.headerText];
    }
    return @"";
}


- (NSString *)formattedHeader
{
    if (self.headerText && self.headerText.length > 0 && ![self.headerText isEqualToString:self.detourDesc])
    {
        return [NSString stringWithFormat:@"#0#b%@#b", self.headerText];
    }
    return @"";
}

- (NSString *)formattedRoutes
{
    NSMutableString *str = [NSMutableString string];
    if (self.routes)
    {
        [str appendString:@"#0"];
        for (Route *route in self.routes)
        {
            if (!route.systemWide)
            {
                [str appendFormat:@"%@\n", route.desc];
            }
        }
    }
    return str;
}

- (NSString*)formattedDescriptionWithoutInfo
{
    return [NSString stringWithFormat:@"%@%@%@#b%@#b%@#(#A (ID %d) #)",
                self.formattedRoutes,
                self.formattedHeaderNewl,
                self.alertColor,
                self.detourDesc,
                self.dateString,
                ABS(self.detourId.intValue)];
}

- (void)populateCell:(UITableViewCell *)cell font:(UIFont*)font routeDisclosure:(bool)routeDisclosure
{

    if (self.systemWideFlag && [UserPrefs sharedInstance].hideSystemWideDetours)
    {
        cell.textLabel.attributedText = [self.formattedHeader formatAttributedStringWithFont:font];
    }
    else
    {
        cell.textLabel.attributedText = [self.formattedDescription formatAttributedStringWithFont:font];
    }

    // cell.view.attributedText = [detour.detourDesc formatAttributedStringWithFont:self.paragraphFont];
    cell.textLabel.accessibilityLabel = self.formattedDescription.removeFormatting.phonetic;
    
    if (!self.systemWideFlag && routeDisclosure)
    {
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else
    {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

}
@end
