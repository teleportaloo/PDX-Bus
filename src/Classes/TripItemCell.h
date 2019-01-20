//
//  TripItemCell.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/9/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "RouteColorBlobView.h"

#define kTripItemCellId @"TripItemCellId"

@interface TripItemCell : UITableViewCell
{
    NSString *_formattedBodyText;
}
@property (strong, nonatomic) IBOutlet RouteColorBlobView *routeColorView;
@property (strong, nonatomic) IBOutlet UILabel *modeLabel;
@property (strong, nonatomic) IBOutlet UILabel *bodyLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *modeLabelWidth;
@property (nonatomic, readonly) bool large;
@property (nonatomic, copy) NSString *formattedBodyText;

- (void)update;
- (void)populateBody:(NSString *)body
                mode:(NSString *)mode
                time:(NSString *)time
           leftColor:(UIColor *)col
               route:(NSString *)route;

+ (UINib*)nib;

@end
