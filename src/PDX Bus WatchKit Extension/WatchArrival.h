//
//  WatchArrival.h
//  PDX Bus
//
//  Created by Andrew Wallace on 5/16/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

/* INSERT_LICENSE */

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "DepartureData.h"
#import "WatchDepartureUI.h"

@interface WatchArrival: NSObject
@property (strong, nonatomic) IBOutlet WKInterfaceImage *lineColor;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *heading;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *mins;
@property (strong, nonatomic) IBOutlet WKInterfaceImage *blockColor;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *exception;

-(void)displayDepature:(WatchDepartureUI *)dep;

@end
