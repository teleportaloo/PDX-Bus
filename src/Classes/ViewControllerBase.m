//
//  ViewControllerBase.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/21/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#define DEBUG_LEVEL_FOR_FILE LogUI

#import "ViewControllerBase.h"
#import "DepartureTimesViewController.h"
#import "Detour+iOSUI.h"
#import "DetourLocation+iOSUI.h"
#import "DetoursViewController.h"
#import "DirectionViewController.h"
#import "FindByLocationViewController.h"
#import "FlashViewController.h"
#import "Icons.h"
#import "MapPin.h"
#import "MapViewController.h"
#import "MapViewControllerWithDetourStops.h"
#import "MemoryCaches.h"
#import "NSString+DocPath.h"
#import "NSString+MoreMarkup.h"
#import "NetworkTestViewController.h"
#import "PDXBus-Swift.h"
#import "PDXBusAppDelegate+Methods.h"
#import "RootViewController.h"
#import "SafariServices/SafariServices.h"
#import "Settings.h"
#import "TaskDispatch.h"
#import "TriMetInfo+UI.h"
#import "TripPlannerSummaryViewController.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIApplication+Compat.h"
#import "UIBarButtonItem+Icons.h"
#import "UIColor+HTML.h"
#import "UIFont+Utility.h"
#import "UITableViewCell+Icons.h"
#import "WatchAppContext.h"
#import "WebViewController.h"
#import <Foundation/Foundation.h>
#import <Social/Social.h>

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
    UIFont *_smallFont;
    dispatch_queue_t _xmlSyncQueue;
}

@property (nonatomic, strong) UIColor *buttonTintColor;

@property (nonatomic, strong) id nsudObserver;

@end

@implementation ViewControllerBase

@dynamic basicFont;

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self memberInit];
    }

    return self;
}

- (instancetype)init {
    if ((self = [super init])) {
        [self memberInit];
    }
    return self;
}

- (void)dealloc {
    DEBUG_FUNC();

    //
    // There is a weak reference to self in the background task - it must
    // be removed if we are dealloc'd.
    //
    if (_backgroundTask) {
        _backgroundTask.callbackComplete = nil;
    }

    if (self.nsudObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.nsudObserver];
        self.nsudObserver = nil;
    }
}

+ (instancetype)viewController {
    return [[[self class] alloc] init];
}

+ (UIColor *)contrastingColorForBackgroundColor:(UIColor *)backgroundColor {
    CGFloat red, green, blue, alpha;
    [backgroundColor getRed:&red green:&green blue:&blue alpha:&alpha];

    // Perceived brightness (standard luminance formula)
    CGFloat brightness = (0.299 * red + 0.587 * green + 0.114 * blue);

    DEBUG_LOG_CGFloat(brightness);
    DEBUG_LOG_BOOL(brightness > 0.6);

    return (brightness > 0.6) ? [UIColor blackColor] : [UIColor whiteColor];
}

