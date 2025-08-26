//
//  LinkInfo.m
//  PDX Bus
//
//  Created by Andy Wallace on 2/23/25.
//  Copyright © 2025 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "LinkInfo.h"
#import "PlistMacros.h"
#import "DebugLogging.h"

#define DEBUG_LEVEL_FOR_FILE LogUI

#define kLinkFull @"LinkF"
#define kLinkMobile @"LinkM"
#define kIcon @"Icon"
#define kCellText @"Title"

@interface LinkInfo ()

// Tell compiler to generate setter and getter, but setter is protected
@property(nonatomic, copy) NSString *valLinkFull;
@property(nonatomic, copy) NSString *valLinkMobile;
@property(nonatomic, copy) NSString *valLinkTitle;
@property(nonatomic, copy) NSString *valLinkIcon;

// Redeclared from parent so we can access
@property(nonatomic, retain) NSMutableDictionary *mDict;

@end

@implementation LinkInfo

// Tell compiler to use the existing parent's accessor
@dynamic mDict;

// Implementations of the setters and getters and helpers
PROP_NSString(LinkFull, kLinkFull, nil);
PROP_NSString(LinkMobile, kLinkMobile, nil);
PROP_NSString(LinkTitle, kCellText, @"");
PROP_NSString(LinkIcon, kIcon, nil);

@end

@implementation NSDictionary (LinkInfo)

- (LinkInfo *)linkInfo {
    return [LinkInfo make:self];
}

@end


