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
#import "DepartureTimesView.h"

#define kLightCtrlOn  (0)
#define kLightCtrlOff (1)

@implementation QrCodeReaderViewController


-(bool)torchSupported
{
    static bool checkDone = NO;
    static bool supported = NO;
    
    if (!checkDone)
    {
        Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
        if (captureDeviceClass != nil)
        {
            AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            
            if (device.hasTorch && device.hasFlash)
            {
                supported = YES;
            }
        }
        checkDone = YES;
    }
    return supported;
}

- (bool)startReading
{
    if (!_isReading)
    {
         _isReading = YES;
        
        NSError *error = nil;
        
        AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
        
        if (!input) {
            LOG_NSERROR(error);
            return NO;
        }
        
        self.captureSession = [[AVCaptureSession alloc] init];
        [self.captureSession addInput:input];
        
        AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
        [self.captureSession addOutput:captureMetadataOutput];
        
        dispatch_queue_t dispatchQueue;
        dispatchQueue = dispatch_queue_create("myQueue", NULL);
        [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
        [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
        
        self.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        [self.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [self.videoPreviewLayer setFrame:self.viewPreview.layer.bounds];
        [self.viewPreview.layer addSublayer:self.videoPreviewLayer];
        
       
        [_captureSession startRunning];
        
    }
    
    return YES;
}



-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects != nil && [metadataObjects count] > 0 && _isReading) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
           _isReading = NO;
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self stopReading];
                [[DepartureTimesView viewController] fetchTimesViaQrCodeRedirectAsync:self.backgroundTask URL:metadataObj.stringValue];
            });
        }
    }
}

- (void)backgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled
{
    if (!cancelled)
    {
        [super backgroundTaskDone:viewController cancelled:cancelled];
    }
    else
    {
        [self startReading];
    }
}

-(void)stopReading
{
    if (self.isReading)
    {
        self.isReading = NO;
        [self.captureSession stopRunning];
        self.captureSession = nil;
    
        [self.videoPreviewLayer removeFromSuperlayer];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"QR Code Reader", @"screen title");
    
    CGRect viewRect = self.middleWindowRect;
    
    self.viewPreview = [[UIView alloc] initWithFrame:viewRect];
    
    [self.view addSubview:self.viewPreview];
    
    self.view.backgroundColor = [UIColor grayColor];
    
    const CGFloat margin = 20;
    
    NSString *text = NSLocalizedString(@"Position a TriMet QR Code in front of the camera to scan it and show the arrivals.", @"QR scanner instructions");
    UIFont *font = [UIFont systemFontOfSize:20];
    
    NSStringDrawingOptions options = NSStringDrawingTruncatesLastVisibleLine |
                                            NSStringDrawingUsesLineFragmentOrigin;
    
    CGFloat width = viewRect.size.width - margin * 2;
    
    NSDictionary *attr = @{NSFontAttributeName: font};
    CGRect bounds = [text boundingRectWithSize:CGSizeMake(width, MAXFLOAT)
                                       options:options
                                    attributes:attr
                                       context:nil];
    
    CGRect labelRect = CGRectMake(margin,100, width, bounds.size.height + 20);
    
    UILabel *label = [[UILabel alloc] initWithFrame:labelRect];
    
    label.font = font;
    label.textAlignment = NSTextAlignmentCenter;
    label.highlightedTextColor = [UIColor whiteColor];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor blackColor];
    label.numberOfLines = -1;
    
    label.text = text;
    
    [self.view addSubview:label];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startReading];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self off];
    
    if (self.lightSegControl)
    {
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


- (void)on
{
    
    if (self.torchSupported) {
        
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        [device lockForConfiguration:nil];
        
        device.torchMode = AVCaptureTorchModeOn;
        device.flashMode = AVCaptureFlashModeOn;
        
        [device unlockForConfiguration];
        
    }
    
}

- (void)off
{
    if (self.torchSupported) {
        
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        [device lockForConfiguration:nil];
        
        device.torchMode = AVCaptureTorchModeOff;
        device.flashMode = AVCaptureFlashModeOff;
        
        [device unlockForConfiguration];
        
    }
}

- (void)toggleFlash:(UISegmentedControl *)ctrl
{
    if (ctrl.selectedSegmentIndex == 0)
    {
        [self on];
    }
    else
    {
        [self off];
    }
}

- (void) updateToolbarItems:(NSMutableArray *)toolbarItems
{
    [toolbarItems addObject:[[UIBarButtonItem alloc]
                              initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                              target:self action:@selector(cancel:)]];
    
    if (self.torchSupported)
    {
        self.lightSegControl = [[UISegmentedControl alloc] initWithItems:
                                      @[@"Light", @"Off"]];
        [self.lightSegControl addTarget:self action:@selector(toggleFlash:) forControlEvents:UIControlEventValueChanged];
        self.lightSegControl.selectedSegmentIndex = kLightCtrlOff;
        
        [toolbarItems addObject:[UIToolbar flexSpace]];
        
        UIBarButtonItem *segItem = [[UIBarButtonItem alloc] initWithCustomView:self.lightSegControl];
        [toolbarItems addObject:segItem];
    }
    
    
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];    
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
