//
//  WebViewController.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WebViewController.h"
#import "TableViewWithToolbar.h"
#import "DebugLogging.h"
#import "TriMetTypes.h"
#import "OpenInChromeController.h"
#import "SafariServices/SafariServices.h"
#import "TriMetXML.h"
#import "Icons.h"
#import "UIAlertController+SimpleMessages.h"
#import "UIApplication+Compat.h"

#define DEBUG_LEVEL_FOR_FILE kLogWeb

@interface WebViewController () {
    int _depth;
    bool _navigated;
}

@property (nonatomic, strong)   NSData *rawDataToDisplay;
@property (nonatomic, copy)     NSString *dataToDisplay;
@property (nonatomic, strong)   WKWebView *webView;
@property (nonatomic, strong)   UIBarButtonItem *webBack;
@property (nonatomic, strong)   UIBarButtonItem *webForward;
@property (nonatomic, strong)   UIBarButtonItem *safari;
@property (nonatomic, strong)   UIViewController *whenDone;
@property (nonatomic)           bool showErrors;
@property (nonatomic, strong)   NSURL *localURL;
@property (nonatomic)           NSInteger rssLinkItem;

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems;
- (void)setRawData:(NSData *)rawData title:(NSString *)title;
- (void)displayPage:(UINavigationController *)nav animated:(BOOL)animated itemToDeselect:(id<DeselectItemDelegate>)deselect;

@end

@implementation WebViewController

- (void)dealloc {
    [self.webView stopLoading];
    [self.webView setNavigationDelegate:nil];
    [UIApplication sharedApplication].compatNetworkActivityIndicatorVisible = NO;
}

- (instancetype)init {
    if ((self = [super init])) {
        self.showErrors = NO;// NO;
        _depth = 0;
    }
    
    return self;
}

#pragma mark Data setters

- (void)setRawData:(NSData *)rawData title:(NSString *)title {
    self.rawDataToDisplay = rawData;
    self.title = title;
}

- (void)setURLmobile:(NSString *)url full:(NSString *)full {
    if (LARGE_SCREEN && full != nil) {
        self.urlToDisplay = full;
    } else {
        self.urlToDisplay = url;
    }
    
    self.title = NSLocalizedString(@"Loading page...", @"Initial web page title");
}

- (void)setNamedUrl:(NSString *)name {
    self.urlToDisplay = [WebViewController namedURL:name];
    self.title = NSLocalizedString(@"Loading page...", @"Initial web page title");
}

#pragma mark ViewControllerBase methods

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems {
    [toolbarItems removeAllObjects];
    // match each of the toolbar item's style match the selection in the "UIBarButtonItemStyle" segmented control
    UIBarButtonItemStyle style = UIBarButtonItemStylePlain;
    
    
    
    self.safari = [[UIBarButtonItem alloc]
                   initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                   target:self action:@selector(safariButton:)];
    self.safari.style = style;
    
    
    self.webBack = [[UIBarButtonItem alloc]
                    // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
                    initWithImage:[Icons getToolbarIcon:kIconBack7]
                    style:style
                    target:self action:@selector(webBackButton:)];
    self.webBack.accessibilityLabel = @"Back";
    
    TOOLBAR_PLACEHOLDER(self.webBack, NSLocalizedString(@"back", @"placeholder"));
    
    self.webForward = [[UIBarButtonItem alloc]
                       initWithImage:[Icons getToolbarIcon:kIconForward7]
                       style:style
                       target:self action:@selector(webForwardButton:)];
    self.webForward.accessibilityLabel = @"Forward";
    self.webForward.style = style;
    
    TOOLBAR_PLACEHOLDER(self.webBack, NSLocalizedString(@"next", @"placeholder"));
    
    if (self.rawDataToDisplay == nil && self.localURL == nil) {
        [toolbarItems addObject:self.webBack];
        [toolbarItems addObject:[UIToolbar flexSpace]];
        [toolbarItems addObject:self.webForward];
        [toolbarItems addObject:[UIToolbar flexSpace]];
        [toolbarItems addObject:self.safari];
        [toolbarItems addObject:[UIToolbar flexSpace]];
    }
    
    [toolbarItems addObject:[self doneButton]];
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
}

