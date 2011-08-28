//
//  LocatingTableView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/4/09.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"
#import <CoreLocation/CoreLocation.h>


@interface LocatingTableView : TableViewWithToolbar <CLLocationManagerDelegate> {
	CLLocationManager *			_locationManager; 
	UIActivityIndicatorView *	_progressInd;
	UITableViewCell *			_progressCell;
	CLLocation *				_lastLocation;
	NSDate *					_timeStamp;
	BOOL						waitingForLocation;
	bool						failed;
	double						accuracy;
}

@property (nonatomic, retain) UIActivityIndicatorView *progressInd;
@property (nonatomic, retain) UITableViewCell *progressCell;
@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) CLLocation *lastLocation;
@property (nonatomic, retain) NSDate *timeStamp;

- (UITableViewCell *)accuracyCellWithReuseIdentifier:(NSString *)identifier;
- (int)LocationTextTag;
- (void)located;
- (NSString *)formatDistance:(double)distance;
- (void)reinit;
- (void)stopAnimating:(bool)refresh;
- (void)startAnimating:(bool)refresh;
- (void)failedToLocate;
- (bool)checkLocation;

#define kLocatingRowHeight		60.0

@end
