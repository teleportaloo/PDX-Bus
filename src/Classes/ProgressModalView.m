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
#import "UIApplication+Compat.h"
#import "UIFont+Utility.h"

#pragma mark ProgressModalView

#define kDimmerTag 25
#define kCancelTag 42
#define kRoundedTag 85

#define kActivityViewWidth 200
#define kActivityViewHeight 200
#define kProgressWidth 65
#define kProgressHeight 65
#define kTextHeight 25
#define kTextSpaceOffset (kActivityViewHieght - ((kActivityViewHieght + kProgressHeight) / 2))
#define kBarHeight 10
#define kTextWidth kBarWidth
#define kBarWidth (kActivityViewWidth - 20)
#define kBarGap 10
#define kMargin 0
#define kTopMargin (kMargin)
#define kButtonHeight 40
#define kButtonGap 5

@interface ProgressModalView ()

@property (nonatomic) NSInteger itemsDone;
@property (nonatomic, strong) UIProgressView *progress;
@property (nonatomic, strong) UILabel *subLabel;
@property (nonatomic, strong) UILabel *helpLabel;
@property (nonatomic, strong) UIView *helpContainer;

@property (nonatomic, strong) UIWindow *shieldWindow;       // blocks toolbar taps
@property (nonatomic, strong) UIViewController *shieldHost; // hosts this view

@end

@implementation ProgressModalView

+ (ProgressModalView *)presentWithParent:(UIViewController *)parent
                                   items:(NSInteger)items
                                   title:(NSString *)title
                                delegate:(id<ProgressDelegate>)delegate {
    if (!parent) {
        parent = UIApplication.topViewController;
    }
    if (!parent)
        return nil;
    return [self presentInViewController:parent items:items title:title delegate:delegate];
}

+ (ProgressModalView *)presentInViewController:(UIViewController *)vc
                                         items:(NSInteger)items
                                         title:(NSString *)title
                                      delegate:(id<ProgressDelegate>)delegate {
    if (!vc.view.window) {
        [vc.view layoutIfNeeded];
    }
    UIWindow *base = vc.view.window ?: vc.navigationController.view.window;
    if (!base)
        return nil;

    UIWindowScene *scene = (UIWindowScene *)base.windowScene;

    if (!scene) {
        // Fallback: grab any active scene/window
        for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
            if (s.activationState == UISceneActivationStateForegroundActive &&
                [s isKindOfClass:UIWindowScene.class]) {
                scene = (UIWindowScene *)s;
                break;
            }
        }
        if (!scene)
            return nil;
    }

    // Create the shield window above everything (incl. liquid bars)
    UIWindow *shield = [[UIWindow alloc] initWithWindowScene:scene];
    shield.frame = base.bounds;
    shield.windowLevel = UIWindowLevelAlert + 100;
    shield.backgroundColor = UIColor.clearColor;

    UIViewController *host = [UIViewController new];
    host.view.backgroundColor = UIColor.clearColor;
    host.modalPresentationStyle = UIModalPresentationOverFullScreen;
    host.view.userInteractionEnabled = YES;   // swallow touches
    host.view.accessibilityViewIsModal = YES; // keep VoiceOver focus inside

    // Build modal content
    ProgressModalView *modal = [[ProgressModalView alloc] initWithParent:vc.view
                                                                   items:items
                                                                   title:title
                                                                delegate:delegate];
    modal.translatesAutoresizingMaskIntoConstraints = NO;

    [host.view addSubview:modal];
    [NSLayoutConstraint activateConstraints:@[
        [modal.topAnchor constraintEqualToAnchor:host.view.topAnchor],
        [modal.leadingAnchor constraintEqualToAnchor:host.view.leadingAnchor],
        [modal.trailingAnchor constraintEqualToAnchor:host.view.trailingAnchor],
        [modal.bottomAnchor constraintEqualToAnchor:host.view.bottomAnchor],
    ]];

    shield.rootViewController = host;
    shield.hidden = NO;
    [shield makeKeyWindow]; // ensure it receives all events

    // Let the modal keep the window alive (strong)
    modal.shieldWindow = shield;
    modal.shieldHost = host;
    return modal;
}

- (void)dismiss {
    [UIView animateWithDuration:0.18
        animations:^{
          self.shieldHost.view.alpha = 0.0;
        }
        completion:^(__unused BOOL finished) {
          self.shieldWindow.hidden = YES;
          self.shieldWindow.rootViewController = nil;
          self.shieldHost = nil;
          self.shieldWindow = nil;
        }];
}