- (void)simpleNavBarWithColoredButtons:(UIColor *)bgColor tint:(UIColor *)tint {
    UINavigationBar *nb = self.navigationController.navigationBar;

    if (!bgColor) {
        bgColor = UIColor.systemBlueColor;
    } else {
        bgColor = [bgColor modeAwareVariant];
    }

    self.buttonTintColor = bgColor;

    UINavigationBarAppearance *ap = [UINavigationBarAppearance new];
    [ap configureWithOpaqueBackground];
    ap.backgroundEffect = nil;
    ap.backgroundColor = nil;

    // Title colors (optional: use label or a custom color)
    ap.titleTextAttributes = @{NSForegroundColorAttributeName : bgColor};
    ap.largeTitleTextAttributes = ap.titleTextAttributes;

    // Apply the *same* appearance to every state
    nb.translucent = NO;
    nb.barStyle = UIBarStyleDefault;
    nb.tintColor = bgColor ?: UIColor.systemBlueColor; // chevron & glyphs

    nb.standardAppearance = ap;
    nb.scrollEdgeAppearance = ap;
    nb.compactAppearance = ap;
    nb.compactScrollEdgeAppearance = ap;

    // Buttons (text color for text-style buttons)
    UIBarButtonItemAppearance *navBtn = [UIBarButtonItemAppearance new];
    NSDictionary *on = @{NSForegroundColorAttributeName : bgColor};
    NSDictionary *off = @{NSForegroundColorAttributeName : UIColor.systemGrayColor};
    [navBtn.normal setTitleTextAttributes:on];
    [navBtn.highlighted setTitleTextAttributes:on];
    [navBtn.focused setTitleTextAttributes:on];
    [navBtn.disabled setTitleTextAttributes:off];

    UIBarButtonItemAppearance *navBack = [UIBarButtonItemAppearance new];
    [navBack.normal setTitleTextAttributes:on];
    [navBack.highlighted setTitleTextAttributes:on];
    [navBack.focused setTitleTextAttributes:on];
    [navBack.disabled setTitleTextAttributes:off];

    ap.buttonAppearance = navBtn;
    ap.doneButtonAppearance = navBtn;
    ap.backButtonAppearance = navBack;

    // Per-VC mirrors (helps during some transitions)
    self.navigationItem.standardAppearance = ap;
    self.navigationItem.scrollEdgeAppearance = ap;
    self.navigationItem.compactAppearance = ap;
}

- (void)setupLegacyNavBar:(UIColor *)bgCol tint:(UIColor *)tint {

    UINavigationController *nc = self.navigationController;
    UINavigationBar *nb = nc.navigationBar;

    // --- NAV BAR ---
    UINavigationBarAppearance *navAp = [UINavigationBarAppearance new];
    [navAp configureWithOpaqueBackground]; // iOS 18: keep this opaque (stable)
    navAp.shadowColor = nil;
    navAp.backgroundColor = bgCol ?: navAp.backgroundColor;

    navAp.titleTextAttributes = @{NSForegroundColorAttributeName : UIColor.labelColor};
    navAp.largeTitleTextAttributes = @{NSForegroundColorAttributeName : UIColor.labelColor};

    // Buttons (text color for text-style buttons)
    UIBarButtonItemAppearance *navBtn = [UIBarButtonItemAppearance new];
    NSDictionary *on = @{NSForegroundColorAttributeName : tint};
    NSDictionary *off = @{NSForegroundColorAttributeName : UIColor.systemGrayColor};
    [navBtn.normal setTitleTextAttributes:on];
    [navBtn.highlighted setTitleTextAttributes:on];
    [navBtn.focused setTitleTextAttributes:on];
    [navBtn.disabled setTitleTextAttributes:off];

    UIBarButtonItemAppearance *navBack = [UIBarButtonItemAppearance new];
    [navBack.normal setTitleTextAttributes:on];
    [navBack.highlighted setTitleTextAttributes:on];
    [navBack.focused setTitleTextAttributes:on];
    [navBack.disabled setTitleTextAttributes:off];

    navAp.buttonAppearance = navBtn;
    navAp.doneButtonAppearance = navBtn;
    navAp.backButtonAppearance = navBack;

    nb.tintColor = tint; // chevrons & glyphs
    nb.standardAppearance = navAp;
    nb.scrollEdgeAppearance = navAp;
    nb.compactAppearance = navAp;
}

- (void)setupNavBar:(UIColor *)bgCol tint:(UIColor *)tint {

    if (@available(iOS 26.0, *)) {
        [self simpleNavBarWithColoredButtons:bgCol tint:tint];
    } else {
        [self setupLegacyNavBar:bgCol tint:tint];
    }
}

