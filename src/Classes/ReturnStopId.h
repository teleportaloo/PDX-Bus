/*
 *  ReturnStopId.h
 *  PDX Bus
 *
 *  Created by Andrew Wallace on 1/25/09.
 */

 

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


@protocol ReturnStopId <NSObject>

/* if returns YES then also pop */
-(void) selectedStop:(NSString *)stopId;
@property (nonatomic, getter=getController, readonly, strong) UIViewController *controller;
@property (nonatomic, readonly, copy) NSString *actionText;

@optional
-(void) selectedStop:(NSString *)stopId desc:(NSString *)desc;

@end
