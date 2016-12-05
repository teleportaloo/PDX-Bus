//
//  BackgroundTaskContainer.h
//  PDX Bus
//
//  Created by Andrew Wallace on 2/20/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "BackgroundTaskProgress.h"
#import "ProgressModalView.h"

@protocol BackgroundTaskDone <NSObject>

- (void)BackgroundTaskDone:(UIViewController*)viewController cancelled:(bool)cancelled;
@property (nonatomic, readonly) UIInterfaceOrientation BackgroundTaskOrientation;

@optional

- (void)backgroundTaskStarted;
@property (nonatomic, readonly) bool backgroundTaskWait;

@end


@interface BackgroundTaskContainer : NSObject  <BackgroundTaskProgress,ProgressDelegate, UIAlertViewDelegate> {
	ProgressModalView *			_progressModal;
	id<BackgroundTaskDone>		_callbackComplete;
	id<BackgroundTaskProgress>	_callbackWhenFetching;
	NSThread *					_backgroundThread;
	NSString *					_title;
    NSString *                  _help;
    NSString *                  _errMsg;
    UIViewController *          _controllerToPop;
    
}

+ (BackgroundTaskContainer*) create:(id<BackgroundTaskDone>) done;
- (void)backgroundStart:(int)items title:(NSString *)title;
- (void)backgroundItemsDone:(int)itemsDone;
- (void)backgroundCompleted:(UIViewController*)viewController;
- (void)backgroundSetErrorMsg:(NSString *)errMsg;
- (void)BackgroundSetHelpText:(NSString*)helpText;

@property (nonatomic, retain)	NSString *					title;
@property (retain)				ProgressModalView *			progressModal;     // atomic for thread safety
@property (   atomic, assign)	id<BackgroundTaskDone>		callbackComplete;  // weak
@property (nonatomic, retain)	id<BackgroundTaskProgress>	callbackWhenFetching;
@property (nonatomic, retain)	NSThread *					backgroundThread;
@property (nonatomic, retain)   NSString *                  errMsg;
@property (nonatomic, retain)   UIViewController *          controllerToPop;
@property (nonatomic, retain)   NSString *                  help;


@end
