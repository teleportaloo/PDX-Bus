//
//  ExtensionDelegate.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/30/16.
//  Copyright © 2016 Teleportaloo. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@protocol ExtentionWakeDelegate <NSObject>

- (void)extentionForgrounded;

@end

@interface ExtensionDelegate : NSObject <WKExtensionDelegate>

@property (nonatomic) bool justLaunched;
@property (atomic)    bool backgrounded;
@property (nonatomic, retain) id<ExtentionWakeDelegate> wakeDelegate;

@end