- (void)setupToolbar:(UIColor *)bgCol
                tint:(UIColor *)tint
                 off:(NSDictionary *)off
                  on:(NSDictionary *)on {
    UINavigationController *nc = self.navigationController;
    UIToolbar *tb = nc.toolbar;
    UIToolbarAppearance *tbAp = [UIToolbarAppearance new];
    if (@available(iOS 26.0, *)) {
        [tbAp configureWithTransparentBackground]; // “liquid” on iOS 26
    } else {
        [tbAp configureWithOpaqueBackground]; // safer on iOS 18
    }
    tbAp.shadowColor = nil;
    tbAp.backgroundColor = bgCol ?: tbAp.backgroundColor;

    // IMPORTANT: give toolbar its own button appearance
    UIBarButtonItemAppearance *tbBtn = [UIBarButtonItemAppearance new];
    [tbBtn.normal setTitleTextAttributes:on];
    [tbBtn.highlighted setTitleTextAttributes:on];
    [tbBtn.focused setTitleTextAttributes:on];
    [tbBtn.disabled setTitleTextAttributes:off];
    tbAp.buttonAppearance = tbBtn;
    tbAp.doneButtonAppearance = tbBtn;

    // Clear legacy images that can pin colors
    [tb setBackgroundImage:nil forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [tb setShadowImage:nil forToolbarPosition:UIBarPositionAny];

    tb.tintColor = tint; // glyphs
    tb.standardAppearance = tbAp;
    tb.compactAppearance = tbAp;
    tb.scrollEdgeAppearance = tbAp;

    [nc setToolbarHidden:NO animated:NO];

    [self updateToolbar];
}

- (void)setTheme {

    int color = Settings.toolbarColors;
    UIColor *bgCol = (color != 0xFFFFFF) ? HTML_COLOR(color) : nil;

    // Robust, never-nil tint
    UIColor *iconColor =
        bgCol ? [ViewControllerBase contrastingColorForBackgroundColor:bgCol] : nil;
    UIColor *tint = iconColor ?: UIColor.systemBlueColor;

    NSDictionary *on = @{NSForegroundColorAttributeName : tint};
    NSDictionary *off = @{NSForegroundColorAttributeName : UIColor.systemGrayColor};

    [self setupNavBar:bgCol tint:tint];

    [self setupToolbar:bgCol tint:tint off:off on:on];

    // ---- SETTINGS ----
    if (self.backgroundTask) {
        self.backgroundTask.showSizes = Settings.showSizes;
    }
}

- (bool)memberInit {
    if (_backgroundTask == nil) {
        _userState = UserState.sharedInstance;
        _backgroundTask = [BackgroundTaskContainer create:self parent:self];
        _basicFont = nil;
        _smallFont = nil;
        UIFont.smallFont = self.smallFont;
        UIFont.basicFont = self.basicFont;
        _xmlSyncQueue = dispatch_queue_create("org.teleportaloo.pdxbus.debugxml.sync",
                                              DISPATCH_QUEUE_CONCURRENT);

        return true;
    }
    return false;
}

- (void)backToRootButtons:(NSMutableArray *)toolbarItems {
    [toolbarItems addObject:[self doneButton]];
    [toolbarItems addObject:[UIBarButtonItem flexSpace]];
}

- (void)updateToolbarMainThread {
}

- (void)updateToolbar {
    NSMutableArray<UIBarButtonItem *> *toolbarItems = [NSMutableArray array];

    [self updateToolbarMainThread];
    [self backToRootButtons:toolbarItems];
    [self updateToolbarItems:toolbarItems];
    [self.navigationController.toolbar setHidden:NO];

    if (@available(ios 26.0, *))
        for (UIBarButtonItem *it in toolbarItems ?: @[]) {
            it.tintColor = self.buttonTintColor;
        }

    [self setToolbarItems:toolbarItems animated:NO];
    [self.navigationController.toolbar sizeToFit];
}

#pragma mark Overridden View Methods

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setTheme]; // re-apply on every show (push/pop, tab switch)
}

// Implement viewDidLoad to do additional setup after loading the view,
// typically from a nib.
- (void)viewDidLoad {
    UIFont.smallFont = self.smallFont;
    UIFont.basicFont = self.basicFont;

    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeBottom;
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.additionalSafeAreaInsets = UIEdgeInsetsZero;

    __weak ViewControllerBase *weakSelf = self;

#ifdef DEBUGLOGGING
    NSString *classForLog = NSStringFromClass(self.class);
#endif // DEBUGLOGGING

    self.nsudObserver = [[NSNotificationCenter defaultCenter]
        addObserverForName:NSUserDefaultsDidChangeNotification
                    object:Settings.sharedInstance.defaults
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *note) {
                  ViewControllerBase *strongSelf = weakSelf;

                  DEBUG_LOG(@"Settings changed in class %p %@", strongSelf, classForLog);

                  if (strongSelf) {
                      [strongSelf handleChangeInUserSettingsOnMainThread:note];
                  }
                }];

    [self setTheme];

    if (@available(iOS 26.0, *)) {
        [self.navigationController.toolbar setItems:@[ [UIBarButtonItem fixedSpaceItem] ]
                                           animated:false];
    }
}

