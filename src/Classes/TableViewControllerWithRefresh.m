//
//  TableViewControllerWithRefresh.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/11/15.
//  Copyright © 2015 Teleportaloo. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TableViewControllerWithRefresh.h"
#import "DebugLogging.h"
#import "AlignedBarItemButton.h"



@implementation TableViewControllerWithRefresh

#define kRefreshInterval    60

@synthesize refreshButton = _refreshButton;
@synthesize lastRefresh   = _lastRefresh;
@synthesize refreshText   = _refreshText;
@synthesize refreshTimer  = _refreshTimer;


- (void)dealloc {
    [self stopTimer];
    
    self.lastRefresh    = nil;
    self.refreshButton  = nil;
    self.refreshText    = nil;
    
    [super dealloc];
}

- (instancetype)init {
    if ((self = [super init]))
    {
        _timerPaused = NO;
    }
    return self;
}


- (void) countDownAction:(NSTimer *)timer
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

- (void)setRefreshtextColor
{
    if (self.refreshText)
    {
        self.refreshText.textColor = self.navigationController.navigationBar.tintColor;
    }
}

- (void)setRefreshButtonText:(NSString*)text
{
    if (self.refreshText)
    {
        self.refreshText.text = text;
    }
    else
    {
        self.refreshButton.title = text;
    }
}

- (void)refreshAction:(id)unused
{
    [self stopTimer];
}

- (void)startTimer
{
    if ([UserPrefs sharedInstance].autoRefresh)
    {
        self.lastRefresh = [NSDate date];
        NSDate *oneSecondFromNow = [NSDate dateWithTimeIntervalSinceNow:0];
        if (self.refreshTimer)
        {
            [self.refreshTimer invalidate];
        }
        self.refreshTimer = [[[NSTimer alloc] initWithFireDate:oneSecondFromNow interval:1 target:self selector:@selector(countDownAction:) userInfo:nil repeats:YES] autorelease];
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
        
        self.refreshTimer = [[[NSTimer alloc] initWithFireDate:[NSDate date] interval:1 target:self selector:@selector(countDownAction:) userInfo:nil repeats:YES] autorelease];
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

-(void)BackgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled
{
    
    if (self.backgroundRefresh && !cancelled)
    {
        [self startTimer];
    }
    
    [super BackgroundTaskDone:viewController cancelled:cancelled];

}

-(void)backgroundTaskStarted
{
    [super backgroundTaskStarted];
    [self pauseTimer];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // add our custom refresh button as the nav bar's custom right view
    // The custom button here is to stop the button from flashing each time
    // the text is updated in iOS7.
    // if ([AlignedBarItemButton iOS7])
    {
        CGRect buttonRect = CGRectMake(0,0, 110, 30);
        
        self.refreshText = [[[UILabel alloc] initWithFrame:buttonRect] autorelease];
        self.refreshText.backgroundColor = [UIColor clearColor];
        self.refreshText.textAlignment = NSTextAlignmentRight;
        
        UIButton *button = [AlignedBarItemButton suitableButtonRight:YES];
        
        [button addTarget:self action:@selector(refreshAction:)forControlEvents:UIControlEventTouchUpInside];
        [button addSubview:self.refreshText];
        button.frame = buttonRect;
        
        self.refreshButton = [[[UIBarButtonItem alloc] initWithCustomView:button] autorelease];
        
        [self setRefreshtextColor];
        
    }
    self.navigationItem.rightBarButtonItem = self.refreshButton;

}

- (void)reloadData
{
    [super reloadData];
    
    [self setRefreshtextColor];
    
}

- (void) viewDidDisappear:(BOOL)animated
{
    DEBUG_FUNC();
    [super viewDidDisappear:animated];
    [self pauseTimer];
}


@end
