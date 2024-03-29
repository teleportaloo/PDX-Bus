//
//  FlashViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 1/31/09.



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "FlashViewController.h"
#import "TorchController.h"
#import "Settings.h"
#import "UIToolbar+Auto.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIFont+Utility.h"


@interface FlashViewController () {
    int _color;
    TorchController *_torch;
}

@property (nonatomic, strong) NSTimer *flashTimer;

@end


@implementation FlashViewController

#define kColors 4

- (void)dealloc {
    if (self.flashTimer) {
        [self.flashTimer invalidate];
    }
}

- (instancetype)init {
    if ((self = [super init])) {
        if ([TorchController supported]) {
            _torch = [[TorchController alloc] init];
        }
    }
    
    return self;
}

- (void)infoAction:(id)sender {
    UIAlertController *alert = [UIAlertController simpleOkWithTitle:NSLocalizedString(@"Info", @"Alert title")
                                                            message:NSLocalizedString(@"This flashing screen is intended to be used to catch the attention of a bus operator at night.\n\nNote: the screen will not dim while this is displayed, so this will drain the battery quicker.", @"Warning text")];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)changeColor:(NSTimer *)timer {
    static dispatch_once_t onceToken;
    static NSArray *colors = nil;
    
    dispatch_once(&onceToken, ^{
        colors = @[
            [UIColor blackColor],
            [UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:1.0],
            [UIColor blackColor],
            [UIColor whiteColor]
        ];
    });
    
    self.view.backgroundColor = colors[_color];
    
    _color = (_color + 1) % kColors;
    [self.view setNeedsDisplay];
    
    if (_torch) {
        [_torch toggle];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    NSDate *date = [NSDate date];
    
    _color = 0;
#ifdef ORIGINAL_IPHONE
    NSDate *oneSecondFromNow = [date addTimeInterval:0.1];
#else
    NSDate *oneSecondFromNow = [date dateByAddingTimeInterval:0.1];
#endif
    self.flashTimer = [[NSTimer alloc] initWithFireDate:oneSecondFromNow interval:0.25 target:self selector:@selector(changeColor:) userInfo:nil repeats:YES];
    
    [[NSRunLoop currentRunLoop] addTimer:self.flashTimer forMode:NSDefaultRunLoopMode];
    self.title = NSLocalizedString(@"Flashing Light", @"Screen title");
    
    UIBarButtonItem *info = [[UIBarButtonItem alloc]
                             initWithTitle:NSLocalizedString(@"info", @"Button text")
                             style:UIBarButtonItemStylePlain
                             target:self action:@selector(infoAction:)];
    
    
    self.navigationItem.rightBarButtonItem = info;
    
    //[self.navigationController setToolbarHidden:YES animated:YES];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    
    UILabel *label;
    
#define TEXT_HEIGHT    20
#define TOOLBAR_HEIGHT 40
    
    CGRect frame = self.view.frame;
    CGRect rect = CGRectMake(frame.origin.x, frame.origin.y + frame.size.height - TEXT_HEIGHT - TOOLBAR_HEIGHT * 3, frame.size.width, TEXT_HEIGHT);
    
    label = [[UILabel alloc] initWithFrame:rect];
    label.font = [UIFont boldMonospacedDigitSystemFontOfSize:20];
    label.adjustsFontSizeToFitWidth = YES;
    label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    label.numberOfLines = 1;
    label.textAlignment = NSTextAlignmentCenter;
    label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    label.highlightedTextColor = [UIColor redColor];
    label.textColor = [UIColor redColor];
    label.backgroundColor = [UIColor clearColor];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:label];
    label.text = NSLocalizedString(@"Device sleep disabled!", @"Button warning");
    
    if (_torch) {
        [_torch on];
    }
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
    if (self.flashTimer) {
        [self.flashTimer invalidate];
        self.flashTimer = nil;
    }
    
    if (_torch) {
        [_torch off];
    }
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
                                     // Release anything that's not essential, such as cached data
}

- (void)toggleLed:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0: {
            Settings.flashLed = YES;
            break;
        }
            
        case 1: {
            Settings.flashLed = NO;
            break;
        }
    }
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    if (_torch) {
        [toolbarItems addObject:[self segBarButtonWithItems:@[NSLocalizedString(@"Flash LED", @"Short segment button text"),
                                                              NSLocalizedString(@"LED Off",   @"Short segment button text")]
                                                     action:@selector(toggleLed:)
                                              selectedIndex:Settings.flashLed ? 0 : 1]];
        [toolbarItems addObject:[UIToolbar flexSpace]];
    }
}

@end
