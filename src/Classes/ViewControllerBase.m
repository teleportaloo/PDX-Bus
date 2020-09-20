//
//  ViewControllerBase.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/21/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "ViewControllerBase.h"
#import "FindByLocationView.h"
#import "FlashViewController.h"
#import "WebViewController.h"
#import "NetworkTestView.h"
#import <Social/Social.h>
#import "OpenInChromeController.h"
#import "Settings.h"
#import "MemoryCaches.h"
#import "PDXBusAppDelegate+Methods.h"
#import "InterfaceOrientation.h"
#import "SafariServices/SafariServices.h"
#import "RootViewController.h"
#import "WatchAppContext.h"
#import "TriMetInfo.h"
#import "Detour+iOSUI.h"
#import "TripPlannerSummaryView.h"
#import "MapViewController.h"
#import "DetourLocation+iOSUI.h"
#import "MapViewWithDetourStops.h"
#import "NSString+Helper.h"
#import "TintedImageCache.h"
#import "DepartureTimesView.h"
#import "Icons.h"
#import "DirectionView.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIApplication+Compat.h"
#import "DetoursView.h"

@implementation UINavigationController (Rotation_IOS6)

- (BOOL)shouldAutorotate {
    return self.viewControllers.lastObject.shouldAutorotate;
}

- (NSUInteger)supportedInterfaceOrientations {
    return self.viewControllers.lastObject.supportedInterfaceOrientations;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return self.viewControllers.lastObject.preferredInterfaceOrientationForPresentation;
}

@end

@interface ViewControllerBase () {
    UIFont *_basicFont;
    UIFont *_paragraphFont;
}

@end

@implementation ViewControllerBase

@dynamic basicFont;

+ (instancetype)viewController {
    return [[[self class] alloc] init];
}

- (void)dealloc {
    //
    // There is a weak reference to self in the background task - it must
    // be removed if we are dealloc'd.
    //
    if (self.backgroundTask) {
        self.backgroundTask.callbackComplete = nil;
    }
}

- (void)setTheme {
    int color = Settings.toolbarColors;
    bool dark = NO;
    
    if (@available(iOS 13.0, *)) {
        if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            dark = YES;
        }
    }
    
    if (color == 0xFFFFFF || dark) {
        self.navigationController.toolbar.barTintColor = nil;
        self.navigationController.navigationBar.barTintColor = nil;
        self.navigationController.toolbar.tintColor = nil;
        self.navigationController.navigationBar.tintColor = nil;
    } else {
        self.navigationController.toolbar.barTintColor = HTML_COLOR(color);
        self.navigationController.navigationBar.barTintColor = HTML_COLOR(color);
        self.navigationController.toolbar.tintColor = [UIColor whiteColor];
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    }
}

- (bool)initMembers {
    if (self.backgroundTask == nil) {
        _userState = UserState.sharedInstance;
        self.backgroundTask = [BackgroundTaskContainer create:self];
        return true;
    }
    
    return false;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self initMembers];
    }
    
    return self;
}

- (instancetype)init {
    if ((self = [super init])) {
        [self initMembers];
    }
    
    return self;
}

- (void)backToRootButtons:(NSMutableArray *)toolbarItems {
    [toolbarItems addObject:[self doneButton]];
    [toolbarItems addObject:[UIToolbar flexSpace]];
}

- (void)updateToolbar {
    NSMutableArray *toolbarItems = [NSMutableArray array];
    
    [self backToRootButtons:toolbarItems];
    
    [self updateToolbarItems:toolbarItems];
    
    
    [self setToolbarItems:toolbarItems animated:NO];
}

#pragma mark Overridden View Methods

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    [super loadView];
    
    [self.navigationController setToolbarHidden:NO animated:NO];
    
    [self setTheme];
    
    [self updateToolbar];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    //    [self.view bringSubviewToFront:self.toolbar];
    
    /*
     if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
     {
     [self setEdgesForExtendedLayout:UIRectEdgeNone];
     self.extendedLayoutIncludesOpaqueBars = NO;
     }
     */
}