- (instancetype)initWithParent:(UIView *)back
                         items:(NSInteger)items
                         title:(NSString *)title
                      delegate:(id<ProgressDelegate>)delegate {
    if (self = [super initWithFrame:back.frame]) {
        _totalItems = items < 1 ? 1 : items;

        UIView *dimmer = [self createScreenBlockView];
        dimmer.tag = kDimmerTag;
        [self addSubview:dimmer];

        UIView *roundedRect = [self createGlassCardWithTitle:title];

        UIActivityIndicatorView *whirly = [self createWhirly];
        [roundedRect addSubview:whirly];
        [whirly startAnimating];

        _subLabel = [self createSubtext:roundedRect yPosition:whirly.frame.origin.y];
        [roundedRect addSubview:self.subLabel];

        _progress = [self createProgress:roundedRect items:items];
        [roundedRect addSubview:self.progress];

        roundedRect.tag = kRoundedTag;
        [self addSubview:roundedRect];

        [self createHelpText];

        UIButton *cancelButton = nil;

        if (delegate) {
            _progressDelegate = delegate;
            cancelButton = [self createCancelButton];

            [cancelButton addTarget:self
                             action:@selector(cancelButtonAction:)
                   forControlEvents:UIControlEventTouchUpInside];

            cancelButton.layer.cornerRadius = 5.0;
            cancelButton.clipsToBounds = true;

            cancelButton.tag = kCancelTag;
            [self addSubview:cancelButton];
            [self bringSubviewToFront:cancelButton];
        }

        [self installOuterConstraintsWithDimmer:dimmer
                                           card:roundedRect
                                   cancelButton:cancelButton
                                  helpContainer:self.helpContainer];

        [self punchHole];
    }

    return self;
}

