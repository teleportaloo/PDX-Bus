//
//  WatchArrivalsInterfaceController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/16/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "XMLDepartures.h"
#import "WatchArrivalsContext.h"
#import "InterfaceControllerWithCommuterBookmark.h"

@interface WatchArrivalsInterfaceController : InterfaceControllerWithCommuterBookmark
{
    WatchArrivalsContext *  _arrivalsContext;
    NSTimer *               _refreshTimer;
    XMLDepartures *         _departures;
    NSInteger               _arrivalsStartRow;
    bool                    _mapUpdated;
    NSDate *                _lastUpdate;
}

@property (strong, nonatomic) IBOutlet WKInterfaceButton *nextButton;
@property (strong, nonatomic) IBOutlet WKInterfaceTable *arrivalsTable;
@property (nonatomic, retain) WatchArrivalsContext *arrivalsContext;
@property (nonatomic, retain) NSTimer *refreshTimer;
@property (atomic, retain) NSDate *lastUpdate;
- (IBAction)doRefreshMenuItem;
- (IBAction)menuItemNearby;
- (IBAction)menuItemCommute;
@property (nonatomic, retain) XMLDepartures *departures;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *labelRefreshing;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *distanceLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *stopDescription;
- (IBAction)menuItemHome;
- (IBAction)nextButtonTapped;
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *navGroup;
@property (nonatomic, retain) DepartureData *detailDeparture;
@property (nonatomic, retain) NSString *detailStreetcarId;

@end
