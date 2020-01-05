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


#import "DepartureCell.h"
#include "ScreenConstants.h"
#import "ViewControllerBase.h"
#import "DebugLogging.h"
#import "UIColor+DarkMode.h"

#define kStandardWidth  (320)


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


enum VIEW_TAGS
{
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

- (UILabel *)routeLabel
{
    return (UILabel*)[self viewWithTag:ROUTE_TAG];
}

- (UILabel *)timeLabel
{
    return (UILabel*)[self viewWithTag:TIME_TAG];
}

- (UILabel *)minsLabel
{
    return (UILabel*)[self viewWithTag:MINS_TAG];
}

- (UILabel *)unitLabel
{
    return (UILabel*)[self viewWithTag:UNIT_TAG];
}

- (RouteColorBlobView *)routeColorView
{
    return (RouteColorBlobView*)[self viewWithTag:ROUTE_COLOR_TAG];
}


- (UILabel *)scheduledLabel
{
    return (UILabel*)[self viewWithTag:SCHEDULED_TAG];
}

- (UILabel *)detourLabel
{
    return (UILabel*)[self viewWithTag:DETOUR_TAG];
}

- (UILabel *)fullLabel
{
    return (UILabel*)[self viewWithTag:FULL_TAG];
}

- (BlockColorView *)blockColorView
{
    return (BlockColorView*)[self viewWithTag:BLOCK_COLOR_TAG];
}

- (CanceledBusOverlay *)cancelledOverlayView
{
    return (CanceledBusOverlay *)[self viewWithTag:CANCELED_OVERLAY_TAG];
}

- (bool)large
{
    // DEBUG_LOGF([UIApplication sharedApplication].delegate.window.bounds.size.width);
    return DEPARTURE_CELL_USE_LARGE;
}


typedef struct _DepartureCellAttributes
{
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
    CGFloat rowHeight;
    CGFloat minsGap;
    CGFloat rowGap;
    
    CGFloat blockColorHeight;
    CGFloat blockColorLeft;
    
} DepartureCellAttributes;

const CGFloat blockColorGap      =  2.0;
const CGFloat blockColorWidth    = 10.0;
const CGFloat blockColorLeftGap  =  4.0;


- (void)initDepartureCellAttributesWithWidth:(CGFloat)width attribures:(DepartureCellAttributes *)attr
{
    
    if (self.large)
    {
        attr->mainFontSize              = 32.0;
        attr->minsFontSize              = 42.0;
        attr->unitFontSize              = 28.0;
        attr->rowHeight                 = kLargeDepartureCellHeight;
        
        attr->minsWidth                 = 70.0;
        attr->minsUnitHeight            = 28.0;
        attr->labelHeight               = 45.0;
        attr->timeFontSize              = 28.0;
    }
    else
    {
        attr->mainFontSize              = 18.0;
        attr->minsFontSize              = 23.0;
        attr->unitFontSize              = 14.0;
        attr->rowHeight                 = kDepartureCellHeight;
        
        attr->minsWidth                 = 40.0;
        attr->minsUnitHeight            = 16.0;
        attr->labelHeight               = 26.0;
        attr->timeFontSize              = 14.0;
    }
    
    CGFloat rightMargin = width - self.contentView.frame.size.width;
    
    if (rightMargin < (blockColorWidth + blockColorGap + blockColorLeftGap))
    {
        rightMargin = blockColorWidth + blockColorGap + blockColorLeftGap;
    }
    
    attr->minsLeft             = width - attr->minsWidth - rightMargin;
    
    attr->shortLeftColumnWidth = attr->minsLeft - self.layoutMargins.left;
    attr->leftColumnWidth      = attr->shortLeftColumnWidth + attr->minsWidth;
    attr->longLeftColumnWidth  = width - self.layoutMargins.left - rightMargin;

    attr->minsGap                    = ((attr->rowHeight - attr->labelHeight - attr->minsUnitHeight) / 3.0);
    attr->rowGap                     = ((attr->rowHeight - attr->labelHeight - attr->labelHeight) / 3.0);
    
    attr->blockColorHeight           = attr->rowHeight - 5;
    attr->blockColorLeft             = width - blockColorGap - blockColorWidth;
}

+ (instancetype)tableView:(UITableView*)tableView cellWithReuseIdentifier:(NSString *)identifier;
{
    DepartureCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil)
    {
        cell = [[DepartureCell alloc] initWithReuseIdentifier:identifier];
    }    
    return cell;
}