- (void)installOuterConstraintsWithDimmer:(UIView *)dimmer
                                     card:(UIView *)card
                             cancelButton:(UIButton *_Nullable)button
                            helpContainer:(UIView *)help {
    dimmer.translatesAutoresizingMaskIntoConstraints = NO;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    button.translatesAutoresizingMaskIntoConstraints = NO;

    // 1) Dimmer fills the whole modal
    [NSLayoutConstraint activateConstraints:@[
        [dimmer.topAnchor constraintEqualToAnchor:self.topAnchor],
        [dimmer.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [dimmer.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [dimmer.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
    ]];

    // 2) Card centered, nudged up by half the button space
    CGFloat yOffset = -(kButtonGap + kButtonHeight) / 2.0;
    [NSLayoutConstraint activateConstraints:@[
        [card.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:yOffset],
        [card.widthAnchor constraintEqualToConstant:kActivityViewWidth],
        [card.heightAnchor constraintEqualToConstant:kActivityViewHeight],
    ]];

    // 3) Button under the card (same width as card)
    if (button) {
        [NSLayoutConstraint activateConstraints:@[
            [button.topAnchor constraintEqualToAnchor:card.bottomAnchor constant:kButtonGap],
            [button.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
            [button.widthAnchor constraintEqualToAnchor:card.widthAnchor],
            [button.heightAnchor constraintEqualToConstant:kButtonHeight],
        ]];

        [NSLayoutConstraint activateConstraints:@[
            [help.topAnchor constraintEqualToAnchor:button.bottomAnchor constant:kButtonGap],
            [help.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
            [help.widthAnchor constraintEqualToAnchor:button.widthAnchor multiplier:1.5],
            [help.heightAnchor constraintEqualToConstant:kButtonHeight * 2],
        ]];
    }
}

- (void)punchHole {
    NSMutableArray<UIView *> *views = NSMutableArray.array;

    UIView *item = [self viewWithTag:kRoundedTag];
    if (item) {
        [views addObject:item];
    };

    [self updateDimmerCutoutUsingCardRadii:[self viewWithTag:kDimmerTag]
                               aroundCards:views
                                extraInset:0.0];
}

- (void)dealloc {
    _progressDelegate = nil;
}

- (void)cancelButtonAction:(id)sender {
    UIButton *button = sender;

    button.hidden = true;

    [self.progressDelegate progressDelegateCancel];
}

- (void)updateDimmerCutoutUsingCardRadii:(UIView *)dimmer
                             aroundCards:(NSArray<UIView *> *)cards
                              extraInset:(CGFloat)inset {
    dimmer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.18];

    UIBezierPath *full = [UIBezierPath bezierPathWithRect:dimmer.bounds];
    full.usesEvenOddFillRule = YES;

    for (UIView *card in cards) {
        CGRect r = [dimmer convertRect:card.bounds fromView:card];
        r = CGRectInset(r, -inset, -inset);
        CGFloat cr = card.layer.cornerRadius;
        UIBezierPath *hole = [UIBezierPath bezierPathWithRoundedRect:r cornerRadius:cr];
        [full appendPath:hole];
    }

    CAShapeLayer *mask = (CAShapeLayer *)dimmer.layer.mask ?: [CAShapeLayer layer];
    mask.fillRule = kCAFillRuleEvenOdd;
    mask.path = full.CGPath;
    if (!dimmer.layer.mask)
        dimmer.layer.mask = mask;
}

// Keep holes aligned on rotation/size changes:
- (void)layoutSubviews {
    [super layoutSubviews];
    [self punchHole];
}

- (UIView *)createScreenBlockView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];

    view.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.6];

    view.opaque = NO;

    return view;
}

// Minimal glass/blur card
- (UIView *)createGlassCardWithTitle:(NSString *)title {
    // Container that will hold the effect view + your existing subviews
    UIView *card = [[UIView alloc] initWithFrame:CGRectZero];
    card.backgroundColor = UIColor.clearColor;
    card.layer.cornerRadius = 12.0;
    card.layer.masksToBounds = YES;

    UIVisualEffect *effect = nil;
    if (@available(iOS 26.0, *)) {
        effect = [UIGlassEffect effectWithStyle:UIGlassEffectStyleRegular];
    } else {
        effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial];
    }

    UIVisualEffectView *glass = [[UIVisualEffectView alloc] initWithEffect:effect];
    glass.frame = card.bounds;
    glass.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    glass.userInteractionEnabled = NO; // content goes on top
    [card addSubview:glass];

    // Subtle inner stroke for definition (looks nice with glass)
    CALayer *stroke = [CALayer layer];
    stroke.frame = card.bounds;
    stroke.cornerRadius = card.layer.cornerRadius;
    stroke.borderWidth = 0.75;
    stroke.borderColor = [UIColor.separatorColor colorWithAlphaComponent:0.55].CGColor;
    // stroke.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    [card.layer addSublayer:stroke];

    // Add a tint overlay *inside* the effect view’s contentView
    UIView *tintOverlay = [[UIView alloc] initWithFrame:glass.bounds];
    tintOverlay.backgroundColor = [UIColor colorWithRed:112.0 / 255.0
                                                  green:138.0 / 255.0
                                                   blue:128.0 / 255.0
                                                  alpha:0.15];
    tintOverlay.autoresizingMask =
        UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [glass.contentView addSubview:tintOverlay];

    if (title.length) {
        UILabel *titleLabel =
            [[UILabel alloc] initWithFrame:CGRectMake(10, 8, CGRectGetWidth(card.bounds) - 20, 25)];
        titleLabel.text = title;
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont monospacedDigitSystemFontOfSize:17];
        titleLabel.textColor = UIColor.labelColor;

        titleLabel.numberOfLines = 1;
        titleLabel.adjustsFontSizeToFitWidth = YES;
        titleLabel.minimumScaleFactor = 0.1;
        titleLabel.lineBreakMode = NSLineBreakByClipping;
        titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;

        titleLabel.translatesAutoresizingMaskIntoConstraints = NO;

        [card addSubview:titleLabel];

        [NSLayoutConstraint activateConstraints:@[
            [titleLabel.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:10],
            [titleLabel.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-10],
            [titleLabel.topAnchor constraintEqualToAnchor:card.topAnchor constant:8],
            [titleLabel.heightAnchor constraintEqualToConstant:25],
        ]];
    }

    return card;
}