// iOS6 methods

- (BOOL)shouldAutorotate {
    if (self.backgroundTask.running) {
        return NO;
    }
    
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    CGRect bounds = [UIScreen mainScreen].bounds;
    
    // Small devices do not need to orient
    if (bounds.size.width <= MaxiPhoneWidth) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    /*
     if (self.backgroundTask.backgroundThread !=nil)
     {
     return ;
     }
     */
    
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] compatStatusBarOrientation];
        
        [self rotatedTo:orientation];
    }           completion:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
    }];
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark View helper methods

- (void)rotatedTo:(UIInterfaceOrientation)orientation {
    if (!self.backgroundTask.running) {
        [self reloadData];
    }
}

- (void)reloadData {
    _basicFont = nil;
    _paragraphFont = nil;
}

- (ScreenInfo)screenInfo {
    ScreenInfo res;
    
    CGRect bounds = [UIApplication sharedApplication].delegate.window.bounds;
    
    res.appWinWidth = bounds.size.width;
    
    CGRect deviceBounds = [UIScreen mainScreen].bounds;
    
    UIInterfaceOrientation orientation = [InterfaceOrientation getInterfaceOrientation:self];
    
    if (bounds.size.width < deviceBounds.size.width) {
        orientation = UIInterfaceOrientationPortrait;
    }
    
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationUnknown:
            
            if (bounds.size.width <= WidthiPhone) {
                res.screenWidth = WidthiPhone;
            } else if (bounds.size.width <= WidthiPhone6) {
                res.screenWidth = WidthiPhone6;
            } else if (bounds.size.width <= WidthiPhone6Plus) {
                res.screenWidth = WidthiPhone6Plus;
            } else if (bounds.size.width <= WidthBigVariable) {
                res.screenWidth = WidthBigVariable;
            } else {
                res.screenWidth = WidthBigVariable;
            }
            
            break;
            
        case    UIInterfaceOrientationLandscapeLeft:
        case    UIInterfaceOrientationLandscapeRight:
            
            if (bounds.size.width <= WidthiPadWide) {
                res.screenWidth = WidthiPadWide;
            } else {
                res.screenWidth = WidthBigVariable;
            }
            
            break;
            
        default:
            res.screenWidth = WidthiPadWide;
    }
    
    return res;
}

- (CGFloat)heightOffset {
    return 0.0;
}

- (CGRect)middleWindowRect {
    CGRect tableViewRect;
    
    tableViewRect.size.width = self.navigationController.view.frame.size.width;
    
    // DEBUG_LOGR([UIScreen mainScreen].applicationFrame);
    DEBUG_LOGR([UIScreen mainScreen].bounds);
    DEBUG_LOGR(UIApplication.firstKeyWindow.frame);
    DEBUG_LOGR([UIApplication sharedApplication].compatStatusBarFrame);
    
    tableViewRect.size.height = UIApplication.compatApplicationFrame.size.height - [self heightOffset];
    tableViewRect.origin.x = 0;
    tableViewRect.origin.y = 0;
    
    DEBUG_LOGR(tableViewRect);
    return tableViewRect;
}

- (UIView *)clearView {
    UIView *backView = [[UIView alloc] initWithFrame:CGRectZero];
    
    backView.backgroundColor = [UIColor clearColor];
    return backView;
}


#pragma mark Toolbar methods

- (UIBarButtonItem *)doneButton {
    if (self.stopIdCallback != nil && (self.stopIdCallback.controller != nil || [self forceRedoButton])) {
        return [UIToolbar redoButtonWithTarget:self action:@selector(backButton:)];
    } else {
        return [UIToolbar doneButtonWithTarget:self action:@selector(backButton:)];
    }
}

- (bool)forceRedoButton {
    return false;
}



- (void)appendXmlData:(NSMutableData *)buffer {
    if (self.xml) {
        for (TriMetXML *xml in self.xml) {
            if (xml.rawData && xml.fullQuery) {
                [xml appendQueryAndData:buffer];
            }
        }
    }
}

