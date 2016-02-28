//
//  LocatingView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/10/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TableViewWithToolbar.h"
#import "CoreLocation/CoreLocation.h"
#import <MapKit/MapKit.h>

@class LocatingView;


@protocol LocatingViewDelegate <NSObject>

- (void)locatingViewFinished:(LocatingView *)locatingView;

@end

@interface LocatingView : TableViewWithToolbar <CLLocationManagerDelegate>
{
    CLLocationManager *			_locationManager;
	UIActivityIndicatorView *	_progressInd;
	UITableViewCell *			_progressCell;
	CLLocation *				_lastLocation;
	NSDate *					_timeStamp;
	BOOL						_waitingForLocation;
	bool						_failed;
	double						_accuracy;
    bool                        _cancelled;
    
    id<LocatingViewDelegate>    _delegate;
    id<MKAnnotation>            _anotation;
}

@property (nonatomic, retain) UIActivityIndicatorView * progressInd;
@property (nonatomic, retain) UITableViewCell *         progressCell;
@property (nonatomic, retain) CLLocationManager *       locationManager;
@property (nonatomic, retain) CLLocation *              lastLocation;
@property (nonatomic, retain) NSDate *                  timeStamp;
@property (nonatomic)         bool                      failed;
@property (nonatomic)         bool                      cancelled;
@property (nonatomic)         double                    accuracy;
@property (nonatomic, retain) id<LocatingViewDelegate>  delegate;
@property (nonatomic, retain) id<MKAnnotation>          annotation;



- (UITableViewCell *)accuracyCellWithReuseIdentifier:(NSString *)identifier;
- (int)LocationTextTag;
- (void)located;
- (void)reinit;
- (void)failedToLocate;
- (bool)checkLocation;
- (void)refreshAction:(id)sender;
- (void)startLocating;
- (void)stopLocating;

@end
