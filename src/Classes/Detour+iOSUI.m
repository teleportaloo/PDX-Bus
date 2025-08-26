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
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"
#import "Settings.h"
#import "UIColor+MoreDarkMode.h"
#import <UIKit/UIStringDrawing.h>

@implementation Detour (iOSUI)

+ (UILabel *)create_UITextView:(UIFont *)font {
    CGRect frame = CGRectMake(0.0, 0.0, 100.0, 100.0);

    UILabel *textView = [[UILabel alloc] initWithFrame:frame];

    textView.textColor = [UIColor modeAwareText];
    textView.font = font;
    textView.backgroundColor = [UIColor clearColor];
    textView.lineBreakMode = NSLineBreakByWordWrapping;
    textView.adjustsFontSizeToFitWidth = YES;
    textView.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    textView.numberOfLines = 0;

    return textView;
}

- (bool)hasInfo {
    return (self.infoLinkUrl != nil || self.locations.count != 0 ||
            self.extractStops.count != 0);
}

- (NSString *)reuseIdentifer {
    if (self.systemWide) {
        return kSystemDetourResuseIdentifier;
    }

    return kDetourResuseIdentifier;
}

- (NSString *)dateString {
    NSString *date = @"";

    if (self.beginDate) {
        date = [NSString
            stringWithFormat:
                @"\n#A#(Effective as of %@#)",
                [NSDateFormatter
                    localizedStringFromDate:self.beginDate
                                  dateStyle:NSDateFormatterMediumStyle
                                  timeStyle:NSDateFormatterShortStyle]];
    }

    if (self.endDate) {
        NSString *gap = @"";

        if (date.length > 0) {
            gap = @"\n";
        }

        if (date.length == 0) {
            date = @"\n";
        }

        date = [NSString
            stringWithFormat:
                @"%@%@#A#(Ends %@#)", date, gap,
                [NSDateFormatter
                    localizedStringFromDate:self.endDate
                                  dateStyle:NSDateFormatterMediumStyle
                                  timeStyle:NSDateFormatterShortStyle]];
    }

    if (Settings.showDetourIds) {
        date = [NSString
            stringWithFormat:@"%@\n#A#(%@ID:%ld#)", date,
                             DETOUR_TYPE_FROM_ID(self.detourId),
                             (long)DETOUR_ID_STRIP_TAG(self.detourId)];
    }

    return date;
}

- (NSString *)alertColor {
    return self.systemWide ? @"#!" : @"#O";
}

- (NSString *)headerColor {
    return self.systemWide ? @"#!" : @"#O";
}

- (NSString *)markedUpDescriptionWithHeader:(NSString *)additionalText {
    NSString *header = self.markedUpHeaderNewl;

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@", self.headerColor,
                                      header, self.alertColor, self.detectStops,
                                      self.markedUpLink,
                                      additionalText ? additionalText : @"",
                                      self.dateString];
}

- (NSString *)markedUpLink {
    NSMutableString *url = [NSMutableString string];

    if (self.infoLinkUrl) {
        [url appendFormat:@" #L%@ More#T", self.infoLinkUrl.percentEncodeUrl];
    }

    if ((self.locations.count != 0 || self.extractStops.count != 0)) {
        [url appendFormat:@"\n#Ldetourmap: See map#T"];
    }

    return url;
}

- (NSString *)markedUpNoMap {
    NSMutableString *url = [NSMutableString string];

    if (self.infoLinkUrl) {
        [url appendFormat:@" #L%@ More#T", self.infoLinkUrl.percentEncodeUrl];
    }

    return url;
}

- (NSString *)markedUpDescription:(NSString *)additionalText {
    NSString *header = @"";

    if (!self.systemWide) {
        header = self.markedUpHeaderNewl;
    }

    return [NSString stringWithFormat:@"%@%@%@%@%@%@", header,
                                      self.systemWide ? @"#!" : @"#O",
                                      self.detectStops, self.markedUpLink,
                                      additionalText ? additionalText : @"",
                                      self.dateString];
}

- (NSString *)markedUpHeaderNewl {
    if (self.headerText && self.headerText.length > 0 &&
        ![self.headerText isEqualToString:self.detourDesc]) {
        return [NSString stringWithFormat:@"%@#b%@#b\n", self.headerColor,
                                          self.headerText.safeEscapeForMarkUp];
    }

    return @"";
}

- (NSString *)markedUpHeader {
    if (self.headerText && self.headerText.length > 0 &&
        ![self.headerText isEqualToString:self.detourDesc]) {
        return [NSString stringWithFormat:@"%@#b%@#b", self.headerColor,
                                          self.headerText.safeEscapeForMarkUp];
    }

    return @"";
}

- (NSString *)markedUpRoutes {
    NSMutableString *str = [NSMutableString string];

    if (self.routes) {
        [str appendString:@"#D"];

        for (Route *route in self.routes) {
            if (!route.systemWide) {
                [str appendFormat:@"%@\n", route.desc.safeEscapeForMarkUp];
            }
        }
    }

    return str;
}

- (NSString *)markedUpDescriptionWithoutInfo:(NSString *)additionalText {
    return [NSString
        stringWithFormat:@"%@%@%@%@%@%@%@#(#A (ID %d) #)", self.markedUpRoutes,
                         self.markedUpHeaderNewl, self.alertColor,
                         self.detectStops, self.markedUpNoMap,
                         additionalText ? additionalText : @"", self.dateString,
                         ABS(self.detourId.intValue)];
}

@end
