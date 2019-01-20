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


#import "TableViewControllerWithRefresh.h"
#import "DebugLogging.h"

@implementation TableViewControllerWithRefresh

#define kRefreshInterval    60

- (void)dealloc {
    [self stopTimer];
    
    
}

- (instancetype)init {
    if ((self = [super init]))
    {
        _timerPaused = NO;
    }
    return self;
}


- (void)countDownAction:(NSTimer *)timer
{
    if (self.refreshTimer !=nil && self.refreshTimer)
    {
        NSTimeInterval sinceRefresh = self.lastRefresh.timeIntervalSinceNow;
        
        // If we detect that the app was backgrounded while this timer
        // was expiring we go around one more time - this is to enable a commuter
        // bookmark time to be processed.
        
        bool updateTimeOnButton = YES;
        if (sinceRefresh <= -kRefreshInterval)
        {
            [self stopTimer];
            [self refreshAction:timer];
            [self setRefreshButtonText: NSLocalizedString(@"Refreshing", @"Refresh button text")];
            updateTimeOnButton = NO;
        }
        
        if (updateTimeOnButton)
        {
            int secs = (1+kRefreshInterval+sinceRefresh);
            
            if (secs < 0) secs = 0;
            
            [self setRefreshButtonText:[NSString stringWithFormat:NSLocalizedString(@"Refresh in %d", @"Refresh button text {number of seconds}"), secs] ];
            
            [self countDownTimer];
        }
    }
}

- (void)countDownTimer
{
    
}


- (void)setRefreshButtonText:(NSString*)text
{
    // iOS10 needs this as it will flash
    [UIView performWithoutAnimation:^{
        self.refreshButton.title = text;
        // [self.refreshButton layoutIfNeeded];
    }];
}

- (void)refreshAction:(id)unused
{
    if (!self.backgroundTask.running)
    {
        [self stopTimer];
    }
}

- (void)startTimer
{
    if ([UserPrefs sharedInstance].autoRefresh && (self.refreshFlags & kRefreshTimer))
    {
        self.lastRefresh = [NSDate date];
        NSDate *oneSecondFromNow = [NSDate dateWithTimeIntervalSinceNow:0];
        if (self.refreshTimer)
        {
            [self.refreshTimer invalidate];
        }
        self.refreshTimer = [[NSTimer alloc] initWithFireDate:oneSecondFromNow interval:1 target:self selector:@selector(countDownAction:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.refreshTimer forMode:NSDefaultRunLoopMode];
    }
}

-(void)stopTimer
{
    if (self.refreshTimer !=nil)
    {
        [self.refreshTimer invalidate];
        self.refreshTimer = nil;
        [self setRefreshButtonText:kRefreshText];
    }
}

-(void)pauseTimer
{
    if (self.refreshTimer!=nil)
    {
        [self.refreshTimer invalidate];
        self.refreshTimer = nil;
        _timerPaused = YES;
    }

}


- (void)didEnterBackground {
    [self pauseTimer];
}

- (void)unpauseTimer
{
    if ([UserPrefs sharedInstance].autoRefresh && _timerPaused)
    {
        DEBUG_LOG(@"restarting timer\n");
        
        if (self.refreshTimer)
        {
            [self.refreshTimer invalidate];
        }
        
        self.refreshTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:1 target:self selector:@selector(countDownAction:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.refreshTimer forMode:NSDefaultRunLoopMode];
        _timerPaused = NO;
        
    }
    else if ([UserPrefs sharedInstance].autoRefresh)
    {
        [self startTimer];
        _timerPaused = NO;
    }
}


- (void)didBecomeActive {
    DEBUG_FUNC();
    [self unpauseTimer];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self unpauseTimer];
    
}

-(void)backgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled
{
    if (self.backgroundRefresh && !cancelled)
    {
        [self startTimer];
    }
    
    [super backgroundTaskDone:viewController cancelled:cancelled];

}

-(void)backgroundTaskStarted
{
    [super backgroundTaskStarted];
    [self pauseTimer];
}

- (void)viewDidLoad
{
    self.disablePull = ((self.refreshFlags & kRefreshPull) == 0);
    
    [super viewDidLoad];
    
    // add our custom refresh button as the nav bar's custom right view
    // The custom button here is to stop the button from flashing each time
    // the text is updated in iOS7.
    // if ([AlignedBarItemButton iOS7])
    if ((self.refreshFlags & kRefreshButton))
    {
        self.refreshButton = [[UIBarButtonItem alloc] init];
        self.refreshButton.target = self;
        self.refreshButton.action = @selector(refreshAction:);
        
        NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
        paragraphStyle.alignment                = NSTextAlignmentRight;
        
        [self.refreshButton setTitleTextAttributes:@{
                                                     NSFontAttributeName : [UIFont fontWithName:@"Verdana" size:UIFont.labelFontSize],
                                                     NSParagraphStyleAttributeName : paragraphStyle
                                                     } forState:UIControlStateNormal];
        
        
        self.navigationItem.rightBarButtonItem = self.refreshButton;
        
        if ((self.refreshFlags & kRefreshTimer) == 0)
        {
            [self setRefreshButtonText:kRefreshText];
        }
    }
   

}

- (void)viewDidDisappear:(BOOL)animated
{
    DEBUG_FUNC();
    [super viewDidDisappear:animated];
    [self pauseTimer];
}


- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if ([UserPrefs sharedInstance].shakeToRefresh && event.type == UIEventSubtypeMotionShake && (self.refreshFlags & kRefreshShake)) {
        UIViewController * top = self.navigationController.visibleViewController;
        
        if ([top respondsToSelector:@selector(refreshAction:)])
        {
            [top performSelector:@selector(refreshAction:) withObject:nil];
        }
    }
}


@end
