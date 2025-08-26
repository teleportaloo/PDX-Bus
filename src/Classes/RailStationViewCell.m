//
//  RailStationViewCell.m
//  PDX Bus
//
//  Created by Andy Wallace on 10/12/24.
//  Copyright © 2024 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RailStationViewCell.h"
#import "NSString+Core.h"
#import "NSString+MoreMarkup.h"
#import "RailStation.h"
#import "RouteColorBlobView.h"
#import "StationData.h"

@interface RailStationViewCell () {
}

@property(nonatomic) CGFloat rightMargin;
@property(nonatomic) CGFloat fixedMargin;
@property(nonatomic, weak) NSLayoutConstraint *widthContraint;

@end

@implementation RailStationViewCell

#define MAX_TAG 2
#define MAX_LINES 4
#define LABEL_TAG 1000
#define LINES_TAG 2000
#define MAX_LINE_SIDE ROUTE_COLOR_WIDTH
#define MAX_LINE_GAP 0

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)configWithRowHeight:(CGFloat)height
                rightMargin:(bool)rightMargin
                fixedMargin:(CGFloat)fixedMargin {
    UIView *maxColors = [[UIView alloc]
        initWithFrame:CGRectMake(0, 0, MAX_LINE_SIDE * MAX_LINES, height)];
    CGRect rect;

    for (int i = 0; i < MAX_LINES; i++) {
        rect = CGRectMake((MAX_LINE_SIDE + MAX_LINE_GAP) * i, 0, MAX_LINE_SIDE,
                          MAX_LINE_SIDE);
        RouteColorBlobView *max =
            [[RouteColorBlobView alloc] initWithFrame:rect];
        max.tag = MAX_LINES + MAX_TAG - i - 1;
        [maxColors addSubview:max];
    }

    self.rightMargin = rightMargin ? 10.0 : 0.0;
    self.fixedMargin = fixedMargin;

    UILabel *label = [[UILabel alloc] init];

    label.tag = LABEL_TAG;
    maxColors.tag = LINES_TAG;

    // We overlay our text and blobs on top of the text label that was there
    // and use constraints to make the overlay move with the underlying label
    // This was the easiest way to make it all fit when an accessory is also
    // added in some cells.

    [self.textLabel addSubview:maxColors];
    [self.textLabel addSubview:label];

    self.textLabel.text = @" ";

    maxColors.translatesAutoresizingMaskIntoConstraints = FALSE;

    if (fixedMargin == 0.0) {
        [maxColors.rightAnchor
            constraintEqualToAnchor:self.contentView.rightAnchor
                           constant:-(MAX_LINE_SIDE * MAX_LINES +
                                      self.rightMargin)]
            .active = YES;
    } else {
        [maxColors.rightAnchor
            constraintEqualToAnchor:self.rightAnchor
                           constant:-(MAX_LINE_SIDE * MAX_LINES + fixedMargin)]
            .active = YES;
    }

    [maxColors.centerYAnchor
        constraintEqualToAnchor:self.contentView.centerYAnchor
                       constant:-MAX_LINE_SIDE / 2]
        .active = YES;

    label.text = @" ";

    label.translatesAutoresizingMaskIntoConstraints = FALSE;
    [label.topAnchor constraintEqualToAnchor:self.textLabel.topAnchor].active =
        YES;
    [label.leadingAnchor constraintEqualToAnchor:self.textLabel.leadingAnchor]
        .active = YES;
    [label.bottomAnchor constraintEqualToAnchor:self.textLabel.bottomAnchor]
        .active = YES;

    self.widthContraint =
        [label.rightAnchor constraintEqualToAnchor:self.textLabel.rightAnchor
                                          constant:-(MAX_LINE_SIDE * MAX_LINES +
                                                     self.rightMargin)];

    self.widthContraint.priority = 999;
    self.widthContraint.active = YES;

    // label.backgroundColor = UIColor.greenColor;
    self.textLabel.font = [UIFont fontWithName:@"HelveticaNeue"
                                          size:self.textLabel.font.pointSize];
}

- (int)addLineTag:(int)tag
             line:(TriMetInfo_ColoredLines)line
            lines:(TriMetInfo_ColoredLines)lines {
    if (tag - MAX_TAG > MAX_LINES) {
        return tag;
    }

    UIView *maxColors = [self.textLabel viewWithTag:LINES_TAG];

    RouteColorBlobView *view =
        (RouteColorBlobView *)[maxColors viewWithTag:tag];

    if (lines & line) {
        if ([view setRouteColorLine:line]) {
            tag++;
        }
    }

    return tag;
}

- (void)populateCellWithStation:(NSString *)station
                          lines:(TriMetInfo_ColoredLines)lines {

    int tag = MAX_TAG;

    UILabel *underLabel = self.textLabel;
    UILabel *label = [underLabel viewWithTag:LABEL_TAG];
    UIView *maxColors = [underLabel viewWithTag:LINES_TAG];

    label.attributedText = station.attributedStringFromMarkUp;

    label.adjustsFontSizeToFitWidth = YES;
    label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    self.accessibilityLabel = station.phonetic;
    self.imageView.image = nil;

    size_t noOfLines = TriMetInfoColoredLines.numOfLines;
    PtrConstRouteInfo allLines = TriMetInfoColoredLines.allLines;
    const int *sorted = [StationData getSortedColoredLines];

    // All the blobs in reverse sort order
    for (int i = (int)noOfLines - 1; i >= 0; i--) {
        PtrConstRouteInfo info = allLines + sorted[i];
        tag = [self addLineTag:tag line:info->line_bit lines:lines];
    }

    self.widthContraint.constant = -(MAX_LINE_SIDE * (tag - MAX_TAG) +
                                     self.rightMargin + self.fixedMargin);

    for (; tag < MAX_TAG + MAX_LINES; tag++) {
        RouteColorBlobView *view =
            (RouteColorBlobView *)[maxColors viewWithTag:tag];
        view.hidden = YES;
    }
    [self layoutIfNeeded];
}

@end
