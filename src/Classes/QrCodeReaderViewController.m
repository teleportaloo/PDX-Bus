//
//  QrCodeReaderViewController.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/16/17.
//  Copyright © 2017 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "QrCodeReaderViewController.h"
#import "DepartureTimesViewController.h"
#import "MainQueueSync.h"
#import "RoundedTransparentRectView.h"
#import "Settings.h"
#import "TaskDispatch.h"
#import "UIColor+HTML.h"
#import "UIColor+MoreDarkMode.h"
#import "UIFont+Utility.h"

#define kLightCtrlOn (0)
#define kLightCtrlOff (1)

@interface QrCodeReaderViewController ()

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) UIView *viewPreview;
@property (nonatomic) bool isReading;
@property (nonatomic, strong) UISegmentedControl *lightSegControl;
@property (nonatomic, strong) RoundedTransparentRectView *qrCodeHighlight;
@property (nonatomic, strong) UIBarButtonItem *segButton;

@end

@implementation QrCodeReaderViewController

- (void)dealloc {
}

- (bool)torchSupported {
    static bool checkDone = NO;
    static bool supported = NO;

    if (!checkDone) {
        Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");

        if (captureDeviceClass != nil) {
            AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

            if (device.hasTorch && device.hasFlash) {
                supported = YES;
            }
        }

        checkDone = YES;
    }

    return supported;
}

- (bool)startReading {
    if (!_isReading) {
        _isReading = YES;

        NSError *error = nil;

        AVCaptureDevice *captureDevice =
            [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice
                                                                            error:&error];

        if (!input) {
            LOG_NSError(error);
            return NO;
        }

        self.captureSession = [[AVCaptureSession alloc] init];
        [self.captureSession addInput:input];

        AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
        [self.captureSession addOutput:captureMetadataOutput];

        dispatch_queue_t dispatchQueue;
        dispatchQueue = dispatch_queue_create("org.teleportaloo.pdxbus.qrcode", NULL);
        [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
        [captureMetadataOutput
            setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];

        self.videoPreviewLayer =
            [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        [self.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [self.videoPreviewLayer setFrame:self.viewPreview.layer.bounds];
        [self.viewPreview.layer addSublayer:self.videoPreviewLayer];

        WORKER_TASK(^{
          [self->_captureSession startRunning];
        });
    }

    return YES;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
    didOutputMetadataObjects:(NSArray *)metadataObjects
              fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects != nil && [metadataObjects count] > 0 && _isReading) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];

        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            _isReading = NO;
            dispatch_sync(dispatch_get_main_queue(), ^{
              AVMetadataObject *displayObj =
                  [self.videoPreviewLayer transformedMetadataObjectForMetadataObject:metadataObj];
              self.qrCodeHighlight.frame = displayObj.bounds;
              [self.qrCodeHighlight setNeedsDisplay];

              [self stopReading];
              [[DepartureTimesViewController viewController]
                  fetchTimesViaQrCodeRedirectAsync:self.backgroundTask
                                               URL:metadataObj.stringValue];
            });
        }
    }
}

- (void)backgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled {
    self.qrCodeHighlight.frame = CGRectNull;
    if (!cancelled) {
        [super backgroundTaskDone:viewController cancelled:cancelled];
    } else {
        [self startReading];
    }
}

