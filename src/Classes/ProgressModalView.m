//
//  ProgressModal.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/19/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "ProgressModalView.h"
#import "DebugLogging.h"
#import "NSString+MoreMarkup.h"
#import "QuartzCore/QuartzCore.h"
#import "RoundedTransparentRectView.h"
#import "TaskDispatch.h"
#import "UIFont+Utility.h"

#pragma mark ProgressModalView

#define kActivityViewWidth 200
#define kActivityViewHeight 200
#define kProgressWidth 65
#define kProgressHeight 65
#define kTextHeight 25
#define kTextSpaceOffset                                                       \
    (kActivityViewHieght - ((kActivityViewHieght + kProgressHeight) / 2))
#define kBarHeight 10
#define kTextWidth kBarWidth
#define kBarWidth (kActivityViewWidth - 20)
#define kBarGap 10
#define kMargin 0
#define kTopMargin (kMargin)
#define kButtonHeight 40
#define kButtonGap 5

@interface ProgressModalView ()

@property(nonatomic) NSInteger itemsDone;
@property(nonatomic, strong) UIProgressView *progress;
@property(nonatomic, strong) UILabel *subLabel;
@property(nonatomic, strong) UILabel *helpLabel;
@property(nonatomic, strong) UIView *helpFrame;

@end

@implementation ProgressModalView

- (instancetype)initWithParent:(UIView *)back
                         items:(NSInteger)items
                         title:(NSString *)title
                      delegate:(id<ProgressDelegate>)delegate
                   orientation:(UIInterfaceOrientation)orientation {
    if (self = [super initWithFrame:back.frame]) {
        _totalItems = items < 1 ? 1 : items;

        [self addSubview:[self createScreenBlockView:back]];

        RoundedTransparentRectView *roundedRect =
            [self createRoundedRect:back.frame.size title:title];

        UIActivityIndicatorView *whirly = [self createWhirly];
        [roundedRect addSubview:whirly];
        [whirly startAnimating];

        _subLabel = [self createSubtext:roundedRect
                              yPosition:whirly.frame.origin.y];
        [roundedRect addSubview:self.subLabel];

        _progress = [self createProgress:roundedRect items:items];
        [roundedRect addSubview:self.progress];

        [self addSubview:roundedRect];

        UILabel *helpTextView = [self createHelpText:roundedRect.frame];
        _helpLabel = helpTextView;
        [self addSubview:helpTextView];

        if (delegate) {
            _progressDelegate = delegate;
            UIButton *cancelButton =
                [self createCancelButton:roundedRect.frame
                         backgroundColor:roundedRect.color];

            [cancelButton addTarget:self
                             action:@selector(cancelButtonAction:)
                   forControlEvents:UIControlEventTouchUpInside];
            
            cancelButton.layer.cornerRadius = 5.0;
            cancelButton.clipsToBounds = true;

            [self addSubview:cancelButton];
            [self bringSubviewToFront:cancelButton];
        }
    }

    return self;
}

- (void)dealloc {
    _progressDelegate = nil;
}

- (void)cancelButtonAction:(id)sender {
    UIButton *button = sender;

    button.hidden = true;

    [self.progressDelegate progressDelegateCancel];
}

- (UIView *)createScreenBlockView:(UIView *)back {
    CGRect backFrame = back.frame;
    
    UIView *view = [[UIView alloc]
        initWithFrame:CGRectMake(
                          backFrame.origin.x + kMargin,
                          backFrame.origin.y + kTopMargin,
                          (backFrame.size.width - kMargin * 2),
                          (backFrame.size.height - kTopMargin - kMargin))];

    view.backgroundColor = [UIColor colorWithRed:0.5
                                           green:0.5
                                            blue:0.5
                                           alpha:0.6];

    view.opaque = NO;

    return view;
}

- (RoundedTransparentRectView *)createRoundedRect:(const CGSize)backSize
                                            title:(NSString *)title {
    CGRect roundedFrame =
        CGRectMake((backSize.width - kActivityViewWidth) / 2,
                   (backSize.height - kActivityViewHeight) / 2 -
                       (kButtonGap + kButtonHeight) / 2,
                   kActivityViewWidth, kActivityViewHeight);

    DEBUG_LOG_CGRect(roundedFrame);
    
    RoundedTransparentRectView *view =
        [[RoundedTransparentRectView alloc] initWithFrame:roundedFrame];

    bool dark = NO;

    dark =
        (view.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);

    if (dark) {
        view.color = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.90];
    } else {
        view.color = [UIColor colorWithRed:112.0 / 255.0
                                     green:138.0 / 255.0
                                      blue:128.0 / 255.0
                                     alpha:0.90];
    }

    view.opaque = NO;

    if (title != nil) {
        [view addSubview:[self createTitleView:title]];
    }

    return view;
}

