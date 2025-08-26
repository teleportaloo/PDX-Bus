//
//  WatchBookmarksInterfaceController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "WatchBookmarksInterfaceController.h"
#import "AlertInterfaceController.h"
#import "DebugLogging.h"
#import "ExtensionDelegate.h"
#import "NSString+Core.h"
#import "NumberPadInterfaceController.h"
#import "PlistMacros.h"
#import "StopNameCacheManager.h"
#import "TriMetXML.h"
#import "UserParams.h"
#import "UserState.h"
#import "WatchAppContext.h"
#import "WatchArrivalsContextBookmark.h"
#import "WatchBookmark.h"
#import "WatchNearbyInterfaceController.h"

@interface WatchBookmarksInterfaceController ()

@property(strong, nonatomic) WCSession *session;
@property(strong, nonatomic) WatchBookmarksContext *bookmarksContext;
@property(strong, nonatomic) NSArray *displayedItems;

- (IBAction)swipeDown:(id)sender;
- (IBAction)menuItemHome;
- (IBAction)enterStopId;
- (IBAction)menuItemCommute;
- (IBAction)topRecentStops;
- (IBAction)topLocateStops;
- (void)displayStopsInBookmark;

@end

@implementation WatchBookmarksInterfaceController

- (void)cacheUpdated:(id)unused {
    [self displayStopsInBookmark];
}

- (id)backgroundTask {
    // [self startBackgroundTask];
    bool updated = NO;
    StopNameCacheManager *stopNameCache = [TriMetXML getStopNameCacheManager];

    [stopNameCache getStopNames:self.bookmarksContext.singleBookmark
                  fetchAndCache:YES
                        updated:&updated
                     completion:nil];

    if (updated) {
        [self performSelectorOnMainThread:@selector(cacheUpdated:)
                               withObject:nil
                            waitUntilDone:NO];
    }

    return nil;
}

- (void)displayStopsInBookmark {
    self.title = self.bookmarksContext.title;
    self.displayedItems = self.bookmarksContext.singleBookmark;
    [self.bookmarkTable setNumberOfRows:self.displayedItems.count
                            withRowType:@"Bookmark"];

    StopNameCacheManager *stopNameCache = [TriMetXML getStopNameCacheManager];

    NSDictionary *names = [stopNameCache getStopNames:self.displayedItems
                                        fetchAndCache:NO
                                              updated:nil
                                           completion:nil];

    for (NSInteger i = 0; i < self.bookmarkTable.numberOfRows; i++) {
        WatchBookmark *row = [self.bookmarkTable rowControllerAtIndex:i];
        NSArray *stopInfo = names[self.displayedItems[i]];

        if (stopInfo) {
            [row.bookmarkName
                setText:[StopNameCacheManager getShortName:stopInfo]];
        }
    }

    self.displayedItems = self.bookmarksContext.singleBookmark;
}

- (void)taskFinishedMainThread:(id)result {
    self.title = self.bookmarksContext.title;

    // [self displayStopsInBookmark];
}

- (void)setupButtonsAndTextTopHidden:(bool)top textHidden:(bool)text {
    self.topGroup.hidden = top;
    self.mainTextLabel.hidden = text;
}

