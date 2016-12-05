//
//  DebugInterfaceController.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/31/16.
//  Copyright © 2016 Teleportaloo. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface DebugInterfaceController : WKInterfaceController
- (IBAction)ClearCommuterBookmark;
@property (strong, nonatomic) IBOutlet WKInterfaceLabel *CommuterStatus;

@end
