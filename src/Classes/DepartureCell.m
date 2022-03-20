//
//  DepartureCell.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/1/17.
//  Copyright © 2017 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE kLogUserInterface

#import "DepartureCell.h"
#import "ScreenConstants.h"
#import "ViewControllerBase.h"
#import "DebugLogging.h"
#import "UIColor+DarkMode.h"
#import "UIFont+Utility.h"

#define kStandardWidth        (320)
#define DEPARTURE_CELL_HEIGHT (DEPARTURE_CELL_USE_LARGE ? kLargeDepartureCellHeight : kDepartureCellHeight)

@interface DepartureCell () {
    bool _tallRouteLabel;
}

@end

@implementation DepartureCell

@dynamic routeLabel;
@dynamic timeLabel;
@dynamic minsLabel;
@dynamic unitLabel;
@dynamic routeColorView;
@dynamic scheduledLabel;
@dynamic detourLabel;
@dynamic fullLabel;
@dynamic blockColorView;
@dynamic cancelledOverlayView;
@dynamic large;


enum VIEW_TAGS {
    ROUTE_TAG = 1,
    TIME_TAG,
    MINS_TAG,
    UNIT_TAG,
    ROUTE_COLOR_TAG,
    SCHEDULED_TAG,
    DETOUR_TAG,
    FULL_TAG,
    BLOCK_COLOR_TAG,
    CANCELED_OVERLAY_TAG
};

- (UILabel *)routeLabel {
    return (UILabel *)[self viewWithTag:ROUTE_TAG];
}

- (UILabel *)timeLabel {
    return (UILabel *)[self viewWithTag:TIME_TAG];
}

- (UILabel *)minsLabel {
    return (UILabel *)[self viewWithTag:MINS_TAG];
}

- (UILabel *)unitLabel {
    return (UILabel *)[self viewWithTag:UNIT_TAG];
}

- (RouteColorBlobView *)routeColorView {
    return (RouteColorBlobView *)[self viewWithTag:ROUTE_COLOR_TAG];
}

- (UILabel *)scheduledLabel {
    return (UILabel *)[self viewWithTag:SCHEDULED_TAG];
}

- (UILabel *)detourLabel {
    return (UILabel *)[self viewWithTag:DETOUR_TAG];
}

- (UILabel *)fullLabel {
    return (UILabel *)[self viewWithTag:FULL_TAG];
}

- (BlockColorView *)blockColorView {
    return (BlockColorView *)[self viewWithTag:BLOCK_COLOR_TAG];
}

- (CanceledBusOverlay *)cancelledOverlayView {
    return (CanceledBusOverlay *)[self viewWithTag:CANCELED_OVERLAY_TAG];
}

- (bool)large {
    // DEBUG_LOGF([UIApplication sharedApplication].delegate.window.bounds.size.width);
    return DEPARTURE_CELL_USE_LARGE;
}

typedef struct DepartureCellAttributesStruct {
    CGFloat leftColumnWidth;
    CGFloat shortLeftColumnWidth;
    CGFloat longLeftColumnWidth;
    
    CGFloat minsLeft;
    CGFloat minsWidth;
    CGFloat minsUnitHeight;
    
    CGFloat mainFontSize;
    CGFloat minsFontSize;
    CGFloat unitFontSize;
    CGFloat labelHeight;
    CGFloat timeFontSize;
    CGFloat innerCellHeight;
    CGFloat minsGap;
    CGFloat rowGap;
    CGFloat routeLabelExpansion;
    
    CGFloat blockColorHeight;
    CGFloat blockColorLeft;
} DepartureCellAttributes;

const CGFloat blockColorGap = 2.0;
const CGFloat blockColorWidth = 10.0;
const CGFloat blockColorLeftGap = 4.0;
const CGFloat normalLabelHeight = 26.0;

