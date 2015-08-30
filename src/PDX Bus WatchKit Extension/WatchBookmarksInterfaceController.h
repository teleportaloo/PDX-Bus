//
//  WatchBookmarksInterfaceController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

/* INSERT_LICENSE */

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "UserFaves.h"
#import "WatchBookmarksContext.h"
#import "InterfaceControllerWithBackgroundThread.h"

@interface WatchBookmarksInterfaceController : InterfaceControllerWithBackgroundThread
{
    SafeUserData            *_faves;
    WatchBookmarksContext   *_bookmarksContext;
    NSArray                 *_displayedItems;
}
@property (strong, nonatomic) IBOutlet WKInterfaceTable *bookmarkTable;
@property (retain, nonatomic) SafeUserData *faves;
@property (retain, nonatomic) WatchBookmarksContext *bookmarksContext;
@property (retain, nonatomic) NSArray *displayedItems;
- (IBAction)menuItemHome;
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *topGroup;
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *bottomGroup;
- (IBAction)topRecentStops;
- (IBAction)topLocateStops;
- (IBAction)bottomRecentStops;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *mainTextLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *bookmarkLabel;

@end
