//
//  AlertViewCancelsTask.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/21/11.
//  Copyright (c) 2011 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "BackgroundTaskContainer.h"

@interface AlertViewCancelsTask : NSObject<UIAlertViewDelegate>
{
    BackgroundTaskContainer *_backgroundTask;
    UIViewController        *_caller;
}

@property (nonatomic, retain) BackgroundTaskContainer *backgroundTask;
@property (nonatomic, retain) UIViewController *caller;

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;


@end