- (void)initDepartureCellAttributesWithWidth:(CGFloat)width attribures:(DepartureCellAttributes *)attr {
    if (self.large) {
        attr->mainFontSize = 32.0;
        attr->minsFontSize = 43.0;
        attr->unitFontSize = 28.0;
        attr->innerCellHeight = kLargeDepartureCellHeight;
        
        attr->minsWidth = 70.0;
        attr->minsUnitHeight = 28.0;
        attr->labelHeight = 45.0;
        attr->timeFontSize = 28.0;
    } else {
        attr->mainFontSize = 18.0;
        attr->minsFontSize = 24.0;
        attr->unitFontSize = 14.0;
        attr->innerCellHeight = kDepartureCellHeight;
        
        attr->minsWidth = 40.0;
        attr->minsUnitHeight = 16.0;
        attr->labelHeight = normalLabelHeight;
        attr->timeFontSize = 14.0;
    }
    
    if (_tallRouteLabel && !self.large) {
        attr->routeLabelExpansion = MAX(attr->labelHeight, attr->minsUnitHeight * 2);
        attr->minsFontSize = 43.0;
        attr->minsWidth = 70.0;
        attr->mainFontSize = 24.0;
    } else {
        attr->routeLabelExpansion = 0.0;
    }
    
    CGFloat rightMargin = width - self.contentView.frame.size.width;
    
    if (rightMargin < (blockColorWidth + blockColorGap + blockColorLeftGap)) {
        rightMargin = blockColorWidth + blockColorGap + blockColorLeftGap;
    }
    
    attr->minsLeft = width - attr->minsWidth - rightMargin;
    
    attr->shortLeftColumnWidth = attr->minsLeft - self.layoutMargins.left;
    
    if (_tallRouteLabel && !self.large) {
        attr->shortLeftColumnWidth -= 3;  // small gap
    }
    
    attr->leftColumnWidth = attr->shortLeftColumnWidth + attr->minsWidth;
    attr->longLeftColumnWidth = width - self.layoutMargins.left - rightMargin;
    
    attr->minsGap = ((attr->innerCellHeight - attr->labelHeight - attr->minsUnitHeight) / 3.0);
    attr->rowGap = ((attr->innerCellHeight - attr->labelHeight - attr->labelHeight) / 3.0);
    
    attr->blockColorHeight = attr->innerCellHeight - 5;
    attr->blockColorLeft = width - blockColorGap - blockColorWidth;
}

+ (instancetype)tableView:(UITableView *)tableView cellWithReuseIdentifier:(NSString *)identifier tallRouteLabel:(bool)tallRouteTable {
    DepartureCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) {
        cell = [[DepartureCell alloc] initWithReuseIdentifier:identifier tallRouteLabel:tallRouteTable];
    }
    
    return cell;
}

static inline CGRect blockColorRect(DepartureCellAttributes *attr) {
    return CGRectMake(attr->blockColorLeft, (attr->innerCellHeight - attr->blockColorHeight) / 2, blockColorWidth, attr->routeLabelExpansion + attr->blockColorHeight);
}

- (CGRect)routeRect:(DepartureCellAttributes *)attr width:(CGFloat)width {
    return CGRectMake(self.layoutMargins.left, attr->minsGap, width, attr->labelHeight + attr->routeLabelExpansion);
}

- (CGRect)routeColorRect:(DepartureCellAttributes *)attr {
    return CGRectMake((self.layoutMargins.left - ROUTE_COLOR_WIDTH) / 2, attr->minsGap, ROUTE_COLOR_WIDTH, attr->labelHeight + attr->routeLabelExpansion);
}

- (CGRect)timeRect:(DepartureCellAttributes *)attr width:(CGFloat)width {
    // DEBUG_LOGF(self.layoutMargins.left);
    return CGRectMake(self.layoutMargins.left, attr->routeLabelExpansion + attr->minsGap + attr->labelHeight + attr->minsGap, width, attr->minsUnitHeight);
}

static inline CGRect minsRect(DepartureCellAttributes *attr) {
    return CGRectMake(attr->minsLeft, attr->minsGap, attr->minsWidth, attr->labelHeight + attr->routeLabelExpansion);
}

static inline CGRect unitRect(DepartureCellAttributes *attr) {
    return CGRectMake(attr->minsLeft, attr->minsGap + attr->labelHeight + attr->minsGap + attr->routeLabelExpansion, attr->minsWidth, attr->minsUnitHeight);
}