#pragma mark UI callbacks

- (void)safariButton:(UIBarButtonItem *)sender {
    [self.webView evaluateJavaScript:@"document.URL" completionHandler:^(NSString *result, NSError *_Nullable error) {
        if (result) {
            NSURL *address = [NSURL URLWithString:result];
            
            UIAlertController *alert = [UIAlertController                                              alertControllerWithTitle:NSLocalizedString(@"Safari", @"alert title")
                                                                                                                        message:nil
                                                                                                                 preferredStyle:UIAlertControllerStyleActionSheet];
            
            
            [alert addAction:[UIAlertAction                                              actionWithTitle:NSLocalizedString(@"Open in Safari", @"alert title")
                                                                                                   style:UIAlertActionStyleDefault
                                                                                                 handler:^(UIAlertAction *action) {
                [[UIApplication sharedApplication] compatOpenURL:address];
            }]];
            
            if ([OpenInChromeController sharedInstance].chromeInstalled) {
                [alert addAction:[UIAlertAction                                          actionWithTitle:NSLocalizedString(@"Open in Chrome", @"button text")
                                                                                                   style:UIAlertActionStyleDefault
                                                                                                 handler:^(UIAlertAction *action) {
                    [[OpenInChromeController sharedInstance] openInChrome:address
                                                          withCallbackURL:[NSURL URLWithString:@"pdxbus://back"]
                                                             createNewTab:YES];
                }]];
            }
            
            alert.popoverPresentationController.barButtonItem = sender;
            
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"button text") style:UIAlertActionStyleCancel handler:nil]];
            
            [self presentViewController:alert animated:YES completion:^{
                [self clearSelection];
            }];
        }
    }];
}

- (void)webForwardButton:(id)sender {
    [self.webView goForward];
}

- (void)webBackButton:(id)sender {
    if (self.webView.canGoBack) {
        [self.webView goBack];
        _depth--;
        
        if (_depth == 0 && self.dataToDisplay != nil) {
            self.safari.enabled = NO;
        } else {
            self.safari.enabled = YES;
        }
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark View methods

// OK - we need a little adjustment here for iOS7.  It took we a while to get this right - I'm exactly
// sure what is going on but on the iPad we need to make the height a little bigger in some cases.
// Annoying.

- (CGFloat)heightOffset {
    if (LARGE_SCREEN || (self.screenInfo.screenWidth == WidthBigVariable)) {
        return -[UIApplication sharedApplication].compatStatusBarFrame.size.height;
    }
    
    return 0.0;
}

- (void)loadView {
    [super loadView];
    
    // Set the size for the table view
    CGRect webViewRect = self.middleWindowRect;
    
    ///webViewRect.size.width = [[UIScreen mainScreen] applicationFrame].size.width;
    //webViewRect.size.height = [[UIScreen mainScreen] applicationFrame].size.height - [self heightOffset];
    //webViewRect.origin.x = 0;
    //webViewRect.origin.y = 0;
    
    // Create a table viiew
    self.webView = [[WKWebView alloc] initWithFrame:webViewRect];
    // set the autoresizing mask so that the table will always fill the view
    self.webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    
    self.webView.backgroundColor = [UIColor whiteColor];
    // self.webView.scalesPageToFit = YES;
    
    
    
    // set the tableview delegate to this object
    self.webView.navigationDelegate = self;
    
    
    
    [self.view addSubview:self.webView];
    
    if (self.rawDataToDisplay != nil) {
        NSString *path = [NSBundle mainBundle].bundlePath;
        NSURL *baseURL = [NSURL fileURLWithPath:path];
        
        // Remove the apps ID from the data
        NSMutableString *stringData = [[NSMutableString alloc] initWithData:self.rawDataToDisplay encoding:NSUTF8StringEncoding];
        
        [stringData replaceOccurrencesOfString:[TriMetXML appId]
                                    withString:@"[hidden application ID]"
                                       options:NSCaseInsensitiveSearch
                                         range:NSMakeRange(0, stringData.length)];
        
        
        // [self.webView loadData:self.rawDataToDisplay MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:baseURL];
        [self.webView loadHTMLString:stringData baseURL:baseURL];
    } else if (self.dataToDisplay != nil) {
        [self.webView loadHTMLString:self.dataToDisplay baseURL:nil];
    } else if (self.localURL) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:self.localURL]];
    } else {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlToDisplay]]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
                                     // Release anything that's not essential, such as cached data
}

