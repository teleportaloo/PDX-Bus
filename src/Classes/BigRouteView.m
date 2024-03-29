//
//  BigRouteView.m
//  PDX Bus
//
//  Created by Andrew Wallace on 11/26/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "BigRouteView.h"
#import "Departure.h"
#import "TriMetInfo.h"
#import "UIToolbar+Auto.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIFont+Utility.h"

@interface BigRouteView ()

@property (nonatomic, strong) UIView *textView;

@end

@implementation BigRouteView

// iOS6 methods

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)infoAction:(id)sender {
    UIAlertController *alert = [UIAlertController simpleOkWithTitle:NSLocalizedString(@"Info", @"alert title")
                                                            message:NSLocalizedString(@"This Bus line identifier screen is intended as an alternative to the large-print book provided to partially sighted travelers to let the operator know which bus they need to board.\n\nNote: the screen will not dim while this is displayed, so this will drain the battery quicker.", @"feature information")];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)createTextView {
    UILabel *label;
    
    if (self.textView != nil) {
        [self.textView removeFromSuperview];
    }
    
    CGRect rect = self.view.frame;
    
    label = [[UILabel alloc] initWithFrame:rect];
    label.font = [UIFont boldMonospacedDigitSystemFontOfSize:260];
    label.adjustsFontSizeToFitWidth = YES;
    label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    label.numberOfLines = 1;
    label.textAlignment = NSTextAlignmentCenter;
    label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    label.highlightedTextColor = [UIColor whiteColor];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:label];
    
    PtrConstRouteInfo info = [TriMetInfo infoForRoute:self.departure.route];
    
    if (info == nil) {
        label.text = self.departure.route;
    } else {
        label.text = info->short_name;
        label.textColor = [TriMetInfo cachedColor:info->html_color];
    }
    
    self.textView = label;
}

- (void)willRotateTo:(UIInterfaceOrientation)orientation {
    [self createTextView];
    
    [super willRotateTo:orientation];
}

- (void)viewWillAppear:(BOOL)animated {
    self.title = NSLocalizedString(@"Bus line identifier", @"screen title");
    [self createTextView];
    
    PtrConstRouteInfo info = [TriMetInfo infoForRoute:self.departure.route];
    
    if (info == nil) {
        self.view.backgroundColor = [UIColor redColor];
    } else {
        self.view.backgroundColor = [TriMetInfo cachedColor:info->html_bg_color];
    }
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"info", @"button text")
                                                               style:UIBarButtonItemStylePlain
                                                              target:self action:@selector(infoAction:)];
    
    self.navigationItem.rightBarButtonItem = button;
    [self.navigationController setToolbarHidden:NO animated:NO];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [super viewWillDisappear:animated];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    [toolbarItems addObject:[UIToolbar noSleepButtonWithTarget:self action:@selector(infoAction:)]];
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

@end