- (void)reloadData {
    if (self.bookmarksContext == nil || self.bookmarksContext.recents) {
        self.displayedItems = nil;

        // force a reload
        self.state.rawData = nil;

        if (self.bookmarksContext == nil) {
            self.title = @"PDX Bus";

            if ([WatchAppContext gotBookmarks:NO]) {
                self.displayedItems = self.state.favesArrivalsOnly;
                self.mainTextLabel.text = [NSString
                    stringWithFormat:@"Set up bookmarks on iPhone. "
                                     @"Trip Planner not supported on Watch."
                                     @"\nVersion %@.%@ #%ld",
                                     [NSBundle mainBundle].infoDictionary
                                         [@"CFBundleShortVersionString"],
                                     [NSBundle mainBundle]
                                         .infoDictionary[@"CFBundleVersion"],
                                     (long)self.state.watchSequence];
                ;
            } else {
                self.displayedItems = nil;
                self.mainTextLabel.text = [NSString
                    stringWithFormat:
                        @"Please run the iPhone app once; it will send "
                        @"bookmarks to the watch.\nVersion %@.%@ #%ld",
                        [NSBundle mainBundle]
                            .infoDictionary[@"CFBundleShortVersionString"],
                        [NSBundle mainBundle]
                            .infoDictionary[@"CFBundleVersion"],
                        (long)self.state.watchSequence];
            }

            self.menuHomeButton.hidden = YES;
            self.bookmarkLabel.hidden = NO;
            self.menuCommuteButton.horizontalAlignment =
                WKInterfaceObjectHorizontalAlignmentCenter;

            [self setupButtonsAndTextTopHidden:NO textHidden:NO];
        } else {
            self.title = @"Recents";
            self.displayedItems = self.state.recents;

            [self setupButtonsAndTextTopHidden:YES textHidden:YES];

            self.bookmarkLabel.hidden = YES;
            self.menuHomeButton.hidden = NO;
            self.menuCommuteButton.horizontalAlignment =
                WKInterfaceObjectHorizontalAlignmentRight;
        }

        if (self.displayedItems.count > 0) {
            [self.bookmarkTable setNumberOfRows:self.displayedItems.count
                                    withRowType:@"Bookmark"];

            for (NSInteger i = 0; i < self.bookmarkTable.numberOfRows; i++) {
                WatchBookmark *row =
                    [self.bookmarkTable rowControllerAtIndex:i];

                // what type is displayedItems
                NSObject *obj = self.displayedItems[i];
                NSDictionary *dict =
                    SAFE_OBJ(obj, NSDictionary, NSDictionary.dictionary);
                UserParams *item = dict.userParams;

                [row.bookmarkName setText:item.valChosenName];
            }
        } else {
            if (self.bookmarksContext == nil) {
                if ([WatchAppContext gotBookmarks:NO]) {
                    [self.bookmarkTable setNumberOfRows:1
                                            withRowType:@"No bookmarks"];
                }
            } else {
                [self.bookmarkTable setNumberOfRows:1
                                        withRowType:@"No recents"];
            }
        }
    } else if (self.bookmarksContext.singleBookmark != nil) {
        self.title = @"Loading";

        [self displayStopsInBookmark];
        [self startBackgroundTask];

        if (self.bookmarksContext.oneTimeShowFirst) {
            self.bookmarksContext.oneTimeShowFirst = NO;
            self.nextScreen = YES;
            self.title = self.baseTitle;

            [self delayedPush:[WatchArrivalsContextBookmark
                                  contextFromBookmark:self.bookmarksContext
                                                index:0]
                   completion:^{
                     self.nextScreen = NO;
                     self.title = self.baseTitle;
                   }];
        }

        [self setupButtonsAndTextTopHidden:YES textHidden:YES];

        self.bookmarkLabel.hidden = YES;
    }
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    self.state = UserState.sharedInstance;
    self.state.readOnly = YES;
    self.bookmarksContext = context;

    if ([WCSession isSupported] && (self.bookmarksContext == nil)) {
        self.session = [WCSession defaultSession];
        self.session.delegate = self;
        [self.session activateSession];

        if (self.session.applicationContext) {
            [WatchAppContext writeAppContext:self.session.applicationContext];
        }
    } else {
        [self reloadData];
    }
}