- (void)didEnterBackground {
    if (self.backgroundTask) {
        [self.backgroundTask taskCancel];
        [self.backgroundTask.progressModal removeFromSuperview];
        self.backgroundTask.progressModal = nil;
    }
    
    ;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)xmlAction:(UIBarButtonItem *)sender {
    // We replace some items in the XML to hide it or to make the reader
    // happy when concatonating.  This was learnt by trial and error!
    // uncrustify-off
    NSDictionary *replacements = @{
        [TriMetXML appId]   : @"TRIMET_APP_ID",                                 // hide APP ID
        @"<?xml"            : @"<!--",                                          // XML encoding gets in the way
        @"?>"               : @"-->",
        @"<--?xml"          : @"<!--",                                          // XML encoding gets in the way
        @"?-->"             : @"-->",
        @"<body"            : @"<wasbody",                                      // This keyword gets dropped
        @"body>"            : @"wasbody>"
    };
    // uncrustify-on
    
    NSMutableData *buffer = [[NSMutableData alloc] init];
    
    [self appendXmlData:buffer];
    
    NSMutableString *redactedData = [[NSMutableString alloc] initWithBytes:buffer.bytes
                                                                    length:buffer.length
                                                                  encoding:NSUTF8StringEncoding];
    
    
    [replacements enumerateKeysAndObjectsUsingBlock: ^void (NSString *key, NSString *replacement, BOOL *stop)
     {
        [redactedData replaceOccurrencesOfString:key
                                      withString:replacement
                                         options:NSCaseInsensitiveSearch
                                           range:NSMakeRange(0, redactedData.length)];
    }];
    
    
    [redactedData insertString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><root>" atIndex:0];
    [redactedData appendString:@"</root>"];
    
    int viewer = Settings.xmlViewer;
    
    if (viewer == 1) {  // Share
        NSURL *docs = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        
        NSString *path = [docs.path stringByAppendingPathComponent:@"PDXBus Debug Data.xml"];
        [redactedData writeToFile:path atomically:YES
                         encoding:NSUTF8StringEncoding error:nil];
        
        NSArray *activities = @[ [NSURL fileURLWithPath:path] ];
        
        UIActivityViewController *activityViewControntroller = [[UIActivityViewController alloc] initWithActivityItems:activities applicationActivities:nil];
        activityViewControntroller.excludedActivityTypes = @[];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIView *source =  (UIView *)[sender valueForKey:@"view"];
            
            if (source == nil)
            {
                source = self.view;
            }
            
            activityViewControntroller.popoverPresentationController.sourceView = source;
            activityViewControntroller.popoverPresentationController.sourceRect = CGRectMake(source.bounds.size.width / 2, source.bounds.size.height / 2, 0, 0);
        }
    
        
        [self presentViewController:activityViewControntroller animated:true completion:nil];
    } else {
        [redactedData replaceOccurrencesOfString:@"\\"
                                      withString:@"\\\\"
                                         options:NSCaseInsensitiveSearch
                                           range:NSMakeRange(0, redactedData.length)];
        
        NSDictionary *replacements2 = @{
            // uncrustify-off
            @"\"": @"\\\"",
            @"\n": @" ",
            @"\r": @" ",
            @"'" : @"\'"
            // uncrustify-on
        };
        
        
        [replacements2 enumerateKeysAndObjectsUsingBlock: ^void (NSString *key, NSString *replacement, BOOL *stop)
         {
            [redactedData replaceOccurrencesOfString:key
                                          withString:replacement
                                             options:NSCaseInsensitiveSearch
                                               range:NSMakeRange(0, redactedData.length)];
        }];
        
        WebViewController *web = [WebViewController viewController];
        
        if (viewer == 2) {
            [web setURLmobile:@"https://www.freeformatter.com/xml-formatter.html" full:nil];
            web.javsScriptCommand = [NSString stringWithFormat:@"document.getElementById('xmlString').value=\"%@\"; document.forms[0].submit()", redactedData];
        } else if (viewer == 3) {
            [web setURLmobile:@"https://www.samltool.com/prettyprint.php" full:nil];
            web.javsScriptCommand = [NSString stringWithFormat:@"document.getElementById('xml').value=\"%@\"; document.getElementById('pretty_print').submit()", redactedData];
        }
        
        DEBUG_LOGS(web.urlToDisplay);
        DEBUG_LOGS(web.javsScriptCommand);
        [self.navigationController pushViewController:web animated:YES];
    }
}

