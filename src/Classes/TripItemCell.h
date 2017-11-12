//
//  TripItemCell.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/9/17.
//  Copyright © 2017 Teleportaloo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RouteColorBlobView.h"

#define kTripItemCellId @"TripItemCellId"

@interface TripItemCell : UITableViewCell
{
    NSString *_formattedBodyText;
}
@property (retain, nonatomic) IBOutlet RouteColorBlobView *routeColorView;
@property (retain, nonatomic) IBOutlet UILabel *modeLabel;
@property (retain, nonatomic) IBOutlet UILabel *bodyLabel;
@property (retain, nonatomic) IBOutlet NSLayoutConstraint *modeLabelWidth;

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