static inline CGRect blockColorRect(DepartureCellAttributes *attr)
{
    return CGRectMake(attr->blockColorLeft, (attr->rowHeight - attr->blockColorHeight)/2, blockColorWidth, attr->blockColorHeight);
}

- (CGRect)routeRect:(DepartureCellAttributes *)attr width:(CGFloat)width
{
    return CGRectMake(self.layoutMargins.left, attr->minsGap, width, attr->labelHeight);
}

- (CGRect)routeColorRect:(DepartureCellAttributes *)attr
{
    return CGRectMake((self.layoutMargins.left - ROUTE_COLOR_WIDTH)/2 , attr->minsGap, ROUTE_COLOR_WIDTH, attr->labelHeight);
}

- (CGRect)timeRect:(DepartureCellAttributes *)attr width:(CGFloat)width
{
    // DEBUG_LOGF(self.layoutMargins.left);
    return CGRectMake(self.layoutMargins.left, attr->minsGap+attr->labelHeight+attr->minsGap, width, attr->minsUnitHeight);
}

static inline CGRect minsRect(DepartureCellAttributes *attr)
{
    return CGRectMake(attr->minsLeft, attr->minsGap, attr->minsWidth, attr->labelHeight);
}

static inline CGRect unitRect(DepartureCellAttributes *attr)
{
    return CGRectMake(attr->minsLeft, attr->minsGap+attr->labelHeight+attr->minsGap, attr->minsWidth, attr->minsUnitHeight);
}

- (DepartureCell *)initWithReuseIdentifier:(NSString *)identifier
{
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier])
    {
        DepartureCellAttributes attr;
        
        self.backgroundColor = [UIColor modeAwareCellBackground];
        
        [self initDepartureCellAttributesWithWidth:kStandardWidth attribures:&attr];
        
        BlockColorView *blockColor = [[BlockColorView alloc] initWithFrame:blockColorRect(&attr)];
        blockColor.tag = BLOCK_COLOR_TAG;
        [self.contentView addSubview:blockColor];
        
        UILabel *label;
        label = [[UILabel alloc] initWithFrame:[self routeRect:&attr width:attr.shortLeftColumnWidth]];
        label.tag = ROUTE_TAG;
        label.font = [UIFont boldSystemFontOfSize:attr.mainFontSize];
        label.adjustsFontSizeToFitWidth = YES;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        label.highlightedTextColor = [UIColor whiteColor];
        label.textColor = [UIColor modeAwareText];
        [self.contentView addSubview:label];
        
        RouteColorBlobView *colorStripe = [[RouteColorBlobView alloc] initWithFrame:[self routeColorRect:&attr]];
        colorStripe.tag = ROUTE_COLOR_TAG;
        [self.contentView addSubview:colorStripe];
        
        UIFont *smallTimeFont =  [UIFont systemFontOfSize:attr.unitFontSize];
        
        // Verdana has a fixed width numbers.  I don't like it, but needed to try it here.
        // UIFont *smallTimeFont =  [UIFont fontWithName:@"Verdana" size:attr.unitFontSize-1];

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
        label.font = [UIFont fontWithName:@"Verdana-bold" size:attr.minsFontSize];
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
        label.font = smallTimeFont;
        label.adjustsFontSizeToFitWidth = YES;
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        label.highlightedTextColor = [UIColor whiteColor];
        [self.contentView addSubview:label];
    }
    return self;
}

