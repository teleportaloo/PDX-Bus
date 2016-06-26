//
//  WatchBookmarksInterfaceController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WatchBookmarksInterfaceController.h"
#import "UserFaves.h"
#import "WatchBookmark.h"
#import "TriMetXML.h"
#import "StopNameCacheManager.h"
#import "WatchArrivalsContextBookmark.h"
#import "StringHelper.h"
#import "DebugLogging.h"
#import "WatchNearbyInterfaceController.h"
#import "NumberPadInterfaceController.h"
#import "AlertInterfaceController.h"


@interface WatchBookmarksInterfaceController()

@end


@implementation WatchBookmarksInterfaceController


@synthesize bookmarksContext    = _bookmarksContext;
@synthesize displayedItems      = _displayedItems;


- (void)dealloc
{
    self.bookmarksContext   = nil;
    self.displayedItems     = nil;
    [super dealloc];
}

- (id)backgroundTask
{
    [self startBackgroundTask];
    StopNameCacheManager *stopNameCache = [TriMetXML getStopNameCacheManager];
    for (NSInteger i = 0; i < self.bookmarksContext.singleBookmark.count; i++) {
        
        [stopNameCache getStopNameAndCache:[self.bookmarksContext.singleBookmark objectAtIndex:i]];
    }
    return nil;
}

- (void)taskFinishedMainThread:(id)arg
{
    self.title = self.bookmarksContext.title;
    self.displayedItems = self.bookmarksContext.singleBookmark;
    
    StopNameCacheManager *stopNameCache = [TriMetXML getStopNameCacheManager];
    
    [self.bookmarkTable setNumberOfRows:self.displayedItems.count withRowType:@"Bookmark"];
    
    for (NSInteger i = 0; i < self.bookmarkTable.numberOfRows; i++) {
        
        WatchBookmark *row = [self.bookmarkTable rowControllerAtIndex:i];
        NSArray *stopName = [stopNameCache getStopNameAndCache:[self.displayedItems objectAtIndex:i]];
        
        [row.bookmarkName setText:[stopName objectAtIndex:kStopNameCacheShortDescription]];
    }
    
    if (self.bookmarksContext.oneTimeShowFirst)
    {
        self.bookmarksContext.oneTimeShowFirst = NO;
        
        [[WatchArrivalsContextBookmark contextFromBookmark:self.bookmarksContext index:0] delayedPushFrom:self];
    }
}

- (void)setupButtonsAndTextTopHidden:(bool)top bottomHidden:(bool)bottom textHidden:(bool)text
{
    self.topGroup.hidden        = top;
    self.bottomGroup.hidden     = bottom;
    self.mainTextLabel.hidden   = text;
}