- (DepartureCell *)initWithReuseIdentifier:(NSString *)identifier tallRouteLabel:(bool)tallRouteLabel {
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier]) {
        _tallRouteLabel = tallRouteLabel;
        DepartureCellAttributes attr;
        
        self.backgroundColor = [UIColor modeAwareCellBackground];
        
        [self initDepartureCellAttributesWithWidth:kStandardWidth attribures:&attr];
        
        BlockColorView *blockColor = [[BlockColorView alloc] initWithFrame:blockColorRect(&attr)];
        blockColor.tag = BLOCK_COLOR_TAG;
        [self.contentView addSubview:blockColor];
        
        UILabel *label;
        label = [[UILabel alloc] initWithFrame:[self routeRect:&attr width:attr.shortLeftColumnWidth]];
        label.tag = ROUTE_TAG;
        label.font =   [UIFont fontWithName:@"HelveticaNeue-Bold" size:attr.mainFontSize];
        label.adjustsFontSizeToFitWidth = YES;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        label.highlightedTextColor = [UIColor whiteColor];
        label.textColor = [UIColor modeAwareText];
        
        if (_tallRouteLabel) {
            label.numberOfLines = 2;
        } else {
            label.numberOfLines = 1;
        }
        
        [self.contentView addSubview:label];
        
        RouteColorBlobView *colorStripe = [[RouteColorBlobView alloc] initWithFrame:[self routeColorRect:&attr]];
        colorStripe.tag = ROUTE_COLOR_TAG;
        [self.contentView addSubview:colorStripe];
    
        UIFont *smallTimeFont = [UIFont monospacedDigitSystemFontOfSize:attr.timeFontSize];
        
        label = [[UILabel alloc] initWithFrame:[self timeRect:&attr width:attr.shortLeftColumnWidth]];
        label.tag = TIME_TAG;
        label.font = smallTimeFont;
        label.adjustsFontSizeToFitWidth = YES;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        label.highlightedTextColor = [UIColor whiteColor];
        
        [self.contentView addSubview:label];
        
        label = [[UILabel alloc] initWithFrame:[self timeRect:&attr width:attr.shortLeftColumnWidth]];
        label.tag = SCHEDULED_TAG;
        label.font = smallTimeFont;
        label.adjustsFontSizeToFitWidth = YES;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        label.highlightedTextColor = [UIColor whiteColor];
        [self.contentView addSubview:label];
        
        label = [[UILabel alloc] initWithFrame:[self timeRect:&attr width:attr.shortLeftColumnWidth]];
        label.tag = DETOUR_TAG;
        label.font = smallTimeFont;
        label.adjustsFontSizeToFitWidth = YES;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        label.highlightedTextColor = [UIColor whiteColor];
        [self.contentView addSubview:label];
        
        label = [[UILabel alloc] initWithFrame:[self timeRect:&attr width:attr.leftColumnWidth]];
        label.tag = FULL_TAG;
        label.font = smallTimeFont;
        label.adjustsFontSizeToFitWidth = YES;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        [self.contentView addSubview:label];
        label.highlightedTextColor = [UIColor whiteColor];
        
        label = [[UILabel alloc] initWithFrame:minsRect(&attr)];
        label.tag = MINS_TAG;
        label.font = [UIFont fontWithName:@"HelveticaNeue-bold" size:attr.minsFontSize];
        label.adjustsFontSizeToFitWidth = YES;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        label.highlightedTextColor = [UIColor whiteColor];
        [self.contentView addSubview:label];
        
        CanceledBusOverlay *canceled = [[CanceledBusOverlay alloc] initWithFrame:minsRect(&attr)];
        canceled.tag = CANCELED_OVERLAY_TAG;
        canceled.backgroundColor = [UIColor clearColor];
        canceled.hidden = YES;
        [self.contentView addSubview:canceled];
        
        label = [[UILabel alloc] initWithFrame:unitRect(&attr)];
        label.tag = UNIT_TAG;
        label.font = [UIFont fontWithName:@"HelveticaNeue" size:attr.unitFontSize];
        label.adjustsFontSizeToFitWidth = YES;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        label.highlightedTextColor = [UIColor whiteColor];
        [self.contentView addSubview:label];
        
        [self setConstraintsForAttr:&attr];
    }
    
    return self;
}

+ (instancetype)tableView:(UITableView *)tableView genericWithReuseIdentifier:(NSString *)identifier {
    DepartureCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) {
        cell = [[DepartureCell alloc] initGenericWithReuseIdentifier:identifier];
    }
    
    return cell;
}

