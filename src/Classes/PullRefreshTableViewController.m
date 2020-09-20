//
// PullRefreshTableViewController.m
// Plancast
//
// Created by Leah Culver on 7/2/10.
// Copyright (c) 2010 Leah Culver
// Changes (c) 2011 Andrew Wallace
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

#import <QuartzCore/QuartzCore.h>
#import "PullRefreshTableViewController.h"
#import "DebugLogging.h"
#import "TintedImageCache.h"
#import "UIApplication+Compat.h"

#define REFRESH_HEADER_HEIGHT 52.0f


@implementation PullRefreshTableViewController

@synthesize textPull, textRelease, textLoading, refreshHeaderView, refreshLabel, refreshArrow, refreshSpinner;
@synthesize secondLine = _secondLine;

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self != nil) {
        [self setupStrings];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        [self setupStrings];
    }
    return self;
}


- (CGFloat)heightOffset
{
    return -[UIApplication sharedApplication].compatStatusBarFrame.size.height;
}

- (void)viewDidLoad {
    if (!self.disablePull)
    {
        [self addPullToRefreshHeader];
        
    }
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    if (!self.disablePull)
    {
        [self iOS7workaroundPromptGap];
    }
    [super viewDidAppear:animated];
}
- (void)setupStrings{
    textPull = @"Pull down to refresh...";
    textRelease = @"Release to refresh...";
    textLoading = @"Loading...";
    
    self.secondLine = @"";
}

- (CGFloat)widthNow
{
    CGRect bounds = [UIApplication sharedApplication].delegate.window.bounds;
    
    return bounds.size.width;
}

- (void)addRefreshArrow
{
    if (refreshArrow!=nil)
    {
        [refreshArrow removeFromSuperview];
    }
    
    refreshArrow = [[UIImageView alloc] initWithImage:[[TintedImageCache sharedInstance] modeAwareLightenedIcon:@"arrow.png"]];
    refreshArrow.frame = CGRectMake(floorf((REFRESH_HEADER_HEIGHT - 27) / 2),
                                    (floorf(REFRESH_HEADER_HEIGHT - 44) / 2),
                                    27, 44);
    [refreshHeaderView addSubview:refreshArrow];
}

- (void)addPullToRefreshHeader {
    
    _width = [self widthNow];
    
    refreshHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0 - REFRESH_HEADER_HEIGHT, _width, REFRESH_HEADER_HEIGHT)];
    refreshHeaderView.backgroundColor = self.table.superview.backgroundColor;
    refreshHeaderView.autoresizesSubviews = YES;
    
    refreshLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _width, REFRESH_HEADER_HEIGHT)];
    refreshLabel.backgroundColor = [UIColor clearColor];
    refreshLabel.font = [UIFont boldSystemFontOfSize:16.0];
    refreshLabel.textAlignment = NSTextAlignmentCenter;
    refreshLabel.textColor = [UIColor darkGrayColor];
    refreshLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    refreshLabel.numberOfLines = 2;
    
    self.table.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];

    [self addRefreshArrow];
    

#if TARGET_OS_MACCATALYST
    refreshSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
#else
    refreshSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
