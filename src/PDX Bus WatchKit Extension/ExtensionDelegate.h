//
//  ExtensionDelegate.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/30/16.
//  Copyright © 2016 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <WatchKit/WatchKit.h>

@protocol ExtentionWakeDelegate <NSObject>

- (void)extentionForgrounded;

@end

@interface ExtensionDelegate : NSObject <WKExtensionDelegate>

@property(nonatomic) bool justLaunched;
@property(atomic) bool backgrounded;
@property(nonatomic, strong) id<ExtentionWakeDelegate> wakeDelegate;

@end