- (UIBarButtonItem *)debugXmlButton {
    // create the system-defined "OK or Done" button
    UIBarButtonItem *xmlButton = [[UIBarButtonItem alloc]
                                  initWithImage:[Icons getToolbarIcon:kIconXml]
                                  style:UIBarButtonItemStylePlain
                                  target:self action:@selector(xmlAction:)];
    
    xmlButton.style = UIBarButtonItemStylePlain;
    xmlButton.accessibilityLabel = @"Show XML";
    
    TOOLBAR_PLACEHOLDER(xmlButton, @"XML");
    
    return xmlButton;
}

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    [self maybeAddFlashButtonWithSpace:(toolbarItems.count == 0) buttons:toolbarItems big:NO];
}

- (void)updateToolbarItemsWithXml:(NSMutableArray *)toolbarItems {
    if (Settings.debugXML) {
        [toolbarItems addObject:[self debugXmlButton]];
        [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
    } else {
        [self maybeAddFlashButtonWithSpace:NO buttons:toolbarItems big:NO];
    }
}

- (void)backButton:(id)sender {
    if (self.stopIdCallback != nil && self.stopIdCallback.controller != nil) {
        [self.navigationController popToViewController:self.stopIdCallback.controller animated:YES];
    } else {
        [ self.navigationController popToRootViewControllerAnimated:YES];
    }
}






- (void)showRouteSchedule:(NSString *)route {
    if ([[TriMetInfo streetcarRoutes] containsObject:route]) {
        [WebViewController displayPage:[NSString stringWithFormat:@"https://portlandstreetcar.org"]
                                  full:nil
                             navigator:self.navigationController
                        itemToDeselect:nil
                              whenDone:self.callbackWhenDone];
    } else {
        NSMutableString *padding = [NSMutableString string];
        
        [self padRoute:route padding:&padding];
        
        
        [WebViewController displayPage:[NSString stringWithFormat:@"https://www.trimet.org/schedules/r%@.htm", padding]
                                  full:nil
                             navigator:self.navigationController
                        itemToDeselect:nil
                              whenDone:self.callbackWhenDone];
    }
}

#pragma mark Common actions

- (bool)fullScreen {
#if !TARGET_OS_MACCATALYST
    CGRect myBounds = [UIApplication sharedApplication].delegate.window.bounds;
    CGRect fullScreen = [UIScreen mainScreen].bounds;
    
    if (fullScreen.size.width == myBounds.size.width) {
        return YES;
    }
    
    return NO;
#else
    return YES;
#endif
}

- (bool)videoCaptureSupported {
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    
    if (self.fullScreen && captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if (device == nil) {
            return NO;
        }
        
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        switch (authStatus) {
            case AVAuthorizationStatusAuthorized:
            case AVAuthorizationStatusNotDetermined:
                return YES;
                
            case AVAuthorizationStatusDenied:
            case AVAuthorizationStatusRestricted:
                return NO;
        }
    }
    
    return NO;
}

- (void)padRoute:(NSString *)route padding:(NSMutableString **)padding {
    while (route.length + (*padding).length < 3) {
        [*padding appendString: @"0"];
    }
    [*padding appendString: route];
}

- (void)networkTips:(NSData *)htmlError networkError:(NSString *)networkError {
    if (htmlError) {
        WebViewController *errorScreen = [WebViewController viewController];
        [errorScreen setRawData:htmlError title:NSLocalizedString(@"Error Message", @"error")];
        [errorScreen displayPage:self.navigationController animated:YES itemToDeselect:nil];
    } else {
        NetworkTestView *networkTest = [NetworkTestView viewController];
        networkTest.networkErrorFromQuery = networkError;
        [networkTest fetchNetworkStatusAsync:self.backgroundTask backgroundRefresh:NO];
    }
}

#pragma mark Text Manipulation Methods

- (UILabel *)create_UITextView:(UIColor *)backgroundColor font:(UIFont *)font; {
    CGRect frame = CGRectMake(0.0, 0.0, 100.0, 200.0);
    
    
    UILabel *textView = [[UILabel alloc] initWithFrame:frame];
    
    textView.textColor = [UIColor modeAwareText];
    textView.font = font; // ;
    
    //    textView.delegate = self;
    //    textView.editable = NO;
    if (backgroundColor == nil) {
        textView.backgroundColor = [UIColor clearColor];
    } else {
        textView.backgroundColor = backgroundColor;
    }
    
    textView.lineBreakMode = NSLineBreakByWordWrapping;
    textView.adjustsFontSizeToFitWidth = YES;
    textView.numberOfLines = 0;
    
    // note: for UITextView, if you don't like autocompletion while typing use:
    // myTextView.autocorrectionType = UITextAutocorrectionTypeNo;
    
    return textView;
}

- (UIFont *)systemFontBold:(bool)bold size:(CGFloat)size {
    if (bold) {
        return [UIFont boldSystemFontOfSize:size];
    }
    
    return [UIFont systemFontOfSize:size];
}

- (UIFont *)paragraphFont {
    if (_paragraphFont == nil) {
        if (SMALL_SCREEN) {
            if (self.screenInfo.screenWidth >= WidthiPhone6) {
                _paragraphFont = [UIFont systemFontOfSize:16.0];
            } else {
                _paragraphFont = [UIFont systemFontOfSize:14.0];
            }
        } else {
            _paragraphFont = [UIFont systemFontOfSize:22.0];
        }
    }
    
    return _paragraphFont;
}

- (UIFont *)basicFont {
    if (_basicFont == nil) {
        if (SMALL_SCREEN) {
            if (self.screenInfo.screenWidth >= WidthiPhone6) {
                _basicFont = [self systemFontBold:NO size:20.0];
            } else {
                _basicFont = [self systemFontBold:NO size:18.0];
            }
        } else {
            _basicFont = [self systemFontBold:NO size:22.0];
        }
    }
    
    return _basicFont;
}

#pragma mark Background Task methods

- (void)backgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled {
    if (!cancelled) {
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (UIInterfaceOrientation)backgroundTaskOrientation {
    return [InterfaceOrientation getInterfaceOrientation:self];
}

#pragma mark Standard Object methods


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    
    if (self.viewLoaded && self.view.window == nil) {
        self.view = nil;
    }
    
    // Release any cached data, images, etc that aren't in use.
    [MemoryCaches memoryWarning];
    
    [super didReceiveMemoryWarning];
}

- (bool)canTweet {
    Class messageClass = (NSClassFromString(@"TWTweetComposeViewController"));
    
    if (messageClass != nil) {
        return YES;
        
        // if ([TWTweetComposeViewController canSendTweet]) {
        //    return YES;
        //}
    }
    
    return NO;
}

- (void)tweetAt:(NSString *)twitterUser {
    NSString *twitter = [NSString stringWithFormat:@"twitter:"];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:twitter]]) {
        NSString *twitter = [NSString stringWithFormat:@"twitter://user?screen_name=%@", twitterUser];
        
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:twitter]]) {
            [[UIApplication sharedApplication] compatOpenURL:[NSURL URLWithString:twitter]];
        }
    } else {
        NSString *twitter = [NSString stringWithFormat:@"https://mobile.twitter.com/%@", twitterUser];
        [self openBrowserFrom:self path:twitter];
    }
}

