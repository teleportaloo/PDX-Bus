//
//  WatchBookmarksInterfaceController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

/* INSERT_LICENSE */

#import "WatchBookmarksInterfaceController.h"
#import "UserFaves.h"
#import "WatchBookmark.h"
#import "TriMetXML.h"
#import "StopNameCacheManager.h"
#import "WatchArrivalsContext.h"


@interface WatchBookmarksInterfaceController()

@end


@implementation WatchBookmarksInterfaceController

@synthesize faves               = _faves;
@synthesize bookmarksContext    = _bookmarksContext;
@synthesize displayedItems      = _displayedItems;

- (void)dealloc
{
    self.faves              = nil;
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
        
            NSArray *stops = [self.faves arrayFromCommaSeparatedString:location];
        
            if (stops.count > 1)
            {
                [self pushControllerWithName:@"Bookmarks" context:[WatchBookmarksContext contextWithBookmark:stops title:title]];
            }
            else
            {
                [self pushControllerWithName:@"Arrivals" context:[WatchArrivalsContext contextWithLocation:location]];
            }
        }
    }
    else
    {
        [self pushControllerWithName:@"Arrivals" context:[WatchArrivalsContext contextWithLocation:[self.displayedItems objectAtIndex:rowIndex]]];
    }
    
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [self reloadData];
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

- (IBAction)menuItemHome {
    [self popToRootController];
}
- (IBAction)topRecentStops {
    [self pushControllerWithName:@"Bookmarks" context:[WatchBookmarksContext contextForRecents]];
}

- (IBAction)topLocateStops {
    [self pushControllerWithName:@"Nearby" context:nil];
}

- (IBAction)bottomRecentStops {
    [self pushControllerWithName:@"Bookmarks" context:[WatchBookmarksContext contextForRecents]];
}

- (IBAction)bottomLocateStops {
    [self pushControllerWithName:@"Nearby" context:nil];
}


@end