- (DepartureCell *)initGenericWithReuseIdentifier:(NSString *)identifier {
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier]) {
        DepartureCellAttributes attr;
        
        _tallRouteLabel = NO;
        [self initDepartureCellAttributesWithWidth:kStandardWidth attribures:&attr];
        
        /*
         Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
         */
        UILabel *label;
        
        BlockColorView *blockColor = [[BlockColorView alloc] initWithFrame:blockColorRect(&attr)];
        blockColor.tag = BLOCK_COLOR_TAG;
        [self.contentView addSubview:blockColor];
        
        label = [[UILabel alloc] initWithFrame:[self routeRect:&attr width:attr.leftColumnWidth]];
        label.tag = ROUTE_TAG;
        label.font = [UIFont boldMonospacedDigitSystemFontOfSize:attr.mainFontSize];
        label.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:label];
        label.highlightedTextColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        
        RouteColorBlobView *colorStripe = [[RouteColorBlobView alloc] initWithFrame:[self routeColorRect:&attr]];
        colorStripe.tag = ROUTE_COLOR_TAG;
        [self.contentView addSubview:colorStripe];
        
        label = [[UILabel alloc] initWithFrame:[self timeRect:&attr width:attr.leftColumnWidth]];
        label.tag = TIME_TAG;
        label.font = [UIFont monospacedDigitSystemFontOfSize:attr.timeFontSize weight:UIFontWeightRegular];
        label.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:label];
        label.highlightedTextColor = [UIColor whiteColor];
        
        label = [[UILabel alloc] initWithFrame:[self timeRect:&attr width:attr.leftColumnWidth]];
        label.tag = SCHEDULED_TAG;
        label.font = [UIFont monospacedDigitSystemFontOfSize:attr.unitFontSize];
        label.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:label];
        label.highlightedTextColor = [UIColor whiteColor];
        
        label = [[UILabel alloc] initWithFrame:[self timeRect:&attr width:attr.leftColumnWidth]];
        label.tag = DETOUR_TAG;
        label.font = [UIFont monospacedDigitSystemFontOfSize:attr.unitFontSize];
        label.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:label];
        label.highlightedTextColor = [UIColor whiteColor];
        
        label = [[UILabel alloc] initWithFrame:[self timeRect:&attr width:attr.leftColumnWidth]];
        label.tag = FULL_TAG;
        label.font = [UIFont monospacedDigitSystemFontOfSize:attr.unitFontSize];
        label.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:label];
        label.highlightedTextColor = [UIColor whiteColor];
        
        [self setConstraintsForAttr:&attr];
    }
    
    return self;
}

static CGFloat labelWidth(UILabel *label) {
    CGFloat width = 0;
    
    if (label != nil & label.text != nil && label.text.length != 0) {
        NSStringDrawingOptions options = NSStringDrawingTruncatesLastVisibleLine |
        NSStringDrawingUsesLineFragmentOrigin;
        
        NSDictionary *attr = @{ NSFontAttributeName: label.font };
        CGRect rect = [label.text boundingRectWithSize:CGSizeMake(9999, 9999)
                                               options:options
                                            attributes:attr
                                               context:nil];
        width = rect.size.width;
    }
    
    return width;
}