- (void)stopReading {
    if (self.isReading) {
        self.isReading = NO;
        [self.captureSession stopRunning];
        self.captureSession = nil;

        [self.videoPreviewLayer removeFromSuperlayer];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = NSLocalizedString(@"QR Code Reader", @"screen title");

    // If you want the content behind the bottom toolbar
    self.edgesForExtendedLayout = UIRectEdgeBottom; // underlap bottom
    self.extendedLayoutIncludesOpaqueBars = YES;    // even if toolbar is opaque
    self.navigationController.toolbarHidden = NO;   // show toolbar

    // Container view that will sit UNDER the toolbar (full-bleed)
    self.viewPreview = [[UIView alloc] initWithFrame:CGRectZero];
    self.viewPreview.translatesAutoresizingMaskIntoConstraints = NO;
    self.viewPreview.backgroundColor = [UIColor blackColor]; // optional
    [self.view addSubview:self.viewPreview];

    // Pin to controller VIEW edges (NOT safe area) so it runs under the bar
    [NSLayoutConstraint activateConstraints:@[
        [self.viewPreview.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.viewPreview.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.viewPreview.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.viewPreview.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    self.view.backgroundColor = [UIColor grayColor];

    const CGFloat margin = 20;

    NSString *text = NSLocalizedString(@"Position a TriMet QR code in front of the camera "
                                       @"to scan it and show the departures.",
                                       @"QR scanner instructions");
    UIFont *font = [UIFont monospacedDigitSystemFontOfSize:20];

    NSStringDrawingOptions options =
        NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin;

    CGFloat width = self.navigationController.view.frame.size.width - margin * 2;

    NSDictionary *attr = @{NSFontAttributeName : font};
    CGRect bounds = [text boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                       options:options
                                    attributes:attr
                                       context:nil];

    CGRect labelRect = CGRectMake(margin, 100, width, bounds.size.height + 20);

    UILabel *label = [[UILabel alloc] initWithFrame:labelRect];

    label.layer.masksToBounds = true;
    label.layer.cornerRadius = 10;

    label.font = font;
    label.textAlignment = NSTextAlignmentCenter;
    label.highlightedTextColor = [UIColor whiteColor];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor blackColor];
    label.numberOfLines = -1;

    label.text = text;

    [self.view addSubview:label];

    RoundedTransparentRectView *view = [[RoundedTransparentRectView alloc] init];

    view.backgroundColor = [UIColor clearColor];

    view.color = [HTML_COLOR(Settings.toolbarColors) colorWithAlphaComponent:0.75];

    self.qrCodeHighlight = view;

    [self.view addSubview:self.qrCodeHighlight];
}

- (void)handleChangeInUserSettingsOnMainThread:(NSNotification *)notfication {
    [super handleChangeInUserSettingsOnMainThread:notfication];
    self.qrCodeHighlight.color = [HTML_COLOR(Settings.toolbarColors) colorWithAlphaComponent:0.75];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startReading];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self off];

    if (self.lightSegControl) {
        self.lightSegControl.selectedSegmentIndex = kLightCtrlOff;
    }

    [self stopReading];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)on {
    if (self.torchSupported) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

        [device lockForConfiguration:nil];

        device.torchMode = AVCaptureTorchModeOn;
        // device.flashMode = AVCaptureFlashModeOn;

        [device unlockForConfiguration];
    }
}

- (void)off {
    if (self.torchSupported) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

        [device lockForConfiguration:nil];

        device.torchMode = AVCaptureTorchModeOff;
        // device.flashMode = AVCaptureFlashModeOff;

        [device unlockForConfiguration];
    }
}

- (void)toggleFlash:(UISegmentedControl *)ctrl {
    if (ctrl.selectedSegmentIndex == 0) {
        [self on];
    } else {
        [self off];
    }
}

- (void)updateToolbarMainThread {
    if (self.segButton == nil) {
        self.segButton = [self segBarButtonWithItems:@[ @"Light", @"Off" ]
                                              action:@selector(toggleFlash:)
                                       selectedIndex:kLightCtrlOff];
    }
}

- (void)updateToolbarItems:(NSMutableArray<UIBarButtonItem *> *)toolbarItems {
    [toolbarItems
        addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                target:self
                                                                action:@selector(cancel:)]];

    if (self.torchSupported) {
        self.lightSegControl = self.segButton.customView;
        [toolbarItems addObject:[UIBarButtonItem flexSpace]];
        [toolbarItems addObject:self.segButton];
    }

    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

/*
 #pragma mark - Navigation

 // In a storyboard-based application, you will often want to do a little
 preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
