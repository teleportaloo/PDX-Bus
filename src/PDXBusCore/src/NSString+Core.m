//
//  NSString+Core.m
//  PDX Bus
//
//  Created by Andy Wallace on 3/9/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "DebugLogging.h"
#import "NSString+Core.h"
#import "TaskDispatch.h"

#define DEBUG_LEVEL_FOR_FILE LogUI

@implementation NSString (Core)

- (NSString *)phonetic {
    NSMutableString *ms = [NSMutableString stringWithString:self];

#define REG_WORD(X) @"\\b" X @"\\b"
#define CLEAR(X) X, @""
    static NSArray *replacements;
    DoOnce((^{
      replacements = @[
          @[ CLEAR(@"\\(Stop ID \\d+\\)") ],
          @[ REG_WORD(@"SW"), @"southwest" ],
          @[ REG_WORD(@"NW"), @"northwest" ],
          @[ REG_WORD(@"SE"), @"southeast" ],
          @[ REG_WORD(@"NE"), @"northeast" ],
          @[ REG_WORD(@"N"), @"north" ],
          @[ REG_WORD(@"S"), @"South" ],
          @[ REG_WORD(@"E"), @"east" ],
          @[ REG_WORD(@"W"), @"west" ],
          @[ REG_WORD(@"ave"), @"avenue" ],
          @[ REG_WORD(@"dr"), @"drive" ],
          @[ REG_WORD(@"st"), @"street" ],
          @[ REG_WORD(@"pkwy"), @"parkway" ],
          @[ REG_WORD(@"ln"), @"lane" ],
          @[ REG_WORD(@"ct"), @"court" ],
          @[ REG_WORD(@"stn"), @"station" ],
          @[ REG_WORD(@"TC"), @"transit center" ],
          @[ REG_WORD(@"MAX"), @"max" ],
          @[ REG_WORD(@"WES"), @"wes" ],
          @[ REG_WORD(@"TriMet"), @"trymet" ],
          @[ REG_WORD(@"Clackamas"), @"clack-a-mas" ],
          @[ REG_WORD(@"Ctr"), @"center" ],
          @[ REG_WORD(@"ID"), @" I-D " ]
      ];
    }));

    for (NSArray<NSString *> *rep in replacements) {
#define isUpper(X) ((X) >= 'A' && (X) <= 'Z')

        unichar decider = rep.lastObject.firstUnichar;
        NSRegularExpressionOptions opts =
            isUpper(decider) ? 0 : NSRegularExpressionCaseInsensitive;
        NSRegularExpression *regex =
            [NSRegularExpression regularExpressionWithPattern:rep.firstObject
                                                      options:opts
                                                        error:nil];
        [regex replaceMatchesInString:ms
                              options:0
                                range:NSMakeRange(0, ms.length)
                         withTemplate:rep.lastObject];
    }

    return ms;
}

@end