- (void)triMetTweetFrom:(UIView *)view {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"TriMet on Twitter", @"alert title")
                                                                   message:NSLocalizedString(@"Which twitter account do you need?", @"alert message")
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"@TriMetAlerts - Distruption and Alert Info", @"alert item")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        [self tweetAt:@"trimetalerts"];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"@TriMetHelp - Rider Support", @"alert item")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        [self tweetAt:@"trimethelp"];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"@TriMet - General Info", @"alert item")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        [self tweetAt:@"trimet"];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"alert item")
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
        [self clearSelection];
    }]];
    
    
    alert.popoverPresentationController.sourceView = view;
    alert.popoverPresentationController.sourceRect = CGRectMake(0, 0, view.frame.size.width, view.frame.size.height);
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)clearSelection {
}

- (UIViewController *)callbackWhenDone {
    if (self.stopIdCallback) {
        return self.stopIdCallback.controller;
    }
    
    return nil;
}

- (bool)openBrowserFrom:(UIViewController *)view path:(NSString *)path {
    if (Settings.useChrome && [ OpenInChromeController sharedInstance].chromeInstalled) {
        if ([[OpenInChromeController sharedInstance] openInChrome:[NSURL URLWithString:path]
                                                  withCallbackURL:[NSURL URLWithString:@"pdxbus:"]
                                                     createNewTab:NO]) {
            return YES;
        }
    }
    
    return [self openSafariFrom:self path:path];
}

