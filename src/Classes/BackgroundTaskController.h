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
#import "TriMetXML.h"

#define DEBUG_PROGRESS(X, s, ...)    DEBUG_LOG(s, ##__VA_ARGS__); if (X.debugMessages) { [X taskSubtext:[NSString stringWithFormat:(s), ##__VA_ARGS__]]; }

@protocol BackgroundTaskController <TriMetXMLDelegate,NSObject>
	-(void)taskStartWithItems:(NSInteger)items title:(NSString *)title;
	-(void)taskItemsDone:(NSInteger)itemsDone;
    -(void)taskTotalItems:(NSInteger)totalItems;
	-(void)taskSubtext:(NSString *)subtext;
	-(void)taskCompleted:(UIViewController*)viewController;
    -(void)taskSetErrorMsg:(NSString *)errMsg;
    -(void)taskRunAsync:(UIViewController * (^)(void)) block;
    -(void)taskCancel;
    -(bool)taskCancelled;
    -(bool)debugMessages;
@end


