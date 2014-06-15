//
//  BackgroundTask.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/19/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>

@protocol BackgroundTaskProgress <NSObject>
	-(void)backgroundThread:(NSThread *)thread;
	-(void)backgroundStart:(int)items title:(NSString *)title;
	-(void)backgroundItemsDone:(int)itemsDone;
	-(void)backgroundSubtext:(NSString *)subtext;
	-(void)backgroundCompleted:(UIViewController*)viewController;
    -(void)backgroundSetErrorMsg:(NSString *)errMsg;
@end