- (UIActivityIndicatorView *)createWhirly {
    UIActivityIndicatorView *whirly = [[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];

    whirly.color = UIColor.labelColor;
    whirly.frame = CGRectMake((kActivityViewWidth - kProgressWidth) / 2,
                              (kActivityViewHeight - kProgressHeight) / 2,
                              kProgressWidth,
                              kProgressHeight);
    return whirly;
}

- (UILabel *)createSubtext:(UIView *)frontWin yPosition:(CGFloat)y {
    CGRect frame = CGRectMake(
        (kActivityViewWidth - kTextWidth) / 2,
        ((y + kProgressHeight) + (kActivityViewWidth - kBarHeight - kBarGap)) / 2 - kTextHeight / 2,
        kTextWidth,
        kTextHeight);

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

- (UIProgressView *)createProgress:(UIView *)frontWin items:(NSInteger)items {
    CGRect frame = CGRectMake((kActivityViewWidth - kBarWidth) / 2,
                              (kActivityViewHeight - kBarHeight - kBarGap),
                              kBarWidth,
                              kBarHeight);

    UIProgressView *view = [[UIProgressView alloc] initWithFrame:frame];

    view.progressViewStyle = UIProgressViewStyleDefault;
    view.progress = 0.0;

    if (items == 1) {
        view.hidden = YES;
    }

    return view;
}

- (UIButton *)createCancelButton {
    UIButtonConfiguration *cfg = [UIButtonConfiguration plainButtonConfiguration];
    cfg.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    cfg.contentInsets = NSDirectionalEdgeInsetsMake(10, 16, 10, 16);

    // Title (keep your existing attributed string, or set a normal title)
    static NSAttributedString *cancelText = nil;
    DO_ONCE(^{
      cancelText = [@"#b#RCancel" attributedStringFromMarkUpWithFont:[UIFont systemFontOfSize:20]];
    });
    cfg.attributedTitle = cancelText;

    // Make the background glassy on iOS 26, blur on older iOS
    if (!UIAccessibilityIsReduceTransparencyEnabled()) {
        UIVisualEffect *effect = nil;
        if (@available(iOS 26.0, *)) {
            effect = [UIGlassEffect effectWithStyle:UIGlassEffectStyleRegular];
        } else {
            effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial];
        }
        cfg.background.visualEffect = effect;

        cfg.background.strokeColor = [UIColor.separatorColor colorWithAlphaComponent:0.8];
        cfg.background.strokeWidth = 1.0;

    } else {
        // Opaque fallback for Reduce Transparency / High Contrast
        cfg.background.backgroundColor = [UIColor secondarySystemBackgroundColor];
        cfg.background.strokeColor = [UIColor.separatorColor colorWithAlphaComponent:0.8];
        cfg.background.strokeWidth = 1.0;
    }

    // Ensure readable title color
    cfg.baseForegroundColor = [UIColor systemRedColor]; // matches your “#R” markup; tweak if needed

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.configuration = cfg;
    btn.layer.masksToBounds = YES; // keep capsule clean
    btn.hidden = NO;
    return btn;
}
- (void)createHelpText {
    UIView *container = [[UIView alloc] initWithFrame:CGRectZero];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.backgroundColor = [UIColor.systemBackgroundColor colorWithAlphaComponent:0.75];
    container.layer.cornerRadius = 12.0;
    container.layer.masksToBounds = YES;
    container.hidden = YES;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.backgroundColor = UIColor.clearColor; // clear so container shows through
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.textColor = UIColor.redColor;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont boldMonospacedDigitSystemFontOfSize:16];
    self.helpLabel = label;

    [container addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.topAnchor constraintEqualToAnchor:container.topAnchor constant:8],
        [label.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-8],
        [label.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:8],
        [label.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-8],
    ]];

    self.helpContainer = container;
    [self addSubview:container];
}

- (UILabel *)createTitleView:(NSString *)title {
    CGRect titleFrame =
        CGRectMake((kActivityViewWidth - kTextWidth) / 2, (kBarGap), kTextWidth, kTextHeight);

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
    BOOL show = (helpText != nil && helpText.length > 0);
    self.helpContainer.hidden = !show;
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

    DEBUG_LOG_MAYBE(newProgress < self.progress.progress,
                    @"Backwards:  %f, %f",
                    newProgress,
                    self.progress.progress);

    self.progress.progress = newProgress;
}

- (void)subItemsDone:(NSInteger)subItemsDone totalSubs:(NSInteger)totalSubs;
{
    if (totalSubs == 0) {
        totalSubs = 1;
    }

    self.progress.hidden = NO;
    float newProgress = ((float)(self.itemsDone) + ((float)subItemsDone / (float)totalSubs)) /
                        (float)self.totalItems;

    DEBUG_LOG_MAYBE(newProgress < self.progress.progress,
                    @"Backwards:  %f, %f",
                    newProgress,
                    self.progress.progress);

    self.progress.progress = newProgress;
}

@end
