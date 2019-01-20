//
//  LocatingView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/10/13.
//  Copyright (c) 2013 Andrew Wallace
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
	bool						_waitingForLocation;
    bool                        _triedToAuthorize;
}

@property (nonatomic, strong) UIActivityIndicatorView * progressInd;
@property (nonatomic, strong) UITableViewCell *         progressCell;
@property (nonatomic, strong) CLLocationManager *       locationManager;
@property (nonatomic, strong) CLLocation *              lastLocation;
@property (nonatomic, strong) NSDate *                  timeStamp;
@property (nonatomic)         bool                      failed;
@property (nonatomic)         bool                      cancelled;
@property (nonatomic)         double                    accuracy;
@property (nonatomic, strong) id<LocatingViewDelegate>  delegate;
@property (nonatomic, strong) id<MKAnnotation>          annotation;
@property (nonatomic, readonly) int locationTextTag;
@property (nonatomic, readonly) bool checkLocation;

- (UITableViewCell *)accuracyCellWithReuseIdentifier:(NSString *)identifier;
- (void)located;
- (void)reinit;
- (void)failedToLocate;
- (void)refreshAction:(id)sender;
- (void)startLocating;
- (void)stopLocating;
- (void)authorize;

@end
