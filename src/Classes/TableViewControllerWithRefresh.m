//
//  TableViewControllerWithRefresh.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/11/15.
//  Copyright © 2015 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "TableViewControllerWithRefresh.h"
#import "DebugLogging.h"
#import "UIFont+Utility.h"

@interface TableViewControllerWithRefresh <FilteredItemType>() {
    bool _timerPaused;
}

@property(nonatomic, strong) NSTimer *refreshTimer;
@property(nonatomic, strong) NSDate *lastRefresh;
@property(nonatomic, strong) UIBarButtonItem *refreshButton;

@end

@implementation TableViewControllerWithRefresh

#define kRefreshInterval 60

- (instancetype)init {
    if ((self = [super init])) {
        _timerPaused = NO;
    }
    return self;
}

- (void)dealloc {
    [self stopTimer];
}

- (void)countDownAction:(NSTimer *)timer {
    if (self.lastRefresh == nil) {
        [self stopTimer];
        return;
    }
    NSTimeInterval sinceRefresh = self.lastRefresh.timeIntervalSinceNow;

    // If we detect that the app was backgrounded while this timer
    // was expiring we go around one more time - this is to enable a
    // commuter bookmark time to be processed.

    bool updateTimeOnButton = YES;

    if (sinceRefresh <= -(NSTimeInterval)kRefreshInterval) {
        [self stopTimer];
        [self refreshAction:timer];
        [self setRefreshButtonText:NSLocalizedString(@"Refreshing",
                                                     @"Refresh button text")];
        updateTimeOnButton = NO;
    }

    if (updateTimeOnButton) {
        int secs = (1 + kRefreshInterval + sinceRefresh);

        if (secs < 0) {
            secs = 0;
        }

        [self setRefreshButtonText:
                  [NSString stringWithFormat:
                                NSLocalizedString(
                                    @"Refresh in %d",
                                    @"Refresh button text {number of seconds}"),
                                secs]];

        [self countDownTimer];
    }
}

- (void)countDownTimer {
}

- (void)setRefreshButtonText:(NSString *)text {
    // iOS10 needs this as it will flash
    [UIView performWithoutAnimation:^{
      self.refreshButton.title = text;
    }];
}

- (void)refreshAction:(id)unused {
    if (!self.backgroundTask.running) {
        [self stopTimer];
    }
}

- (void)startTimer {
    if (Settings.autoRefresh && (self.refreshFlags & kRefreshTimer)) {
        self.lastRefresh = [NSDate date];
        [self oneSecondTimer];
    }
}

- (void)oneSecondTimer {
    // Stop any existing timer (idempotent)
    NSTimer *old = self.refreshTimer;
    self.refreshTimer = nil; // drop property first so the block’s identity
                             // check works even if old fires once more
    [old invalidate];

    __weak __typeof(self) weakSelf = self;

    NSTimer *t = [NSTimer
        scheduledTimerWithTimeInterval:1.0
                               repeats:YES
                                 block:^(__kindof NSTimer *_Nonnull timer) {
                                   DEBUG_LOG_description(timer);
                                   __strong __typeof(self) strongSelf =
                                       weakSelf;
                                   if (!strongSelf) {
                                       [timer invalidate];
                                       DEBUG_LOG(@"Timer with no target");
                                       return;
                                   }

                                   // If this isn't the current timer (e.g., an
                                   // older one firing), quietly kill it.
                                   if (timer != strongSelf.refreshTimer) {
                                       [timer invalidate];
                                       DEBUG_LOG(@"Rogue timer");
                                       return;
                                   }

                                   [strongSelf countDownAction:timer];
                                 }];

    [[NSRunLoop mainRunLoop] addTimer:t forMode:NSDefaultRunLoopMode];

    t.tolerance = 0.1;

    self.refreshTimer = t;

    DEBUG_LOG_description(self.refreshTimer);
}

- (void)stopTimer {
    if (self.refreshTimer != nil) {
        [self.refreshTimer invalidate];
        self.refreshTimer = nil;
        [self setRefreshButtonText:kRefreshText];
        self.lastRefresh = nil;
    }
}

- (void)pauseTimer {
    if (self.refreshTimer != nil) {
        [self.refreshTimer invalidate];
        self.refreshTimer = nil;
        _timerPaused = YES;
    }
}

- (void)didEnterBackground {
    [self pauseTimer];
    [super didEnterBackground];
}

- (void)unpauseTimer {
    if (Settings.autoRefresh && _timerPaused) {
        DEBUG_LOG(@"restarting timer\n");
        [self oneSecondTimer];
        _timerPaused = NO;
    } else if (Settings.autoRefresh) {
        [self startTimer];
        _timerPaused = NO;
    }
}

- (void)didBecomeActive {
    DEBUG_FUNC();
    [self unpauseTimer];
    [super didBecomeActive];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self unpauseTimer];
}

- (void)backgroundTaskDone:(UIViewController *)viewController
                 cancelled:(bool)cancelled {
    if (self.backgroundRefresh && !cancelled) {
        [self startTimer];
    }

    [super backgroundTaskDone:viewController cancelled:cancelled];
}

- (void)backgroundTaskStarted {
    [super backgroundTaskStarted];
    [self pauseTimer];
}

- (void)viewDidLoad {
    self.disablePull = ((self.refreshFlags & kRefreshPull) == 0);

    [super viewDidLoad];

    // add our custom refresh button as the nav bar's custom right view
    // The custom button here is to stop the button from flashing each time
    // the text is updated in iOS7.
    // if ([AlignedBarItemButton iOS7])
    if ((self.refreshFlags & kRefreshButton)) {
        self.refreshButton = [[UIBarButtonItem alloc] init];
        self.refreshButton.target = self;
        self.refreshButton.action = @selector(refreshAction:);

        NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
        paragraphStyle.alignment = NSTextAlignmentRight;

        [self.refreshButton setTitleTextAttributes:@{
            NSFontAttributeName :
                [UIFont monospacedDigitSystemFontOfSize:UIFont.labelFontSize],
            NSParagraphStyleAttributeName : paragraphStyle
        }
                                          forState:UIControlStateNormal];

        self.navigationItem.rightBarButtonItem = self.refreshButton;

        if ((self.refreshFlags & kRefreshTimer) == 0) {
            [self setRefreshButtonText:kRefreshText];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    DEBUG_FUNC();
    [super viewDidDisappear:animated];
    [self pauseTimer];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (event.subtype == UIEventSubtypeMotionShake &&
        (self.refreshFlags & kRefreshShake)) {
        UIViewController *top = self.navigationController.visibleViewController;

        if ([top respondsToSelector:@selector(refreshAction:)]) {
            [top performSelector:@selector(refreshAction:) withObject:nil];
        }
    }
}

@end