- (void)reloadData
{
    if (self.bookmarksContext == nil || self.bookmarksContext.recents)
    {
        self.displayedItems = nil;
        
        // force a reload
        self.faves.appData = nil;
        
        if (self.bookmarksContext == nil)
        {
            self.title = @"PDX Bus";
            self.displayedItems = self.faves.favesArrivalsOnly;
            self.bookmarkLabel.hidden = NO;
            
            if ([UserPrefs getSingleton].watchBookmarksAtTheTop)
            {
                [self setupButtonsAndTextTopHidden:YES bottomHidden:NO textHidden:NO];
            }
            else
            {
                [self setupButtonsAndTextTopHidden:NO bottomHidden:YES textHidden:NO];
            }
            
        } else {
            self.title =  @"Recents";
            self.displayedItems = self.faves.recents;
            
            [self setupButtonsAndTextTopHidden:YES bottomHidden:YES textHidden:YES];
            
             self.bookmarkLabel.hidden = YES;
        }
        
        if (self.displayedItems.count > 0)
        {
            [self.bookmarkTable setNumberOfRows:self.displayedItems.count withRowType:@"Bookmark"];
            
            for (NSInteger i = 0; i < self.bookmarkTable.numberOfRows; i++) {
                
                WatchBookmark *row = [self.bookmarkTable rowControllerAtIndex:i];
                
                NSDictionary *item = (NSDictionary *)[self.displayedItems objectAtIndex:i];
                
                [row.bookmarkName setText:[item valueForKey:kUserFavesChosenName]];
            }
        }
        else
        {
            if (self.bookmarksContext == nil)
            {
                [self.bookmarkTable setNumberOfRows:1 withRowType:@"No bookmarks"];
            }
            else
            {
                [self.bookmarkTable setNumberOfRows:1 withRowType:@"No recents"];
            }
        }
    }
    else if (self.bookmarksContext.singleBookmark !=nil)
    {
        self.title = @"Loading";
        [self startBackgroundTask];
        
        [self setupButtonsAndTextTopHidden:YES bottomHidden:YES textHidden:YES];
        
        self.bookmarkLabel.hidden = YES;
    }
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    self.faves = [SafeUserData getSingleton];
    self.faves.readOnly = YES;
    self.bookmarksContext = context;
    
    [UserPrefs useWatchSettings];
    
    [self reloadData];
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex
{
    if (self.bookmarksContext == nil || self.bookmarksContext.recents)
    {
        if (rowIndex < self.displayedItems.count)
        {
            NSDictionary *selectedItem = [self.displayedItems objectAtIndex:rowIndex];
            NSString *location = [selectedItem valueForKey:kUserFavesLocation];
            NSString *title    = [selectedItem valueForKey:kUserFavesChosenName];
        
            NSArray *stops = [StringHelper arrayFromCommaSeparatedString:location];

            
            if (stops.count > 1)
            {
                WatchBookmarksContext * context = [WatchBookmarksContext contextWithBookmark:stops title:title locationString:location];
                
                if (![UserPrefs getSingleton].watchBookmarksDisplayStopList && self.bookmarksContext == nil)
                {
                    context.oneTimeShowFirst = YES;
                }
                
                [context pushFrom:self];
                
            }
            else if (stops.count !=0)
            {
                if (self.bookmarksContext.recents)
                {
                    NSMutableArray *recentStops = [[[NSMutableArray alloc] init] autorelease];
                    
                    for (NSDictionary *item in self.displayedItems)
                    {
                        [recentStops addObject:[item valueForKey:kUserFavesLocation]];
                    }
                    
                    [[WatchArrivalsContextBookmark contextFromRecents:
                      [WatchBookmarksContext contextWithBookmark:recentStops
                                                           title:title
                                                  locationString:location] index:rowIndex] pushFrom:self];
                    

                }
                else
                {
                    [[WatchArrivalsContextBookmark contextWithLocation:location] pushFrom:self];
                }
            }
        }
    }
    else
    {
        [[WatchArrivalsContextBookmark contextFromBookmark:self.bookmarksContext index:rowIndex] pushFrom:self];
    }
    
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    
    bool pushedCommuterBookmark = NO;
    [SafeUserData getSingleton].lastRunKey = kLastRunWatch;
    
    
    // If we are the root display the bookmark
    if (self.bookmarksContext == nil )
    {
        pushedCommuterBookmark = [self maybeDisplayCommuterBookmark];
        DEBUG_LOG(@"Root - did  I push? %d", pushedCommuterBookmark);
    }
    
    if (!pushedCommuterBookmark)
    {
        pushedCommuterBookmark = [self autoCommuteAlreadyHome:(self.bookmarksContext == nil) ];
        DEBUG_LOG(@"Auto-commute? %d", pushedCommuterBookmark);
    }
    
    if (!pushedCommuterBookmark)
    {
        [self reloadData];
        
        [self.bookmarksContext updateUserActivity:self];
    }
    
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)menuItemHome {
    [self popToRootController];
}

- (IBAction)enterStopId {
    [self pushControllerWithName:@"Number Pad" context:nil];
}

- (IBAction)menuItemCommute {
    [self forceCommuteAlreadyHome:(self.bookmarksContext == nil)];
}
- (IBAction)topRecentStops {
    [[WatchBookmarksContext contextForRecents] pushFrom:self];
}

- (IBAction)topLocateStops {
    [self pushControllerWithName:kNearbyScene context:nil];
}

- (IBAction)bottomRecentStops {
    [[WatchBookmarksContext contextForRecents] pushFrom:self];
}

- (IBAction)bottomLocateStops {
    [self pushControllerWithName:kNearbyScene context:nil];
}


@end