- (void)table:(WKInterfaceTable *)table
    didSelectRowAtIndex:(NSInteger)rowIndex {
    if (self.bookmarksContext == nil || self.bookmarksContext.recents) {
        if (rowIndex < self.displayedItems.count) {
            NSDictionary *selectedItem = self.displayedItems[rowIndex];
            UserParams *params = selectedItem.userParams;
            NSString *stopIds = params.valLocation;
            NSString *title = params.valChosenName;

            NSArray<NSString *> *stopIdArray =
                stopIds.mutableArrayFromCommaSeparatedString;

            if (stopIdArray.count > 1) {
                WatchBookmarksContext *context =
                    [WatchBookmarksContext contextWithBookmark:stopIdArray
                                                         title:title
                                                locationString:stopIds];

                //
                // if (self.bookmarksContext == nil)
                //{
                //    context.oneTimeShowFirst = YES;
                //}

                [context pushFrom:self];
            } else if (stopIdArray.count != 0) {
                if (self.bookmarksContext.recents) {
                    NSMutableArray *recentStops = [NSMutableArray array];

                    for (NSDictionary *item in self.displayedItems) {
                        [recentStops addObject:item.userParams.valLocation];
                    }

                    [[WatchArrivalsContextBookmark
                        contextFromRecents:[WatchBookmarksContext
                                               contextWithBookmark:recentStops
                                                             title:title
                                                    locationString:stopIds]
                                     index:rowIndex] pushFrom:self];
                } else {
                    [[WatchArrivalsContextBookmark contextWithStopId:stopIds]
                        pushFrom:self];
                }
            }
        }
    } else {
        [[WatchArrivalsContextBookmark contextFromBookmark:self.bookmarksContext
                                                     index:rowIndex]
            pushFrom:self];
    }
}

- (void)applicationDidBecomeActive {
#ifdef DEBUGLOGGING
    bool pushedCommuterBookmark =
#endif
        [self autoCommute];
    DEBUG_LOG(@"Auto-commute? %d", pushedCommuterBookmark);
}

- (void)processUserActivity {
    if ([self.userActivity.activityType
            isEqualToString:kHandoffUserActivityBookmark]) {
        [self processBookmark:self.userActivity.userInfo];
    } else if ([self.userActivity.activityType
                   isEqualToString:kHandoffUserActivityLocation]) {
        [self processLocation:self.userActivity.userInfo];
    }
}

- (void)didAppear {
    bool pushedCommuterBookmark = NO;

    UserState.sharedInstance.lastRunKey = kLastRunWatch;

    WKExtension *extension = [WKExtension sharedExtension];

    ExtensionDelegate *delegate = extension.delegate;

    // If we are the root display the bookmark
    if (self.bookmarksContext == nil) {
        pushedCommuterBookmark = [self delayedDisplayOfCommuterBookmark];
        DEBUG_LOG(@"Root - did  I push? %d", pushedCommuterBookmark);
        [WatchAppContext writeAppContext:self.session.applicationContext];
    }

    if (!pushedCommuterBookmark && delegate.justLaunched) {
        pushedCommuterBookmark = [self autoCommute];
        DEBUG_LOG(@"Auto-commute? %d", pushedCommuterBookmark);
    }

    delegate.justLaunched = NO;

    if (!pushedCommuterBookmark) {
        if (self.session && self.session.applicationContext) {
            [WatchAppContext writeAppContext:self.session.applicationContext];
        }

        [self reloadData];

        [self.bookmarksContext updateUserActivity:self];
    }

    [super didAppear];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)swipeDown:(id)sender {
    [self popToRootController];
}

- (IBAction)menuItemHome {
    [self popToRootController];
}

- (IBAction)enterStopId {
    [self pushControllerWithName:@"Number Pad" context:nil];
}

- (IBAction)menuItemCommute {
    [self forceCommute];
}

- (IBAction)topRecentStops {
    [[WatchBookmarksContext contextForRecents] pushFrom:self];
}

- (IBAction)topLocateStops {
    [self pushControllerWithName:kNearbyScene context:nil];
}

- (void)session:(WCSession *)session
    didReceiveApplicationContext:
        (NSDictionary<NSString *, id> *)applicationContext {
    [WatchAppContext writeAppContext:applicationContext];

    [self performSelectorOnMainThread:@selector(reloadData)
                           withObject:nil
                        waitUntilDone:NO];
}

- (void)extentionForgrounded {
}

- (void)session:(WCSession *)session
    activationDidCompleteWithState:(WCSessionActivationState)activationState
                             error:(nullable NSError *)error {
}

@end