+ (instancetype)tableView:(UITableView*)tableView genericWithReuseIdentifier:(NSString *)identifier
{
    DepartureCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil)
    {
        cell = [[DepartureCell alloc] initGenericWithReuseIdentifier:identifier];
    }
    return cell;
}

- (DepartureCell *)initGenericWithReuseIdentifier:(NSString *)identifier
{
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier])
    {        
        DepartureCellAttributes attr;
        
        [self initDepartureCellAttributesWithWidth:kStandardWidth attribures:&attr];
        
        /*
         Create labels for the text fields; set the highlight color so that when the cell is selected it changes appropriately.
         */
        UILabel *label;
        
        BlockColorView *blockColor = [[BlockColorView alloc] initWithFrame:blockColorRect(&attr)];
        blockColor.tag = BLOCK_COLOR_TAG;
        [self.contentView addSubview:blockColor];
        
        // rect = CGRectMake(attr.LeftColumnOffset, attr.RowGap, spaceToDecorate? attr.LeftColumnWidth : attr.LongLeftColumnWidth, attr.LabelHeight);
        label = [[UILabel alloc] initWithFrame:[self routeRect:&attr width:attr.leftColumnWidth]];
        label.tag = ROUTE_TAG;
        label.font = [UIFont boldSystemFontOfSize:attr.mainFontSize];
        label.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:label];
        label.highlightedTextColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        
        RouteColorBlobView *colorStripe = [[RouteColorBlobView alloc] initWithFrame:[self routeColorRect:&attr]];
        colorStripe.tag = ROUTE_COLOR_TAG;
        [self.contentView addSubview:colorStripe];
        
        // rect = CGRectMake(attr.LeftColumnOffset,attr.RowGap * 2.0 + attr.LabelHeight, spaceToDecorate? attr.LeftColumnWidth : attr.LongLeftColumnWidth, attr.LabelHeight);
        label = [[UILabel alloc] initWithFrame:[self timeRect:&attr width:attr.leftColumnWidth]];
        label.tag = TIME_TAG;
        label.font = [UIFont systemFontOfSize:attr.timeFontSize];
        label.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:label];
        label.highlightedTextColor = [UIColor whiteColor];
        
        label = [[UILabel alloc] initWithFrame:[self timeRect:&attr width:attr.leftColumnWidth]];
        label.tag = SCHEDULED_TAG;
        label.font = [UIFont systemFontOfSize:attr.unitFontSize];
        label.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:label];
        label.highlightedTextColor = [UIColor whiteColor];
        
        label = [[UILabel alloc] initWithFrame:[self timeRect:&attr width:attr.leftColumnWidth]];
        label.tag = DETOUR_TAG;
        label.font = [UIFont systemFontOfSize:attr.unitFontSize];
        label.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:label];
        label.highlightedTextColor = [UIColor whiteColor];
        
        label = [[UILabel alloc] initWithFrame:[self timeRect:&attr width:attr.leftColumnWidth]];
        label.tag = FULL_TAG;
        label.font = [UIFont systemFontOfSize:attr.unitFontSize];
        label.adjustsFontSizeToFitWidth = YES;
        [self.contentView addSubview:label];
        label.highlightedTextColor = [UIColor whiteColor];
    }
    
    return self;
}

- (CGFloat)labelWidth:(UILabel *)label
{
    CGFloat width = 0;
    
    if (label !=nil & label.text!=nil && label.text.length!=0)
    {
        
        NSStringDrawingOptions options = NSStringDrawingTruncatesLastVisibleLine |
        NSStringDrawingUsesLineFragmentOrigin;
        
        NSDictionary *attr = @{NSFontAttributeName: label.font};
        CGRect rect = [label.text boundingRectWithSize:CGSizeMake(9999, 9999)
                                               options:options
                                            attributes:attr
                                               context:nil];
        width = rect.size.width;
    }
    
    return width;
}