static inline CGFloat moveLabelNextX(CGFloat nextX, UILabel *label) {
    NSString *text = label.text;
    if (text != nil && text.length != 0) {
        label.hidden = NO;
        CGFloat width = labelWidth(label);
        label.frame = CGRectMake(nextX, label.frame.origin.y, width, label.frame.size.height);
        nextX += width;
    } else {
        label.hidden = YES;
    }
    return nextX;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

static inline void resetLabelFontSize(UILabel *label, CGFloat sz) {
    if (label.font.pointSize != sz) {
        label.font = [UIFont fontWithDescriptor:label.font.fontDescriptor size:sz];
    }
}

- (void)resetConstraints {
    DepartureCellAttributes attr;
    
    [self initDepartureCellAttributesWithWidth:self.frame.size.width attribures:&attr];
    [self setConstraintsForAttr:&attr];
}

- (void)setConstraintsForAttr:(DepartureCellAttributes *)attr {
    CGFloat height = attr->innerCellHeight + attr->routeLabelExpansion;
    
    DEBUG_LOGO(self.heightConstraint);
    DEBUG_LOGF(self.frame.size.height);
    DEBUG_LOGF(height);
    
    if (self.heightConstraint == nil)
    {
        self.heightConstraint = [NSLayoutConstraint constraintWithItem:self
                                                             attribute:NSLayoutAttributeHeight
                                                             relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                                toItem:nil
                                                             attribute:NSLayoutAttributeNotAnAttribute
                                                            multiplier:1
                                                              constant:height];
        
        // This stops an exception and allows other constraints to also be taken into account
        self.heightConstraint.priority = UILayoutPriorityDefaultLow;
        
        [self addConstraint:self.heightConstraint];
    } else if (self.heightConstraint.constant != height || self.frame.size.height != height) {
        DEBUG_LOGF(self.heightConstraint.constant);
        self.heightConstraint.constant = height;
    }
}


- (void)layoutSubviews {
    DepartureCellAttributes attr;
    
    [self initDepartureCellAttributesWithWidth:self.frame.size.width attribures:&attr];
    [self setConstraintsForAttr:&attr];
    [super layoutSubviews];
    
    CGFloat leftColumnWidth = 0;
    
    if (self.minsLabel == nil) {
        if (self.accessoryType == UITableViewCellAccessoryNone) {
            leftColumnWidth = attr.longLeftColumnWidth;
        } else {
            leftColumnWidth = attr.leftColumnWidth;
        }
    } else {
        leftColumnWidth = attr.shortLeftColumnWidth;
        
        self.minsLabel.frame = minsRect(&attr);
        resetLabelFontSize(self.minsLabel, attr.minsFontSize);
        
        self.unitLabel.frame = unitRect(&attr);
        resetLabelFontSize(self.unitLabel, attr.unitFontSize);
        
        self.cancelledOverlayView.frame = minsRect(&attr);
    }
    
    self.routeLabel.frame = [self routeRect:&attr width:leftColumnWidth];
    resetLabelFontSize(self.routeLabel, attr.mainFontSize);
    
    self.blockColorView.frame = blockColorRect(&attr);
    self.routeColorView.frame = [self routeColorRect:&attr];
    
    self.timeLabel.frame = [self timeRect:&attr width:leftColumnWidth];
    resetLabelFontSize(self.timeLabel, attr.timeFontSize);
    
    self.scheduledLabel.frame = [self timeRect:&attr width:leftColumnWidth];
    resetLabelFontSize(self.scheduledLabel, attr.timeFontSize);
    
    self.fullLabel.frame = [self timeRect:&attr width:leftColumnWidth];
    resetLabelFontSize(self.fullLabel, attr.timeFontSize);
    
    self.detourLabel.frame = [self timeRect:&attr width:leftColumnWidth];
    resetLabelFontSize(self.detourLabel, attr.timeFontSize);
    
    CGFloat nextX = self.timeLabel.frame.origin.x;
    
    nextX = moveLabelNextX(nextX,self.timeLabel);
    nextX = moveLabelNextX(nextX,self.scheduledLabel);
    nextX = moveLabelNextX(nextX,self.fullLabel);
    
    const CGFloat gap = 0.0;
    
    // self.detourLabel.text = [NSString stringWithFormat:@"h%d c%d f%d", (int)height, (int)self.heightConstraint.constant, (int)self.frame.size.height];
    
    if (self.unitLabel) {
        CGFloat fullWidth = labelWidth(self.detourLabel);
        CGFloat unitLeft = self.unitLabel.frame.origin.x;
        
        if ((fullWidth + nextX + gap) < unitLeft) {
            // Shift a little to the right
            nextX = unitLeft - fullWidth - gap;
            moveLabelNextX(nextX, self.detourLabel);
        } else {
            nextX = moveLabelNextX(nextX, self.detourLabel);
            moveLabelNextX(nextX + gap, self.unitLabel);
        }
    } else {
        moveLabelNextX(nextX, self.detourLabel);
    }
}

+ (CGFloat)cellHeightWithTallRouteLabel:(bool)tallRouteLabel {
    return (DEPARTURE_CELL_USE_LARGE ? kLargeDepartureCellHeight : (kDepartureCellHeight + (tallRouteLabel ? normalLabelHeight : 0.0)));
}

@end