- (void)handleChangeInUserSettingsOnMainThread:(NSNotification *)notfication {
    DEBUG_FUNC();
    DEBUG_LOG_class(self);
    [self setTheme];

    if (self.backgroundTask) {
        self.backgroundTask.showSizes = Settings.showSizes;
    }
}

// iOS6 methods

- (BOOL)shouldAutorotate {
    if (self.backgroundTask.running) {
        return NO;
    }

    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    // Small devices do not need to orient
    if (SMALL_SCREEN) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator
        animateAlongsideTransition:nil
                        completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                          [self waitForValidWidthWithRetry:0
                                                     block:^{
                                                       if (!self.backgroundTask.running) {
                                                           [self reloadData];
                                                       }
                                                     }];
                        }];

    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

#pragma mark View helper methods

- (void)addDoneButtonSameAsBack {
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:self
                                                      action:@selector(doneButtonTapped)];
}

- (void)doneButtonTapped {
    if (self.navigationController) {
        // If presented via push, pop back
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        // If presented modally, dismiss
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)waitForValidWidthWithRetry:(NSInteger)retry block:(void (^)(void))block {
    DEBUG_LOG_long(retry);
    if (retry > 100)
        return;

    CGFloat width = UIApplication.firstKeyWindow.frame.size.width;
    DEBUG_LOG_CGFloat(width);
    if (width > 1) {

        block();
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(),
                       ^{
                         [self waitForValidWidthWithRetry:retry + 1 block:block];
                       });
    }
}

- (void)willRotateTo:(UIInterfaceOrientation)orientation {
    if (!self.backgroundTask.running) {
        [self reloadData];
    }
}

- (void)reloadData {
    DEBUG_HERE();
    _basicFont = nil;
    _smallFont = nil;
    UIFont.smallFont = self.smallFont;
    UIFont.basicFont = self.basicFont;
    [self setTheme];
}

- (UIView *)clearView {
    UIView *backView = [[UIView alloc] initWithFrame:CGRectZero];

    backView.backgroundColor = [UIColor clearColor];
    return backView;
}

#pragma mark Toolbar methods

- (UIBarButtonItem *)doneButton {
    if (self.stopIdStringCallback != nil &&
        (self.stopIdStringCallback.returnStopIdStringController != nil || [self forceRedoButton])) {
        return [UIBarButtonItem redoButtonWithTarget:self action:@selector(backButton:)];
    } else {
        return [UIBarButtonItem homeButtonWithTarget:self action:@selector(backButton:)];
    }
}

- (bool)forceRedoButton {
    return false;
}

- (void)debugXmlInit {
    dispatch_barrier_async(_xmlSyncQueue, ^{
      if (Settings.debugXML) {
          self.debugXml = [NSMutableArray array];
      } else {
          self.debugXml = nil;
      }
    });
}

- (void)debugXmlAddParser:(TriMetXML *)xml {
    dispatch_barrier_async(_xmlSyncQueue, ^{
      if (xml && xml.rawData && self.debugXml != nil) {
          [self.debugXml addObject:xml];
      }
    });
}