- (CGFloat)moveLabelNextX:(CGFloat)nextX  label:(UILabel *)label
{
    NSString *text = label.text;
    
    if (text !=nil && text.length !=0)
    {

        label.hidden = NO;
        
        CGFloat width = [self labelWidth:label];
        
        CGRect frame = CGRectMake( nextX, label.frame.origin.y, width, label.frame.size.height );
        label.frame = frame;
        nextX += width;
        // DEBUG_LOG(@"%@ y %f h %f\n", text, frame.origin.y, frame.size.height);
    }
    else {
        label.hidden = YES;
    }
    
    return nextX;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


#define reset_font_size(F,S) F = resetFontSize(F,S)


static inline UIFont * resetFontSize(UIFont *font, CGFloat sz)
{
    if (font.pointSize != sz)
    {
        return [UIFont fontWithDescriptor:font.fontDescriptor size:sz];
    }
    
    return font;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    DepartureCellAttributes attr;
    
    [self initDepartureCellAttributesWithWidth:self.frame.size.width attribures:&attr];
    
    CGFloat leftColumnWidth = 0;
    
    if (self.minsLabel == nil)
    {
        if (self.accessoryType == UITableViewCellAccessoryNone)
        {
            leftColumnWidth = attr.longLeftColumnWidth;
        }
        else
        {
            leftColumnWidth = attr.leftColumnWidth;
        }
    }
    else
    {
        leftColumnWidth = attr.shortLeftColumnWidth;
        
        self.minsLabel.frame = minsRect(&attr);
        reset_font_size(self.minsLabel.font, attr.minsFontSize);
        
        self.unitLabel.frame = unitRect(&attr);
        reset_font_size(self.unitLabel.font, attr.unitFontSize);
        
        self.cancelledOverlayView.frame = minsRect(&attr);
    }
    
    self.routeLabel.frame = [self routeRect:&attr width:leftColumnWidth];
    reset_font_size(self.routeLabel.font, attr.mainFontSize);
    
    self.blockColorView.frame = blockColorRect(&attr);
    self.routeColorView.frame = [self routeColorRect:&attr];
    
    self.timeLabel.frame = [self timeRect:&attr width:leftColumnWidth];
    reset_font_size(self.timeLabel.font, attr.timeFontSize);
    
    self.scheduledLabel.frame = [self timeRect:&attr width:leftColumnWidth];
    reset_font_size(self.scheduledLabel.font, attr.unitFontSize);
    
    self.detourLabel.frame = [self timeRect:&attr width:leftColumnWidth];
    reset_font_size(self.detourLabel.font, attr.unitFontSize);
    
    self.fullLabel.frame = [self timeRect:&attr width:leftColumnWidth];
    reset_font_size(self.fullLabel.font, attr.unitFontSize);
    
    CGFloat nextX = self.timeLabel.frame.origin.x;
    nextX = [self moveLabelNextX:nextX label:self.timeLabel];
    nextX = [self moveLabelNextX:nextX label:self.scheduledLabel];
    nextX = [self moveLabelNextX:nextX label:self.detourLabel];
    
    if (self.unitLabel)
    {
        CGFloat fullWidth = [self labelWidth:self.fullLabel];
        CGFloat unitLeft = self.unitLabel.frame.origin.x;
        const CGFloat gap = 0.0;
    
        if ((fullWidth + nextX + gap) < unitLeft)
        {
            [self moveLabelNextX:nextX label:self.fullLabel];
        }
        else
        {
            nextX = [self moveLabelNextX:nextX label:self.fullLabel];
            [self moveLabelNextX:nextX+gap label:self.unitLabel];
        }
    }
    else
    {
        [self moveLabelNextX:nextX label:self.fullLabel];
    }
}

@end
