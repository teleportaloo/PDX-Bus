//
//  NumberPadInterfaceController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 3/20/16.
//  Copyright © 2016 Teleportaloo. All rights reserved.
//

#import "NumberPadInterfaceController.h"
#import "WatchArrivalsContext.h"
#import "StringHelper.h"
#import "DebugLogging.h"
#import "AlertInterfaceController.h"
#import "UIKit/UIKit.h"

@implementation NumberPadInterfaceController


- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.stopId = [NSMutableString string];
    [self setLabel];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (void)setLabel
{
    if (self.stopId.length == 0)
    {
        [self.buttonStopId setAttributedTitle:
         [@"#A#i<stop ID>" formatAttributedStringWithFont:[UIFont systemFontOfSize:16]]];

    }
    else
    {
        [self.buttonStopId setAttributedTitle:
         [[NSString stringWithFormat:@"#W#b%@", self.stopId]  formatAttributedStringWithFont:[UIFont systemFontOfSize:18]]];
    }
}
- (void)addDigit:(NSString *)digit
{
    [self.stopId appendString:digit];
    [self  setLabel];
}

- (IBAction)button1 {
    [self addDigit:@"1"];
}

- (IBAction)button2 {
    [self addDigit:@"2"];
}

- (IBAction)button3 {
    [self addDigit:@"3"];
}

- (IBAction)button4 {
    [self addDigit:@"4"];
}

- (IBAction)button5 {
    [self addDigit:@"5"];
}

- (IBAction)button6 {
    [self addDigit:@"6"];
}

- (IBAction)button7 {
    [self addDigit:@"7"];
}

- (IBAction)button8 {
    [self addDigit:@"8"];
}

- (IBAction)button9 {
    [self addDigit:@"9"];
}

- (IBAction)button0 {
     [self addDigit:@"0"];
}

- (IBAction)buttonBack {
    if (self.stopId.length > 0)
    {
        NSRange lastCharacter = {self.stopId.length-1, 1};
        [self.stopId deleteCharactersInRange:lastCharacter];
        [self  setLabel];
    }
}

- (IBAction)buttonGo {
    if (self.stopId.length > 0)
    {
        WatchArrivalsContext * context = [ WatchArrivalsContext contextWithLocation:self.stopId ];
        [context pushFrom:self];
    }
}

- (IBAction)menuClear {
    [self.stopId setString:@""];
    [self setLabel];
}

- (IBAction)sayStopId {
    [self presentTextInputControllerWithSuggestions:nil allowedInputMode:WKTextInputModePlain completion:^(NSArray * _Nullable results) {
        if (results != nil)
        {
            NSCharacterSet *numbers  = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
            NSCharacterSet *skippers = [NSCharacterSet characterSetWithCharactersInString:@",."];
            NSDictionary   *replacements = @{
                                             @"zero" : @"0",
                                             @"oh"   : @"0",
                                             @"one"  : @"1",
                                             @"two"  : @"2",
                                             @"three": @"3",
                                             @"four" : @"4",
                                             @"five" : @"5",
                                             @"six"  : @"6",
                                             @"seven": @"7",
                                             @"eight": @"8",
                                             @"nine" : @"9" };
            
            NSInteger stopNum = 0;
            NSMutableArray *stops = [NSMutableArray array];
            // Find the numbers in the results
            for (NSString *result in results)
            {
                NSMutableString *replacedResult = result.mutableCopy;
                
                [replacements enumerateKeysAndObjectsUsingBlock: ^void (NSString* key, NSString* replacement, BOOL *stop)
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
                while (!scanner.isAtEnd)
                {
                    segment = nil;
                    [scanner scanUpToCharactersFromSet:skippers intoString:&segment];
                    
                    if (segment!=nil)
                    {
                        [filteredResult appendString:segment];
                    }
                    
                    if (!scanner.isAtEnd)
                    {
                        scanner.scanLocation++;
                    }
                }
                
                scanner = [NSScanner scannerWithString:filteredResult];
                DEBUG_LOGS(result);
                DEBUG_LOGS(filteredResult);
                
                while (!scanner.isAtEnd)
                {
                    [scanner scanUpToCharactersFromSet:numbers intoString:nil];
                    
                    if (!scanner.isAtEnd)
                    {
                        if ([scanner scanInteger:&stopNum])
                        {
                            [stops addObject:[NSString stringWithFormat:@"%lu", (unsigned long)stopNum]];
                            DEBUG_LOGS((NSString *)stops.lastObject);
                        }
                    }
                }
            }
            
            if (stops.count >= 1)
            {
                [self.stopId setString:stops. firstObject];
                [self setLabel];
                [self buttonGo];
            }
            else
            {
                [self pushControllerWithName:kAlertScene context:
                 [@"#b#RNot sure what that was.#W Was it a stop ID?#b Saying each digit works best. This app can only do stop ID #inumbers#i right now." formatAttributedStringWithFont:[UIFont systemFontOfSize:16]]];
            }
        }
    }];
}

@end