- (bool)openSafariFrom:(UIViewController *)view path:(NSString *)path {
    Class safariClass = (NSClassFromString(@"SFSafariViewController"));
    
    NSURL *url = [NSURL URLWithString:path];
    
    if (safariClass != nil) {
        SFSafariViewController *vc = [[SFSafariViewController alloc] initWithURL:url];
        
        // vc.delegate = self
        [view presentViewController:vc animated:YES completion:^{}];
        return TRUE;
    } else {
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] compatOpenURL:url];
            return TRUE;
        }
    }
    
    return FALSE;
}

- (void)facebookWithId:(NSString *)fbid path:(NSString *)fbpath {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:fbid]]) {
        [[UIApplication sharedApplication] compatOpenURL:[NSURL URLWithString:fbid]];
    } else {
        [self openBrowserFrom:self path:fbpath];
    }
    
    [self clearSelection];
}

- (void)facebookTriMet {
    static NSString *fbid = @"fb://profile/270344585472";
    static NSString *fbpath = @"https://m.facebook.com/TriMet";
    
    [self facebookWithId:fbid path:fbpath];
}

- (void)facebook {
    static NSString *fbid = @"fb://profile/218101161593";
    static NSString *fbpath = @"https://m.facebook.com/PDXBus";
    
    [self facebookWithId:fbid path:fbpath];
}

- (void)favesChanged {
    _userState.favesChanged = YES;
    [self updateWatch];
}

- (void)updateWatch {
    RootViewController *root = PDXBusAppDelegate.sharedInstance.rootViewController;
    
    if (root.session) {
        [WatchAppContext updateWatch:root.session];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.backgroundTask taskCancel];
}

- (void)displayActionSheet:(UIAlertController *)alert {
    alert.popoverPresentationController.sourceView = self.view;
    alert.popoverPresentationController.sourceRect = CGRectMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2, 10, 10);
    
    [self.navigationController presentViewController:alert animated:YES completion:nil];
}

- (UIBarButtonItem *)segBarButtonWithItems:(NSArray *)items action:(SEL)action selectedIndex:(NSInteger)selectedIndex {
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:items];
    
    [seg addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    
    if (selectedIndex != kSegNoSelectedIndex) {
        seg.selectedSegmentIndex = selectedIndex;
    }
    
    return [[UIBarButtonItem alloc] initWithCustomView:seg];
}



- (void)maybeAddFlashButtonWithSpace:(bool)space buttons:(NSMutableArray *)array big:(bool)big {
    if (Settings.flashingLightIcon) {
        if (space) {
            [array addObject:[UIToolbar flexSpace]];
        }
        
        if (big) {
            [array addObject:[self bigFlashButton]];
        } else {
            [array addObject:[self flashButton]];
        }
    }
}

