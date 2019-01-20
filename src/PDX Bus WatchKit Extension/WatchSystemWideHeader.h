//
//  WatchSystemWideHeader.h
//  PDX Bus WatchKit Extension
//
//  Created by Andrew Wallace on 4/27/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>
#import "WatchRow.h"

@interface WatchSystemWideHeader : WatchRow

@property (strong, nonatomic) IBOutlet WKInterfaceLabel *label;

@end
