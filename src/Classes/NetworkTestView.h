//
//  NetworkTestView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 8/25/09.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TableViewControllerWithRefresh.h"


@interface NetworkTestView : TableViewControllerWithRefresh 

@property (nonatomic, copy)   NSString *diagnosticText;
@property (nonatomic, copy)   NSString *reverseGeoCodeService;
@property (nonatomic, copy)   NSString *networkErrorFromQuery;

@property bool trimetQueryStatus;
@property bool nextbusQueryStatus;
@property bool internetConnectionStatus;
@property bool reverseGeoCodeStatus;
@property bool trimetTripStatus;

- (void)fetchNetworkStatusAsync:(id<BackgroundTaskController>)task backgroundRefresh:(bool)backgroundRefresh;

@end
