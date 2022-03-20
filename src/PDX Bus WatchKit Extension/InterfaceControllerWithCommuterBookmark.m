//
//  InterfaceControllerWithCommuterBookmark.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/6/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogUserInterface

#import "InterfaceControllerWithCommuterBookmark.h"
#import "UserState.h"
#import "WatchBookmarksContext.h"
#import "WatchArrivalsContextBookmark.h"
#import "NSString+Helper.h"
#import "DebugLogging.h"
#import  "AlertInterfaceController.h"
#import <UIKit/UIKit.h>
#import "WatchNearbyInterfaceController.h"

@interface InterfaceControllerWithCommuterBookmark ()

- (bool)atRoot;
- (bool)runCommuterBookmarkOnlyOnce:(bool)onlyOnce;

@end

@implementation InterfaceControllerWithCommuterBookmark

static NSDictionary *bookmarkToDisplay;
static NSDictionary *delayedLocate;

- (void)setTitle:(NSString *)title {
    self.baseTitle = title;
    
    if (_nextScreen) {
        [super setTitle:kNextScreenTitle];
    } else {
        [super setTitle:title];
    }
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.state = UserState.sharedInstance;
    self.state.readOnly = YES;
}

- (bool)autoCommute {
    return [self runCommuterBookmarkOnlyOnce:YES];
}

- (void)forceCommute {
    if (![self runCommuterBookmarkOnlyOnce:NO]) {
        NSString *errorMsg = NSLocalizedString(@"#WNo commuter bookmark was found for the current day of the week and time.\n\n"
                                               @"#CTo create a commuter bookmark, go to the iPhone to edit a bookmark to set which days to use it for the morning or evening commute.", @"commuter bookmark error");
        
        [self pushControllerWithName:kAlertScene
                             context:[errorMsg attributedStringFromMarkUpWithFont:[UIFont systemFontOfSize:16.0]]];
    }
}

- (bool)atRoot {
    bool atRoot = NO;
    
    
    WKExtension *sharedExtention = [WKExtension sharedExtension];
    WKInterfaceController *rootInterfaceController = sharedExtention.rootInterfaceController;
    
    if ([rootInterfaceController isKindOfClass:[self class]]) {
        if (rootInterfaceController == self) {
            atRoot = YES;
        }
    }
    
    return atRoot;
}

- (void)processLocation:(NSDictionary *)location {
    bool atRoot = self.atRoot;
    
    // DEBUG_LOG(@"runCommuterBookmarkOnlyOnce:%d atRoot:%d ->\n%@\n", onlyOnce, atRoot, bookmark.description);
    
    if (location) {
        if (!atRoot) {
            if (delayedLocate) {
                delayedLocate = nil;
            }
            
            delayedLocate = location;
            
            [self popToRootController];
            DEBUG_LOG(@"runCommuterBookmarkOnlyOnce: popped\n");
        } else {
            [[WatchContext contextWithSceneName:kNearbyScene] delayedPushFrom:self completion:nil];
        }
    }
}

- (void)processBookmark:(NSDictionary *)bookmark {
    bool atRoot = self.atRoot;
    
    // DEBUG_LOG(@"runCommuterBookmarkOnlyOnce:%d atRoot:%d ->\n%@\n", onlyOnce, atRoot, bookmark.description);
    
    if (bookmark) {
        if (bookmarkToDisplay) {
            bookmarkToDisplay = nil;
        }
        
        bookmarkToDisplay = bookmark;
        
        if (!atRoot) {
            [self popToRootController];
            DEBUG_LOG(@"runCommuterBookmarkOnlyOnce: popped\n");
        } else {
            [self delayedDisplayOfCommuterBookmark];
            DEBUG_LOG(@"runCommuterBookmarkOnlyOnce: at home\n");
        }
    }
}

- (bool)runCommuterBookmarkOnlyOnce:(bool)onlyOnce {
    ExtensionDelegate *extensionDelegate = (ExtensionDelegate *)[WKExtension sharedExtension].delegate;
    
    NSDictionary *bookmark = nil;
    
    if (!extensionDelegate.backgrounded) {
        bookmark = [UserState.sharedInstance checkForCommuterBookmarkShowOnlyOnce:onlyOnce];
        
        [self processBookmark:bookmark];
    } else {
        DEBUG_LOG(@"No commuter bookmark as backgrounded\n");
    }
    
    return (bookmark != nil);
}

- (bool)delayedDisplayOfCommuterBookmark {
    if (bookmarkToDisplay != nil) {
        NSDictionary *bookmark = bookmarkToDisplay;
        bookmarkToDisplay = nil;
        
        NSString *location = bookmark[kUserFavesLocation];
        NSString *title = bookmark[kUserFavesChosenName];
        NSArray<NSString *> *stopIdArray = location.mutableArrayFromCommaSeparatedString;
        
        WatchBookmarksContext *context = [WatchBookmarksContext contextWithBookmark:stopIdArray title:title locationString:location];
        context.oneTimeShowFirst = YES;
        
        DEBUG_LOG(@"delayedDisplayOfCommuterBookmark: delayed push\n");
        _nextScreen = YES;
        self.title = self.baseTitle;
        [self delayedPush:context completion:^{
            self->_nextScreen = NO;
            self.title = self.baseTitle;
        }];
        // self.delayedPush = context;
        // [context delayedPushFrom:self];
        
        return YES;
    }
    
    return NO;
}

@end