- (void)appendDebugXmlData:(NSMutableData *)buffer {
    dispatch_sync(_xmlSyncQueue, ^{
      for (TriMetXML *xml in self.debugXml) {
          if (xml.rawData && xml.fullQuery) {
              [xml appendQueryAndData:buffer];
          }
      }
    });
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

- (void)didBecomeActive {
}

- (void)debugXmlAction:(UIBarButtonItem *)sender {
    // We replace some items in the XML to hide it or to make the reader
    // happy when concatonating.  This was learnt by trial and error!
    // uncrustify-off
    NSDictionary *replacements = @{
        TriMetXML.appId : @"TRIMET_APP_ID", // hide APP ID
        @"<?xml" : @"<!--",                 // XML encoding gets in the way
        @"?>" : @"-->",
        @"<--?xml" : @"<!--", // XML encoding gets in the way
        @"?-->" : @"-->",
        @"<body" : @"<wasbody", // This keyword gets dropped
        @"body>" : @"wasbody>"
    };
    // uncrustify-on

    NSMutableData *buffer = [[NSMutableData alloc] init];

    [self appendDebugXmlData:buffer];

    NSMutableString *redactedData = [[NSMutableString alloc] initWithBytes:buffer.bytes
                                                                    length:buffer.length
                                                                  encoding:NSUTF8StringEncoding];

    [replacements
        enumerateKeysAndObjectsUsingBlock:^void(NSString *key, NSString *replacement, BOOL *stop) {
          [redactedData replaceOccurrencesOfString:key
                                        withString:replacement
                                           options:NSCaseInsensitiveSearch
                                             range:NSMakeRange(0, redactedData.length)];
        }];

    [redactedData insertString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><root>" atIndex:0];
    [redactedData appendString:@"</root>"];

    int viewer = Settings.xmlViewer;

    if (viewer == 1) { // Share

        // delete any dross! we arem't using a file any more
        NSString *path = @"PDXBus Debug Data.xml".fullDocPath;
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];

        NSArray *activities = @[ redactedData ]; // [NSURL fileURLWithPath:path] ];

        UIActivityViewController *activityViewControntroller =
            [[UIActivityViewController alloc] initWithActivityItems:activities
                                              applicationActivities:nil];
        // activityViewControntroller.excludedActivityTypes = @[];

        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIView *source = (UIView *)[sender valueForKey:@"view"];

            if (source == nil) {
                source = self.view;
            }

            activityViewControntroller.popoverPresentationController.sourceView = source;
            activityViewControntroller.popoverPresentationController.sourceRect =
                CGRectMake(source.bounds.size.width / 2, source.bounds.size.height / 2, 0, 0);
        }

        [self presentViewController:activityViewControntroller animated:true completion:nil];
    } else {
        [redactedData replaceOccurrencesOfString:@"\\"
                                      withString:@"\\\\"
                                         options:NSCaseInsensitiveSearch
                                           range:NSMakeRange(0, redactedData.length)];

        NSDictionary *replacements2 = @{
            // uncrustify-off
            @"\"" : @"\\\"",
            @"\n" : @" ",
            @"\r" : @" ",
            @"'" : @"\'"
            // uncrustify-on
        };

        [replacements2 enumerateKeysAndObjectsUsingBlock:^void(
                           NSString *key, NSString *replacement, BOOL *stop) {
          [redactedData replaceOccurrencesOfString:key
                                        withString:replacement
                                           options:NSCaseInsensitiveSearch
                                             range:NSMakeRange(0, redactedData.length)];
        }];

        WebViewController *web = [WebViewController viewController];

        if (viewer == 2) {
            [web setNamedUrl:@"XML Viewer 2"];
            web.javsScriptCommand =
                [NSString stringWithFormat:@"document.getElementById('xmlString').value="
                                           @"\"%@\"; document.forms[0].submit()",
                                           redactedData];
        } else if (viewer == 3) {
            [web setNamedUrl:@"XML Viewer 3"];
            web.javsScriptCommand =
                [NSString stringWithFormat:@"document.getElementById('xml').value=\"%@\"; "
                                           @"document.getElementById('pretty_print').submit()",
                                           redactedData];
        }

        DEBUG_LOG_NSString(web.urlToDisplay);
        DEBUG_LOG_NSString(web.javsScriptCommand);
        [self.navigationController pushViewController:web animated:YES];
    }
}

- (UIBarButtonItem *)debugXmlButton {
    // create the system-defined "OK or Done" button
    UIBarButtonItem *xmlButton =
        [UIBarButtonItem iconButton:kIconXml
                 accessabilityLabel:NSLocalizedString(@"Debug XML", @"toolbar button")
                             target:self
                             action:@selector(debugXmlAction:)];

    return xmlButton;
}

