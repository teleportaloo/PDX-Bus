//
//  WebViewController.m
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WebViewController.h"
#import "TableViewWithToolbar.h"
#include "DebugLogging.h"
#include "TriMetTypes.h"
#include "OpenInChromeController.h"
#import "SafariServices/SafariServices.h"



@implementation WebViewController

@synthesize webView			= _webView;
@synthesize urlToDisplay	= _urlToDisplay;
@synthesize dataToDisplay	= _dataToDisplay;
@synthesize webBack			= _webBack;
@synthesize webForward		= _webForward;
@synthesize whenDone		= _whenDone;
@synthesize showErrors		= _showErrors;
@synthesize rawDataToDisplay = _rawDataToDisplay;
@synthesize safari			= _safari;
@synthesize localURL		= localURL;
@synthesize rssLinkItem		= _rssLinkItem;

- (void)dealloc {
	[self.webView stopLoading];
	[self.webView setDelegate:nil];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	self.urlToDisplay = nil;
	self.webView = nil;
	self.webBack = nil;
	self.webForward = nil;	
	self.dataToDisplay = nil;
	self.whenDone = nil;
	self.localURL = nil;
	self.rawDataToDisplay = nil;
    self.safari = nil;
	[super dealloc];
}

- (instancetype)init {
	if ((self = [super init]))
	{
		self.showErrors = NO;// NO;
		_depth = 0;
	}
	return self;
}

#pragma mark Data setters

- (void)setRawData:(NSData *)rawData title:(NSString *)title
{	
	self.rawDataToDisplay = rawData;
	self.title = title;
}

- (void)setURLmobile:(NSString *)url full:(NSString *)full
{
	if (LARGE_SCREEN && full!=nil)
	{
		self.urlToDisplay = full;
	}
	else {
		self.urlToDisplay = url;

	}

	self.title = NSLocalizedString(@"Loading page...", @"Initial web page title");
}

#pragma mark ViewControllerBase methods

- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    [toolbarItems removeAllObjects];
	// match each of the toolbar item's style match the selection in the "UIBarButtonItemStyle" segmented control
	UIBarButtonItemStyle style = UIBarButtonItemStylePlain;
	
	
	
	self.safari = [[[UIBarButtonItem alloc]
							 initWithBarButtonSystemItem:UIBarButtonSystemItemAction
							 target:self action:@selector(safariButton:)] autorelease];
	self.safari.style = style;
	
	
	self.webBack = [[[UIBarButtonItem alloc]
								// initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
								initWithImage:[TableViewWithToolbar getToolbarIcon7:kIconBack7 old:kIconBack]
								style:style
								target:self action:@selector(webBackButton:)] autorelease];
    self.webBack.accessibilityLabel = @"Back";

	
	self.webForward = [[[UIBarButtonItem alloc]
                            initWithImage:[TableViewWithToolbar getToolbarIcon7:kIconForward7 old:kIconForward]
                                style:style
								target:self action:@selector(webForwardButton:)] autorelease];
    self.webForward.accessibilityLabel = @"Forward";
	self.webForward.style = style;

	
	if (self.rawDataToDisplay == nil && self.localURL == nil)
	{

        [toolbarItems addObject:self.webBack];
        [toolbarItems addObject:[UIToolbar autoFlexSpace]];
        [toolbarItems addObject:self.webForward];
        [toolbarItems addObject:[UIToolbar autoFlexSpace]];
        [toolbarItems addObject:self.safari];
        [toolbarItems addObject:[UIToolbar autoFlexSpace]];
    }
        
    
    [toolbarItems addObject:[self autoDoneButton]];
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];

}

#pragma mark UI callbacks

-(void)safariButton:(UIBarButtonItem*)sender
{
    NSURL *address = [NSURL URLWithString:[self.webView stringByEvaluatingJavaScriptFromString:@"document.URL"]];
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Safari", @"alert title")
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Open in Safari", @"alert title")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action){
                                                [[UIApplication sharedApplication] openURL:address];
                                            }]];
    
    if ([OpenInChromeController sharedInstance].isChromeInstalled)
    {
        
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Open in Chrome", @"button text")
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action){
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

-(void)webForwardButton:(id)sender
{
	[self.webView goForward];
}

-(void)webBackButton:(id)sender
{
	if (self.webView.canGoBack)
	{
		[self.webView goBack];
		_depth --;
		
		if (_depth == 0 && self.dataToDisplay!=nil)
		{
			self.safari.enabled = NO;
		}
		else {
			self.safari.enabled = YES;
		}
		
	}
	else
	{
		[self.navigationController popViewControllerAnimated:YES];
	}
}


#pragma mark View methods


// OK - we need a little adjustment here for iOS7.  It took we a while to get this right - I'm exactly
// sure what is going on but on the iPad we need to make the height a little bigger in some cases.
// Annoying.

- (CGFloat) heightOffset
{
    if (LARGE_SCREEN || (self.screenInfo.screenWidth == WidthBigVariable))
    {
        return -[UIApplication sharedApplication].statusBarFrame.size.height;
    }
	return 0.0;
}

					  
- (void)loadView {
	[super loadView];
	
	// Set the size for the table view
	CGRect webViewRect = [self getMiddleWindowRect];
	///webViewRect.size.width = [[UIScreen mainScreen] applicationFrame].size.width;
	//webViewRect.size.height = [[UIScreen mainScreen] applicationFrame].size.height - [self heightOffset];
	//webViewRect.origin.x = 0;
	//webViewRect.origin.y = 0;
	
	// Create a table viiew
	self.webView = [[[UIWebView alloc] initWithFrame:webViewRect] autorelease];
	// set the autoresizing mask so that the table will always fill the view
	self.webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
	
	self.webView.backgroundColor = [UIColor whiteColor];
	self.webView.scalesPageToFit = YES;

	
	
	// set the tableview delegate to this object
	self.webView.delegate = self;	

		
	
	[self.view addSubview:self.webView];
	
	if (self.rawDataToDisplay !=nil)
	{
		NSString *path = [NSBundle mainBundle].bundlePath;
		NSURL *baseURL = [NSURL fileURLWithPath:path];
		
		// Remove the apps ID from the data
		NSMutableString *stringData = [[NSMutableString alloc] initWithData:self.rawDataToDisplay encoding:NSUTF8StringEncoding];
		
		[stringData replaceOccurrencesOfString:TRIMET_APP_ID 
									withString:@"[hidden application ID]" 
									   options:NSCaseInsensitiveSearch 
										 range:NSMakeRange(0, stringData.length)];

		
		// [self.webView loadData:self.rawDataToDisplay MIMEType:@"text/html" textEncodingName:@"UTF-8" baseURL:baseURL];
		[self.webView loadHTMLString:stringData baseURL:baseURL];
		
		[stringData release];
	}
	else if (self.dataToDisplay != nil)
	{
		[self.webView loadHTMLString:self.dataToDisplay baseURL:nil];
	}
	else if (self.localURL)
	{
		[self.webView loadRequest:[NSURLRequest requestWithURL:self.localURL]];
	}
	else
	{
		[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlToDisplay]]];
	}
	
}



- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}




#pragma mark UIWebView delegate methods


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
#ifdef DEBUG
	NSURL *url = request.URL;
    NSString * reqStr = url.absoluteString;
	
	DEBUG_LOG(@"%@", reqStr);
#endif
	
	if (_depth == 0 && self.dataToDisplay!=nil)
	{
		self.safari.enabled = NO;
	}
	else {
		self.safari.enabled = YES;
	}

	
	self.webBack.enabled = YES; // webView.canGoBack;
	self.webForward.enabled = webView.canGoForward;
	// [self.toolbar setNeedsDisplay];
	return YES;
}



- (void)webViewDidStartLoad:(UIWebView *)webView
{
	// starting the load, show the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	if (_depth > 0)
	{
		self.safari.enabled = YES;
	}
	_depth ++;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	// finished loading, hide the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	
	self.webBack.enabled = YES;
	self.webForward.enabled = webView.canGoForward;
	
	self.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
	
	// NSHTTPCookie *cookie;
	//for (cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
	//	NSLog(@"%@", [cookie description]);
	//}
	
	NSString *js = @"\
        var d = document.getElementsByTagName('a');\
        for (var i = 0; i < d.length; i++) {\
			if (d[i].getAttribute('target') != null) {\
				d[i].removeAttribute('target');\
			}\
        }\
        ";
		
	[webView stringByEvaluatingJavaScriptFromString:js];

	

}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	// load error, hide the activity indicator in the status bar
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	
	if (self.showErrors)
	{
		// report the error inside the webview
		NSString* errorString = [NSString stringWithFormat:
							 @"<html><center><font size=+5 color='red'>An error occurred:<br>%@</font></center></html>",
							 error.localizedDescription];
		[webView loadHTMLString:errorString baseURL:nil];
	}
	else {
		if (!([error.domain isEqualToString:@"NSURLErrorDomain"] && error.code==-999))
		{
            UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Web Page Error", @"page title")
														   message:error.localizedDescription
														  delegate:nil
												 cancelButtonTitle:NSLocalizedString(@"OK", @"button text")
												 otherButtonTitles:nil ] autorelease];
			[alert show];
		}
	}

}

- (bool)openSafariFrom:(UIViewController *)view path:(NSString *)path
{
    if ( [self iOS9style] )
    {
        return [super openSafariFrom:view path:path];
    }
    
    return FALSE;
}

+ (void)displayPage:(NSString *)mobile
               full:(NSString*)full
          navigator:(UINavigationController *)nav
     itemToDeselect:(id<DeselectItemDelegate>)deselect
           whenDone:(UIViewController*)whenDone
{
    
    WebViewController *webPage = [WebViewController viewController];
    
    [webPage setURLmobile:mobile full:full];
    
    webPage.whenDone = whenDone;
    webPage.showErrors = NO;
    
    [webPage displayPage:nav animated:YES itemToDeselect:deselect];
}


- (void)displayPage:(UINavigationController *)nav animated:(BOOL)animated itemToDeselect:(id<DeselectItemDelegate>)deselect
{
    if ([UserPrefs sharedInstance].useChrome && [OpenInChromeController sharedInstance].isChromeInstalled && self.urlToDisplay!=nil)
    {
        [[OpenInChromeController sharedInstance] openInChrome:[NSURL URLWithString:self.urlToDisplay]
                                              withCallbackURL:[NSURL URLWithString:@"pdxbus:"]
                                                 createNewTab:NO];
        
        if (deselect)
        {
            [deselect deselectItemCallback];
        }
    } else if ([self openSafariFrom:nav path:self.urlToDisplay])
    {
        if (deselect)
        {
            [deselect deselectItemCallback];
        }
    }
    else
    {
        [nav pushViewController:self animated:animated];
    }
}


@end