#pragma mark UIWebView delegate methods


- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (!_navigated) {
        // finished loading, hide the activity indicator in the status bar
        [UIApplication sharedApplication].compatNetworkActivityIndicatorVisible = NO;
        
        
        self.webBack.enabled = YES;
        self.webForward.enabled = webView.canGoForward;
        
        [self.webView evaluateJavaScript:@"document.title" completionHandler:^(NSString *result, NSError *_Nullable error) {
            if (result) {
                self.title = result;
            }
        }];
        
        
        NSString *js = @"\
        var d = document.getElementsByTagName('a');\
        for (var i = 0; i < d.length; i++) {\
        if (d[i].getAttribute('target') != null) {\
        d[i].removeAttribute('target');\
        }\
        }\
        ";
        
        [self.webView evaluateJavaScript:js completionHandler:nil];
        
        if (self.javsScriptCommand) {
            [self.webView evaluateJavaScript:self.javsScriptCommand completionHandler:^(NSString *result, NSError *_Nullable error) {
                LOG_NSERROR(error);
            }];
        }
        
        _navigated = YES;
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    // load error, hide the activity indicator in the status bar
    [UIApplication sharedApplication].compatNetworkActivityIndicatorVisible = NO;
    
    if (self.showErrors) {
        // report the error inside the webview
        NSString *errorString = [NSString stringWithFormat:
                                 @"<html><center><font size=+5 color='red'>An error occurred:<br>%@</font></center></html>",
                                 error.localizedDescription];
        [webView loadHTMLString:errorString baseURL:nil];
    } else {
        if (!([error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -999)) {
            UIAlertController * alert = [UIAlertController simpleOkWithTitle:NSLocalizedString(@"Web Page Error", @"page title")
                                                                     message:error.localizedDescription];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (bool)openSafariFrom:(UIViewController *)view path:(NSString *)path {
    return [super openSafariFrom:view path:path];
}

+ (void)displayPage:(NSString *)mobile
               full:(NSString *)full
          navigator:(UINavigationController *)nav
     itemToDeselect:(id<DeselectItemDelegate>)deselect
           whenDone:(UIViewController *)whenDone {
    if (mobile == nil && full == nil) {
        return;
    }
    
    @try {
        WebViewController *webPage = [WebViewController viewController];
        
        [webPage setURLmobile:mobile full:full];
        
        webPage.whenDone = whenDone;
        webPage.showErrors = NO;
        
        [webPage displayPage:nav animated:YES itemToDeselect:deselect];
    } @catch (NSException *exception)   {
        ERROR_LOG(@"Exception: %@ %@\n", exception.name, exception.reason);
        UIAlertController * alert = [UIAlertController simpleOkWithTitle:NSLocalizedString(@"Unable to open link", @"error")
                                                                 message:[NSString stringWithFormat:@"Reason: %@", exception.reason]];
        [nav.topViewController presentViewController:alert animated:YES completion:nil];
        
    }
}


+ (void)displayNamedPage:(NSString *)name
               navigator:(UINavigationController *)nav
          itemToDeselect:(id<DeselectItemDelegate>)deselect
                whenDone:(UIViewController *)whenDone {
    @try {
        WebViewController *webPage = [WebViewController viewController];
        
        webPage.urlToDisplay = [WebViewController namedURL:name];
        webPage.whenDone = whenDone;
        webPage.showErrors = NO;
        
        [webPage displayPage:nav animated:YES itemToDeselect:deselect];
    } @catch (NSException *exception)   {
        ERROR_LOG(@"Exception: %@ %@\n", exception.name, exception.reason);
        UIAlertController * alert = [UIAlertController simpleOkWithTitle:NSLocalizedString(@"Unable to open link", @"error")
                                                                 message:[NSString stringWithFormat:@"Reason: %@", exception.reason]];
        [nav.topViewController presentViewController:alert animated:YES completion:nil];
        
    }
}


+ (void)displayNamedPage:(NSString *)name
               parameter:(NSString *)param
               navigator:(UINavigationController *)nav
          itemToDeselect:(id<DeselectItemDelegate>)deselect
                whenDone:(UIViewController *)whenDone {
    @try {
        WebViewController *webPage = [WebViewController viewController];
        
        webPage.urlToDisplay = [WebViewController namedURL:name param:param];
        webPage.whenDone = whenDone;
        webPage.showErrors = NO;
        
        [webPage displayPage:nav animated:YES itemToDeselect:deselect];
    } @catch (NSException *exception)   {
        ERROR_LOG(@"Exception: %@ %@\n", exception.name, exception.reason);
        UIAlertController * alert = [UIAlertController simpleOkWithTitle:NSLocalizedString(@"Unable to open link", @"error")
                                                                 message:[NSString stringWithFormat:@"Reason: %@", exception.reason]];
        [nav.topViewController presentViewController:alert animated:YES completion:nil];
        
    }
}


- (void)displayPage:(UINavigationController *)nav animated:(BOOL)animated itemToDeselect:(id<DeselectItemDelegate>)deselect {
    if (Settings.useChrome && [OpenInChromeController sharedInstance].chromeInstalled && self.urlToDisplay != nil) {
        [[OpenInChromeController sharedInstance] openInChrome:[NSURL URLWithString:self.urlToDisplay]
                                              withCallbackURL:[NSURL URLWithString:@"pdxbus:"]
                                                 createNewTab:NO];
        
        if (deselect) {
            [deselect deselectItemCallback];
        }
    } else if (self.urlToDisplay && [self openSafariFrom:nav path:self.urlToDisplay]) {
        if (deselect) {
            [deselect deselectItemCallback];
        }
    } else {
        [nav pushViewController:self animated:animated];
    }
}

+ (NSString *)namedURL:(NSString *)name param:(NSString *)param {
    NSString *url = [WebViewController namedURL:name];
    
    if (url) {
        return [NSString stringWithFormat:url, param];
    }
    
    return nil;
}

+ (void)openNamedURL:(NSString *)name {
    [[UIApplication sharedApplication] compatOpenURL:[NSURL URLWithString:[WebViewController namedURL:name]]];
}
+ (NSString *)namedURL:(NSString *)name {
    static dispatch_once_t once;
    static NSDictionary *links;
    
#ifdef DEBUGLOGGING
    static NSMutableSet *itemsLeft;
#endif
    
    dispatch_once(&once, ^{
        links = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"web-links" ofType:@"plist"]];
    
#ifdef DEBUGLOGGING
        itemsLeft = [NSMutableSet setWithArray:links.allKeys];
#endif
    });
        
    NSDictionary *item = links[name];
    
    if (item == nil) {
        ERROR_LOG(@"Named URL not found: %@", name);
        return nil;
    }
    
    NSString *full   = item[@"LinkF"];
    NSString *mobile = item[@"LinkM"];
    NSString *final  = nil;
    
    if (LARGE_SCREEN && full != nil) {
        final = full;
    }
    
    if (final == nil) {
        final = mobile;
    }
    
    if (final == nil) {
        final = full;
    }
    
    if (final == nil) {
        ERROR_LOG(@"No link for named URL: %@", name);
    }
    
#ifdef DEBUGLOGGING
    [itemsLeft removeObject:name];
    
    DEBUG_LOG(@"Link %@", name);
    DEBUG_LOG(@"Links to go %ld", (long)itemsLeft.count);
    
    for (NSString *left in itemsLeft) {
        DEBUG_LOG(@"Not used: %@", left);
    }
#endif
    
    return final;
}

@end
