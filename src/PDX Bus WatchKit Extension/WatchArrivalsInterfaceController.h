//
//  WatchArrivalsInterfaceController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/16/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

/* INSERT_LICENSE */

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "XMLDepartures.h"
#import "WatchArrivalsContext.h"
#import "InterfaceControllerWithBackgroundThread.h"

@interface WatchArrivalsInterfaceController : InterfaceControllerWithBackgroundThread
{
    WatchArrivalsContext *  _arrivalsContext;
    NSTimer *               _refreshTimer;
    XMLDepartures *         _departures;
    NSInteger               _infoRow;
    bool                    _mapUpdated;
    NSDate *                _lastUpdate;
}
@property (strong, nonatomic) IBOutlet WKInterfaceTable *arrivalsTable;
@property (nonatomic, retain) WatchArrivalsContext *arrivalsContext;
@property (nonatomic, retain) NSTimer *refreshTimer;
@property (atomic, retain) NSDate *lastUpdate;
- (IBAction)doRefreshMenuItem;
- (IBAction)menuItemNearby;
@property (nonatomic, retain) XMLDepartures *departures;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *labelRefreshing;
@property (strong, nonatomic) IBOutlet WKInterfaceMap *map;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *distanceLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *stopDescription;
- (IBAction)menuItemHome;

@end