- (UIBarButtonItem *)flashButton {
    return [UIToolbar flashButtonWithTarget:self action:@selector(flashButton:)];
}

- (UIBarButtonItem *)bigFlashButton {
    return [UIToolbar flashButtonWithTarget:self action:@selector(flashButton:)];
}

- (void)flashButton:(UIBarButtonItem *)sender {
    [ViewControllerBase flashScreen:self.navigationController button:sender];
}

+ (void)flashLight:(UINavigationController *)nav {
    [nav pushViewController:[FlashViewController viewController] animated:YES];
}


+ (void)flashScreen:(UINavigationController *)nav button:(UIBarButtonItem *)button {
    if (Settings.flashingLightWarning) {
        Settings.flashingLightWarning = NO;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Flashing Light", @"Alert title")
                                                                       message:NSLocalizedString(@"If you have photosensitive epilepsy please be aware that you may be affected by the flashing light. Would you like to disable this feature? This warning will not be shown again.", @"Warning text")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        ViewControllerBase *top = nil;
        
        if ([nav.topViewController isKindOfClass:[ViewControllerBase class]]) {
            top = (ViewControllerBase *)nav.topViewController;
        }
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Disable", @"Button text") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            Settings.flashingLightIcon = NO;
            
            if (top != nil) {
                [top updateToolbar];
            }
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Continue", @"Buttin text") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            Settings.flashingLightIcon = YES;
            
            if (top != nil) {
                [top updateToolbar];
            }
            
            [ViewControllerBase flashLight:nav];
        }]];
        
        alert.popoverPresentationController.barButtonItem = button;
        
        [nav.topViewController presentViewController:alert animated:YES completion:nil];
    } else {
        [ViewControllerBase flashLight:nav];
    }
}


- (bool)canGoDeeperAlert {
    if (![DepartureTimesView canGoDeeper]) {
        UIAlertController *alert = [UIAlertController simpleOkWithTitle:nil
                                                                message:NSLocalizedString(@"Too many windows are open.", @"error")];
        [self presentViewController:alert animated:YES completion:nil];
        return NO;
    }
    return YES;
}


- (bool)linkAction:(NSString *)link {
    NSString *stoplink = @"id:";
    NSString *routeLink = @"route:";
    
    if (([link containsString:@"trimet.org/a"])
        || ([link containsString:@"trimet.org/#alerts/"])) {
        
        if ([self isKindOfClass:[DetoursView class]])
        {
            UIAlertController *alert = [UIAlertController simpleOkWithTitle:NSLocalizedString(@"Service Alerts", @"Title")
                                                                    message:NSLocalizedString(@"All Service Alerts are displayed here.", @"error")];
            [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            [[DetoursView viewController] fetchDetoursAsync:self.backgroundTask];
        }
        return NO;
    } if ([link containsString:@"trimet.org/#/planner"]) {
        TripPlannerSummaryView *tripStart = [TripPlannerSummaryView viewController];
        @synchronized (_userState)
        {
            [tripStart.tripQuery addStopsFromUserFaves:_userState.faves];
        }
        [self.navigationController pushViewController:tripStart animated:YES];
        return NO;
    }
    else if ([link hasPrefix:stoplink])
    {
        if ([self canGoDeeperAlert])
        {
            DepartureTimesView *viewController = [DepartureTimesView viewController];
            
            [viewController fetchTimesForLocationAsync:self.backgroundTask stopId:[link substringFromIndex:stoplink.length]];
        }
        return NO;
    }
    else if ([link hasPrefix:routeLink])
    {
        if ([self canGoDeeperAlert])
        {
            [[DirectionView viewController] fetchDirectionsAsync:self.backgroundTask route:[link substringFromIndex:routeLink.length]];
        }
        return NO;
    }

    return YES;
}

@end
