//
//  WatchArrivalDetailsInterfaceController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/17/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "WatchDepartureUI.h"
#import "InterfaceControllerWithBackgroundThread.h"

@interface WatchArrivalDetailsInterfaceController : InterfaceControllerWithBackgroundThread
{
    WatchDepartureUI *_dep;
}
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *labelScheduleInfo;
@property (nonatomic, retain) WatchDepartureUI *dep;
@property (strong, nonatomic) IBOutlet WKInterfaceMap *map;
- (IBAction)menuItemHome;
@property (strong, nonatomic) IBOutlet WKInterfaceTable *detourTable;

@end
