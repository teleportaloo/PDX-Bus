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
#import "TableViewWithToolbar.h"



@interface NetworkTestView : TableViewWithToolbar {
	bool _trimetQueryStatus;
	bool _nextbusQueryStatus;
	bool _internetConnectionStatus;
	bool _reverseGeoCodeStatus;
	bool _trimetTripStatus;
	
	NSString *_reverseGeoCodeService;
	NSString *_networkErrorFromQuery;
	
	
	NSString *_diagnosticText;
}

- (void)fetchNetworkStatusInBackground:(id<BackgroundTaskProgress>)background;

@property (nonatomic, retain) NSString *diagnosticText;
@property (nonatomic, retain) NSString *reverseGeoCodeService;
@property (nonatomic, retain) NSString *networkErrorFromQuery;

@property bool trimetQueryStatus;
@property bool nextbusQueryStatus;
@property bool internetConnectionStatus;
@property bool reverseGeoCodeStatus;
@property bool trimetTripStatus;


@end
