//
//  NumberPadInterfaceController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 3/20/16.
//  Copyright © 2016 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogUserInterface

#import "NumberPadInterfaceController.h"
#import "WatchArrivalsContext.h"
#import "NSString+Helper.h"
#import "DebugLogging.h"
#import "AlertInterfaceController.h"
#import "UIKit/UIKit.h"
#import "UIFont+Utility.h"

@interface NumberPadInterfaceController ()

@end

@implementation NumberPadInterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.stopId = [NSMutableString string];
    [self updateUI];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (void)updateUI {
    if (self.stopId.length == 0) {
        [self.buttonStopId setAttributedTitle:
         [@"#A#i<stop ID>" attributedStringFromMarkUpWithFont:[UIFont monospacedDigitSystemFontOfSize:16]]];
        self.goButton.hidden = YES;
        self.backButton.hidden = YES;
    } else {
        [self.buttonStopId setAttributedTitle:
         [[NSString stringWithFormat:@"#W#b%@", self.stopId] attributedStringFromMarkUpWithFont:[UIFont monospacedDigitSystemFontOfSize:18]]];
        
        self.goButton.hidden = NO;
        self.backButton.hidden = NO;
    }
}

- (void)addDigit:(NSString *)digit {
    [self.stopId appendString:digit];
    [self  updateUI];
}

- (IBAction)buttonAction1 {
    [self addDigit:@"1"];
}

- (IBAction)buttonAction2 {
    [self addDigit:@"2"];
}

- (IBAction)buttonAction3 {
    [self addDigit:@"3"];
}

- (IBAction)buttonAction4 {
    [self addDigit:@"4"];
}

- (IBAction)buttonAction5 {
    [self addDigit:@"5"];
}

- (IBAction)buttonAction6 {
    [self addDigit:@"6"];
}

- (IBAction)buttonAction7 {
    [self addDigit:@"7"];
}

- (IBAction)buttonAction8 {
    [self addDigit:@"8"];
}

- (IBAction)buttonAction9 {
    [self addDigit:@"9"];
}

- (IBAction)buttonAction0 {
    [self addDigit:@"0"];
}

- (IBAction)buttonBackAction {
    if (self.stopId.length > 0) {
        NSRange lastCharacter = { self.stopId.length - 1, 1 };
        [self.stopId deleteCharactersInRange:lastCharacter];
        [self  updateUI];
    }
}

- (IBAction)buttonGoAction {
    if (self.stopId.length > 0) {
        WatchArrivalsContext *context = [ WatchArrivalsContext contextWithStopId:self.stopId ];
        [context pushFrom:self];
    }
}

- (IBAction)menuClearAction {
    [self.stopId setString:@""];
    [self updateUI];
}

- (IBAction)sayStopIdAction {
    [self presentTextInputControllerWithSuggestions:nil allowedInputMode:WKTextInputModePlain completion:^(NSArray *_Nullable results) {
        if (results != nil) {
            NSCharacterSet *numbers  = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
            NSCharacterSet *skippers = [NSCharacterSet characterSetWithCharactersInString:@",."];
            // uncrustify-off
            NSDictionary *replacements = @{
                @"zero":    @"0",
                @"oh":      @"0",
                @"one":     @"1",
                @"two":     @"2",
                @"three":   @"3",
                @"four":    @"4",
                @"five":    @"5",
                @"six":     @"6",
                @"seven":   @"7",
                @"eight":   @"8",
                @"nine":    @"9"
            };
            // uncrustify-on
            
            NSInteger stopNum = 0;
            NSMutableArray *stops = [NSMutableArray array];
            
            // Find the numbers in the results
            for (NSString *result in results) {
                NSMutableString *replacedResult = result.mutableCopy;
                
                [replacements enumerateKeysAndObjectsUsingBlock: ^void (NSString *key, NSString *replacement, BOOL *stop)
                 {
                    [replacedResult replaceOccurrencesOfString:key
                                                    withString:replacement
                                                       options:NSCaseInsensitiveSearch
                                                         range:NSMakeRange(0, replacedResult.length)];
                }];
                
                // Skips certain characters
                NSScanner *scanner = [NSScanner scannerWithString:replacedResult];
                NSString *segment;
                NSMutableString *filteredResult = [NSMutableString string];
                
                while (!scanner.isAtEnd) {
                    segment = nil;
                    [scanner scanUpToCharactersFromSet:skippers intoString:&segment];
                    
                    if (segment != nil) {
                        [filteredResult appendString:segment];
                    }
                    
                    if (!scanner.isAtEnd) {
                        scanner.scanLocation++;
                    }
                }
                
                scanner = [NSScanner scannerWithString:filteredResult];
                DEBUG_LOGS(result);
                DEBUG_LOGS(filteredResult);
                
                while (!scanner.isAtEnd) {
                    [scanner scanUpToCharactersFromSet:numbers intoString:nil];
                    
                    if (!scanner.isAtEnd) {
                        if ([scanner scanInteger:&stopNum]) {
                            [stops addObject:[NSString stringWithFormat:@"%lu", (unsigned long)stopNum]];
                            DEBUG_LOGS((NSString *)stops.lastObject);
                        }
                    }
                }
            }
            
            if (stops.count >= 1) {
                [self.stopId setString:stops.firstObject];
                [self updateUI];
                [self buttonGoAction];
            } else {
                [self pushControllerWithName:kAlertScene context:
                 [@"#b#RNot sure what that was.#W Was it a stop ID?#b Saying each digit works best. This app can only do stop ID #inumbers#i right now." attributedStringFromMarkUpWithFont:[UIFont monospacedDigitSystemFontOfSize:16]]];
            }
        }
    }];
}

@end