#endif
    refreshSpinner.frame = CGRectMake(floorf(floorf(REFRESH_HEADER_HEIGHT - 20) / 2), floorf((REFRESH_HEADER_HEIGHT - 20) / 2), 20, 20);
    refreshSpinner.hidesWhenStopped = YES;
    
    [refreshHeaderView addSubview:refreshLabel];
    [refreshHeaderView addSubview:refreshArrow];
    [refreshHeaderView addSubview:refreshSpinner];
    [self.table addSubview:refreshHeaderView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.disablePull)
    {
        return;
    }
    
    if (_width != [self widthNow])
    {
        [refreshHeaderView removeFromSuperview];
        [refreshLabel      removeFromSuperview];
        [refreshArrow      removeFromSuperview];
        [refreshSpinner    removeFromSuperview];
        
        
        [self addPullToRefreshHeader];
    }
    if (isLoading) return;
    isDragging = YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.disablePull)
    {
        return;
    }
    if (scrollView!=self.table)
    {
        return;
    }
    
    //DEBUG_LOGB(isLoading);
    if (isLoading) {
        // Update the content inset, good for section headers
        if (scrollView.contentOffset.y > 0)
            scrollView.contentInset = UIEdgeInsetsZero;
        else if (scrollView.contentOffset.y >= -REFRESH_HEADER_HEIGHT)
        {
            scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
            DEBUG_LOGF(scrollView.contentInset.top);
        }
    } else if (isDragging && scrollView.contentOffset.y < 0) {
        // Update the arrow direction and label
        [self.table bringSubviewToFront:refreshHeaderView];
        
        [UIView animateWithDuration:0.2 animations:^{  // default duration
            if (scrollView.contentOffset.y < -REFRESH_HEADER_HEIGHT) {
                // User is scrolling above the header
                self.refreshLabel.text = [NSString stringWithFormat:@"%@\n%@", self.textRelease, self.secondLine];
                self.refreshArrow.layer.transform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
            } else { // User is scrolling somewhere within the header
                self.refreshLabel.text = [NSString stringWithFormat:@"%@\n%@", self.textPull, self.secondLine];
                self.refreshArrow.layer.transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
            }
        } completion:^(BOOL finished){
        }];

    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (self.disablePull)
    {
        return;
    }
    
    if (scrollView!=self.table)
    {
        return;
    }
    
    if (isLoading) return;
    isDragging = NO;
    if (scrollView.contentOffset.y <= -REFRESH_HEADER_HEIGHT && scrollView == self.table) {
        // Released above the header
        [self startLoading];
    }
}

- (void)startLoading {
    isLoading = YES;
    
    
    [UIView animateWithDuration:0.3 animations:^{  // default duration
        self.table.contentInset = UIEdgeInsetsMake(REFRESH_HEADER_HEIGHT, 0, 0, 0);
        self.refreshLabel.text = [NSString stringWithFormat:@"%@\n%@", self.textLoading, self.secondLine];
        self.refreshArrow.hidden = YES;
        [self.refreshSpinner startAnimating];
    } completion:^(BOOL finished){
    }];
    
    // Refresh action!
    [self refresh];
}

- (void)stopLoading {
    isLoading = NO;
    
    // Hide the header
    [UIView animateWithDuration:0.3 animations:^{  // default duration
        self.table.contentInset = UIEdgeInsetsZero;
        self.refreshArrow.layer.transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
        
        DEBUG_LOGF(self.table.contentOffset.y);
        DEBUG_LOGF(self.table.contentInset.bottom);
        
        if (self.searchController && !self.searchController.searchBar.hidden)
        {
            self.table.contentOffset = CGPointMake(0, self.searchController.searchBar.frame.size.height);
        }
        DEBUG_LOGF(self.table.contentOffset.y);
    } completion:^(BOOL finished){
        // Reset the header
        self.refreshLabel.text = self.textPull;
        self.refreshArrow.hidden = NO;
        [self.refreshSpinner stopAnimating];
    }];
}

- (void)refresh {
    [self refreshAction:nil];
    [self performSelector:@selector(stopLoading) withObject:nil afterDelay:0.5];
}

- (void)refreshAction:(id)sender
{
    
}


- (void)updateRefreshDate:(NSDate *)date
{
    
    if (date == nil)
    {
        date = [NSDate date];
    }
    
    self.secondLine = [NSString stringWithFormat:NSLocalizedString(@"Last updated: %@", @"pull to refresh text"),
                       [NSDateFormatter localizedStringFromDate:date
                                                      dateStyle:NSDateFormatterNoStyle
                                                      timeStyle:NSDateFormatterMediumStyle]];
}


#pragma mark - <UIBarPositioningDelegate>

// Make sure NavigationBar is properly top-aligned to Status bar
- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
    if (bar == self.searchController.searchBar) {
        return UIBarPositionTopAttached;
    }
    else { // Handle other cases
        return UIBarPositionAny;
    }
}


- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *))
    {
        if (previousTraitCollection.userInterfaceStyle != self.traitCollection.userInterfaceStyle)
        {
             [self addRefreshArrow];
        }
    }
}


@end