- (void)updateToolbarItems:(NSMutableArray<UIBarButtonItem *> *)toolbarItems {
    [self maybeAddFlashButtonWithSpace:(toolbarItems.count == 0) buttons:toolbarItems big:NO];
}

- (void)updateToolbarItemsWithXml:(NSMutableArray<UIBarButtonItem *> *)toolbarItems {
    if (Settings.debugXML) {
        [toolbarItems addObject:[self debugXmlButton]];
        [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
    } else {
        [self maybeAddFlashButtonWithSpace:NO buttons:toolbarItems big:NO];
    }
}

- (void)backButton:(id)sender {
    if (self.stopIdStringCallback != nil &&
        self.stopIdStringCallback.returnStopIdStringController != nil) {
        [self.navigationController
            popToViewController:self.stopIdStringCallback.returnStopIdStringController
                       animated:YES];
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)showRouteSchedule:(NSString *)route {
    if ([[TriMetInfo streetcarRoutes] containsObject:route]) {
        [WebViewController displayNamedPage:@"Portland Streetcar"
                                  navigator:self.navigationController
                             itemToDeselect:nil
                                   whenDone:self.callbackWhenDone];
    } else {
        NSMutableString *padding = [NSMutableString string];

        [self padRoute:route padding:&padding];

        [WebViewController displayNamedPage:@"TriMet Route"
                                  parameter:padding
                                  navigator:self.navigationController
                             itemToDeselect:nil
                                   whenDone:self.callbackWhenDone];
    }
}

#pragma mark Common actions

- (bool)fullScreen {
#if !TARGET_OS_MACCATALYST
    CGRect myBounds = UIApplication.appRect;
    CGRect fullScreen = [UIScreen mainScreen].bounds;

    if (fullScreen.size.width == myBounds.size.width) {
        return YES;
    }

    return NO;

#else
    return YES;

#endif // !TARGET_OS_MACCATALYST
}

- (bool)videoCaptureSupported {
    if (self.fullScreen) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

        if (device == nil) {
            return NO;
        }

        AVAuthorizationStatus authStatus =
            [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];

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
        [*padding appendString:@"0"];
    }
    [*padding appendString:route];
}

- (void)networkTips:(NSData *)htmlError networkError:(NSString *)networkError {
    if (htmlError) {
        WebViewController *errorScreen = [WebViewController viewController];
        [errorScreen setRawData:htmlError title:NSLocalizedString(@"Error Message", @"error")];
        [errorScreen displayPage:self.navigationController animated:YES itemToDeselect:nil];
    } else {
        NetworkTestViewController *networkTest = [NetworkTestViewController viewController];
        networkTest.networkErrorFromQuery = networkError;
        [networkTest fetchNetworkStatusAsync:self.backgroundTask backgroundRefresh:NO];
    }
}

#pragma mark Text Manipulation Methods

- (UIFont *)smallFont {
    if (_smallFont == nil) {
        if (SMALL_SCREEN) {
            _smallFont = [UIFont monospacedDigitSystemFontOfSize:16.0];
        } else {
            _smallFont = [UIFont monospacedDigitSystemFontOfSize:22.0];
        }
    }

    return _smallFont;
}

- (UIFont *)basicFont {
    if (_basicFont == nil) {
        if (SMALL_SCREEN) {
            _basicFont = [UIFont monospacedDigitSystemFontOfSize:20.0];
        } else {
            _basicFont = [UIFont monospacedDigitSystemFontOfSize:22.0];
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

- (void)instagramAt:(NSString *)user {
    [[UIApplication sharedApplication]
        compatOpenURL:[NSURL URLWithString:[WebViewController namedURL:@"Instagram" param:user]]];
}

- (void)blueskyAt:(NSString *)user {
    [[UIApplication sharedApplication]
        compatOpenURL:[NSURL URLWithString:[WebViewController namedURL:@"Bluesky" param:user]]];
}

- (void)triMetBluesky {
    [self blueskyAt:@"trimet.org"];
}

- (void)clearSelection {
}

- (UIViewController *)callbackWhenDone {
    if (self.stopIdStringCallback) {
        return self.stopIdStringCallback.returnStopIdStringController;
    }

    return nil;
}

- (bool)openSafariFrom:(UIViewController *)view path:(NSString *)path {
    Class safariClass = (NSClassFromString(@"SFSafariViewController"));

    NSURL *url = [NSURL URLWithString:path];

    if (safariClass != nil) {
        SFSafariViewController *vc = [[SFSafariViewController alloc] initWithURL:url];

        // vc.delegate = self
        [view presentViewController:vc
                           animated:YES
                         completion:^{
                         }];
        return TRUE;
    } else {
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] compatOpenURL:url];
            return TRUE;
        }
    }

    return FALSE;
}

- (void)facebookAt:(NSString *)user {
    [[UIApplication sharedApplication]
        compatOpenURL:[NSURL URLWithString:[WebViewController namedURL:@"Facebook" param:user]]];
}

- (void)facebookTriMet {
    [self facebookAt:@"TriMet"];
    [self clearSelection];
}

- (void)facebookPDXBus {
    [self facebookAt:@"PDXBus"];
    [self clearSelection];
}

- (void)userStateChanged {
    _userState.dirty = YES;
    [self updateWatch];
}

- (void)updateWatch {
    RootViewController *root = RootViewController.currentRootViewController;

    if (root.session) {
        [WatchAppContext updateWatch:root.session];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.backgroundTask taskCancel];
}

- (void)displayPopover:(UIViewController *)alert
                  view:(UIView *)view
            completion:(void (^__nullable)(void))completion {
    alert.popoverPresentationController.sourceView = view;
    alert.popoverPresentationController.sourceRect =
        CGRectMake(view.frame.size.width / 2, view.frame.size.height / 2, 10, 10);

    [self.navigationController presentViewController:alert animated:YES completion:completion];
}

- (void)displayPopover:(UIViewController *)alert completion:(void (^__nullable)(void))completion {
    [self displayPopover:alert view:self.view completion:completion];
}

- (void)displayPopover:(UIViewController *)alert
     fromBarButtonItem:(UIBarButtonItem *_Nullable)item
            completion:(void (^__nullable)(void))completion {
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIPopoverPresentationController *pop = alert.popoverPresentationController;
        if (item) {
            pop.barButtonItem = item;
        } else {
            pop.sourceView = self.view;
            pop.sourceRect =
                CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
        }
    }
    [self presentViewController:alert animated:YES completion:completion];
}