- (UIActivityIndicatorView *)createWhirly {
    UIActivityIndicatorView *whirly = [[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];

    whirly.color = UIColor.labelColor;
    whirly.frame = CGRectMake((kActivityViewWidth - kProgressWidth) / 2,
                              (kActivityViewHeight - kProgressHeight) / 2,
                              kProgressWidth, kProgressHeight);
    return whirly;
}

- (UILabel *)createSubtext:(RoundedTransparentRectView *)frontWin
                 yPosition:(CGFloat)y {
    CGRect frame = CGRectMake(
        (kActivityViewWidth - kTextWidth) / 2,
        ((y + kProgressHeight) + (kActivityViewWidth - kBarHeight - kBarGap)) /
                2 -
            kTextHeight / 2,
        kTextWidth, kTextHeight);

    UILabel *label = [[UILabel alloc] initWithFrame:frame];

    label.text = nil;
    label.opaque = NO;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor labelColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = NO;
    label.font = [UIFont monospacedDigitSystemFontOfSize:12];

    return label;
}

- (UIProgressView *)createProgress:(RoundedTransparentRectView *)frontWin
                             items:(NSInteger)items {
    CGRect frame = CGRectMake((kActivityViewWidth - kBarWidth) / 2,
                              (kActivityViewHeight - kBarHeight - kBarGap),
                              kBarWidth, kBarHeight);

    UIProgressView *view = [[UIProgressView alloc] initWithFrame:frame];

    view.progressViewStyle = UIProgressViewStyleDefault;
    view.progress = 0.0;

    if (items == 1) {
        view.hidden = YES;
    }

    return view;
}

- (UIButton *)createCancelButton:(const CGRect)frontFrame
                 backgroundColor:(UIColor *)backgroundColor {
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];

    static NSAttributedString *cancelText = nil;

    DoOnce(^{
      cancelText = [@"#b#RCancel"
          attributedStringFromMarkUpWithFont:[UIFont systemFontOfSize:20]];
    });

    [cancelButton setAttributedTitle:cancelText forState:UIControlStateNormal];

    cancelButton.frame =
        CGRectMake(frontFrame.origin.x,
                   frontFrame.origin.y + frontFrame.size.height + kButtonGap,
                   kActivityViewWidth, kButtonHeight);

    cancelButton.backgroundColor = backgroundColor;

    cancelButton.hidden = NO;

    return cancelButton;
}

- (UILabel *)createHelpText:(const CGRect)frontFrame {
    double y = frontFrame.origin.y + frontFrame.size.height + 2 * kButtonGap +
               kButtonHeight;
    double width = kActivityViewWidth * 1.5;
    CGRect helpOuterFrame =
        CGRectMake(frontFrame.origin.x - (width - kActivityViewWidth) / 2, y,
                   width, kButtonHeight * 2);

    CGRect helpInnerFrame = CGRectInset(helpOuterFrame, 5, 5);

    UILabel *label = [[UILabel alloc] initWithFrame:helpInnerFrame];

    label.text = nil;
    label.opaque = NO;
    label.backgroundColor = [UIColor clearColor];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 10;
    label.textColor = [UIColor redColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = NO;
    label.font = [UIFont boldMonospacedDigitSystemFontOfSize:16];
    label.hidden = YES;

    label.layer.masksToBounds = YES;
    label.layer.cornerRadius = 5.0;

    return label;
}

- (UILabel *)createTitleView:(NSString *)title {
    CGRect titleFrame = CGRectMake((kActivityViewWidth - kTextWidth) / 2,
                                   (kBarGap), kTextWidth, kTextHeight);

    UILabel *label = [[UILabel alloc] initWithFrame:titleFrame];

    label.text = title;
    label.opaque = NO;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor labelColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = YES;
    label.font = [UIFont monospacedDigitSystemFontOfSize:17];

    return label;
}

- (void)addSubtext:(NSString *)subtext {
    if (self.subLabel && subtext) {
        self.subLabel.text = subtext;
    }
}

- (void)addHelpText:(NSString *)helpText {
    self.helpLabel.text = helpText;

    if (helpText == nil) {
        self.helpLabel.hidden = YES;
        self.helpFrame.hidden = YES;
    } else {
        CGRect rect = self.helpLabel.frame;

        NSStringDrawingOptions options =
            NSStringDrawingTruncatesLastVisibleLine |
            NSStringDrawingUsesLineFragmentOrigin;

        NSDictionary *attr = @{NSFontAttributeName : self.helpLabel.font};
        rect = [helpText boundingRectWithSize:rect.size
                                      options:options
                                   attributes:attr
                                      context:nil];

        rect.origin = self.helpLabel.frame.origin;
        rect.size.height += 10;

        self.helpLabel.frame = rect;

        self.helpLabel.hidden = NO;
        self.helpFrame.hidden = NO;
        self.helpLabel.layer.cornerRadius = 5.0;
        self.helpLabel.clipsToBounds = true;
    }
}

- (void)totalItems:(NSInteger)total {

    self.totalItems = total < 1 ? 1 : total;

    if (self.totalItems > 1) {
        self.progress.hidden = NO;
    } else {
        self.progress.hidden = YES;
    }

    [self itemsDone:self.itemsDone];
}

- (void)itemsDone:(NSInteger)done {
    self.itemsDone = done;
    float newProgress = (float)done / (float)self.totalItems;

    DEBUG_LOG_MAYBE(newProgress < self.progress.progress, @"Backwards:  %f, %f",
                    newProgress, self.progress.progress);

    self.progress.progress = newProgress;
}

- (void)subItemsDone:(NSInteger)subItemsDone totalSubs:(NSInteger)totalSubs;
{
    if (totalSubs == 0) {
        totalSubs = 1;
    }

    self.progress.hidden = NO;
    float newProgress =
        ((float)(self.itemsDone) + ((float)subItemsDone / (float)totalSubs)) /
        (float)self.totalItems;

    DEBUG_LOG_MAYBE(newProgress < self.progress.progress, @"Backwards:  %f, %f",
                    newProgress, self.progress.progress);

    self.progress.progress = newProgress;
}

@end
