//
//  WhatsNewBasicAction.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/14.
//  Copyright (c) 2014 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WhatsNewViewController.h"
#import <Foundation/Foundation.h>

@interface WhatsNewBasicAction : NSObject <WhatsNewSpecialAction>

- (NSString *)prefix:(NSString *)item restOfText:(NSString **)rest;
- (NSString *)plainTextIndented:(NSString *)fullText;
- (NSString *)plainTextNormal:(NSString *)fullText;

+ (instancetype)action;
+ (bool)matches:(NSString *)string;
+ (void)addAction;

@end