- (UIBarButtonItem *)segBarButtonWithItems:(NSArray *)items
                                    action:(SEL)action
                             selectedIndex:(NSInteger)selectedIndex {
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:items];

    if (self.buttonTintColor) {
        // Text colors
        NSDictionary *normalAttrs = @{NSForegroundColorAttributeName : self.buttonTintColor};
        NSDictionary *selectedAttrs = @{NSForegroundColorAttributeName : self.buttonTintColor};
        [seg setTitleTextAttributes:normalAttrs forState:UIControlStateNormal];
        [seg setTitleTextAttributes:selectedAttrs forState:UIControlStateSelected];
    }

    [seg addTarget:self action:action forControlEvents:UIControlEventValueChanged];

    if (selectedIndex != kSegNoSelectedIndex) {
        seg.selectedSegmentIndex = selectedIndex;
    }

    return [[UIBarButtonItem alloc] initWithCustomView:seg];
}

- (void)maybeAddFlashButtonWithSpace:(bool)space
                             buttons:(NSMutableArray<UIBarButtonItem *> *)array
                                 big:(bool)big {
    if (Settings.flashingLightIcon) {
        if (space) {
            [array addObject:[UIBarButtonItem flexSpace]];
        }

        if (big) {
            [array addObject:[self bigFlashButton]];
        } else {
            [array addObject:[self flashButton]];
        }
    }
}

- (UIBarButtonItem *)flashButton {
    return [UIBarButtonItem flashButtonWithTarget:self action:@selector(flashButton:)];
}

