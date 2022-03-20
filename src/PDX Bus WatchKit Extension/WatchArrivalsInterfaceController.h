//
//  WatchArrivalsInterfaceController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/16/15.
//  Copyright (c) 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "XMLDepartures.h"
#import "XMLDetours.h"
#import "WatchArrivalsContext.h"
#import "InterfaceControllerWithCommuterBookmark.h"
#import "WatchConnectivity/WatchConnectivity.h"

@interface WatchArrivalsInterfaceController : InterfaceControllerWithCommuterBookmark <TriMetXMLDelegate>

@property (strong, nonatomic) IBOutlet WKInterfaceLabel *loadingLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceButton *nextButton;
@property (strong, nonatomic) IBOutlet WKInterfaceTable *arrivalsTable;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *labelRefreshing;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *distanceLabel;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *stopDescription;
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *navGroup;
@property (strong, nonatomic) IBOutlet WKInterfaceGroup *loadingGroup;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *locateButton;


- (IBAction)swipeLeft:(id)sender;
- (IBAction)swipeDown:(id)sender;
- (IBAction)doRefreshMenuItem;
- (IBAction)menuItemNearby;
- (IBAction)menuItemCommute;
- (IBAction)nextButtonTapped;
- (IBAction)homeButtonTapped;

@end
