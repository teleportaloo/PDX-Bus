//
//  TableViewControllerWithRefresh.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/11/15.
//  Copyright © 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "PullRefreshTableViewController.h"

#define kRefreshText        NSLocalizedString(@"Refresh", @"Refresh arrivals button")

@interface TableViewControllerWithRefresh : PullRefreshTableViewController
{
    
    NSTimer *			_refreshTimer;
    NSDate *			_lastRefresh;
    bool                _timerPaused;
    UIBarButtonItem *	_refreshButton;
    UILabel *           _refreshText;

}

@property (nonatomic, retain) NSTimer *             refreshTimer;
@property (nonatomic, retain) NSDate *              lastRefresh;
@property (nonatomic, retain) UIBarButtonItem *     refreshButton;
@property (nonatomic, retain) UILabel *             refreshText;



- (void)stopTimer;
- (void)startTimer;
- (void)setRefreshButtonText:(NSString*)text;
- (void)refreshAction:(id)unused;
- (void)countDownTimer;




@end