- (UIBarButtonItem *)bigFlashButton {
    return [UIBarButtonItem flashButtonWithTarget:self action:@selector(flashButton:)];
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

        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:NSLocalizedString(@"Flashing Light", @"Alert title")
                             message:NSLocalizedString(@"If you have photosensitive epilepsy "
                                                       @"please be aware that you may be "
                                                       @"affected by the flashing light. Would "
                                                       @"you like to disable this feature? This "
                                                       @"warning will not be shown again.",
                                                       @"Warning text")
                      preferredStyle:UIAlertControllerStyleAlert];

        ViewControllerBase *top = nil;

        if ([nav.topViewController isKindOfClass:[ViewControllerBase class]]) {
            top = (ViewControllerBase *)nav.topViewController;
        }

        [alert
            addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Disable", @"Button text")
                                               style:UIAlertActionStyleDestructive
                                             handler:^(UIAlertAction *action) {
                                               Settings.flashingLightIcon = NO;

                                               if (top != nil) {
                                                   [top updateToolbar];
                                               }
                                             }]];

        [alert
            addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Continue", @"Buttin text")
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
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
    if (![DepartureTimesViewController canGoDeeper]) {
        [UIAlertController
            simpleOkWithTitle:nil
                      message:NSLocalizedString(@"Too many windows are open.", @"error")
               viewController:self
                   completion:nil];
        return NO;
    }

    return YES;
}

- (BOOL)textView:(UITextView *)textView
    shouldInteractWithURL:(NSURL *)URL
                  inRange:(NSRange)characterRange
              interaction:(UITextItemInteraction)interaction {
    return [self linkAction:URL.absoluteString source:textView];
}

- (bool)linkAction:(NSString *)link source:(UIView *)source {
    static NSString *stoplink = @"id:";
    static NSString *routeLink = @"route:";
    static NSString *tpLink = @"info:timepoint";

    if ([link containsString:@"trimet.org/#/planner"]) {
        TripPlannerSummaryViewController *tripStart =
            [TripPlannerSummaryViewController viewController];
        tripStart.tripQuery.userFaves = _userState.stopsFromFaves;
        [self.navigationController pushViewController:tripStart animated:YES];
        return NO;
    } else if ([link hasPrefix:stoplink]) {
        if ([self canGoDeeperAlert]) {
            DepartureTimesViewController *viewController =
                [DepartureTimesViewController viewController];
            viewController.stopIdStringCallback = self.stopIdStringCallback;

            [viewController fetchTimesForLocationAsync:self.backgroundTask
                                                stopId:[link substringFromIndex:stoplink.length]];
        }

        return NO;
    } else if ([link hasPrefix:routeLink]) {
        if ([self canGoDeeperAlert]) {
            DirectionViewController *directionView = [DirectionViewController viewController];
            directionView.stopIdStringCallback = self.stopIdStringCallback;
            [directionView fetchDirectionsAsync:self.backgroundTask
                                          route:[link substringFromIndex:routeLink.length]];
        }

        return NO;
    } else if ([link hasPrefix:tpLink]) {
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:NSLocalizedString(@"Time Points", @"alert title")
                             message:NSLocalizedString(@"Blue stops are Time Points - one of "
                                                       @"several stops on each route that "
                                                       @"serves as a benchmark for whether a "
                                                       @"trip is running on time.",
                                                       @"alert message")
                      preferredStyle:UIAlertControllerStyleActionSheet];

        [alert
            addAction:[UIAlertAction
                          actionWithTitle:NSLocalizedString(@"Show TriMet dashboard", @"alert item")
                                    style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction *action) {
                                    [WebViewController displayNamedPage:@"TriMet Dashboard"
                                                              navigator:self.navigationController
                                                         itemToDeselect:nil
                                                               whenDone:nil];
                                  }]];

        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"alert item")
                                                  style:UIAlertActionStyleCancel
                                                handler:^(UIAlertAction *action) {
                                                  [self clearSelection];
                                                }]];

        [self displayPopover:alert view:source completion:nil];

        return NO;
    }

    return YES;
}

@end
