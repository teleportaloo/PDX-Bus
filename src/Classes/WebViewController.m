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
@synthesize rssLinks		= _rssLinks;
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
	self.rssLinks = nil;
	self.rawDataToDisplay = nil;
	[super dealloc];
}

- (id)init {
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
	map = false;
}

- (void)setURLmobile:(NSString *)url full:(NSString *)full
{
	if (LargeScreenStyle([self screenWidth]) && full!=nil)
	{
		self.urlToDisplay = full;
	}
	else {
		self.urlToDisplay = url;

	}

	self.title = NSLocalizedString(@"Loading page...", @"Initial web page title");
	map = false;
}


- (void)setRssItem:(RssLink *)rss title:(NSString *)title
{
	if (title == nil)
	{
		title = self.title;
	}
	self.dataToDisplay = [NSString stringWithFormat:
							  @"<html><head><title>%@</title></title>"
							  "<meta name=\"viewport\" content=\"user-scalable=yes, width=device-width\" />"
							  "<body>"					
							  "<b>%@</b>"		  
							  //"<div style=\"font-family:Helvetica; font-size:40px;\">"
							  "<div style=\"color:blue\"><b>%@</b></div>"
							  // "<br><div style=\"font-size:48px\"><b>%@</b></div>"
							  "<br>%@</br>"
							  //"<hr><div style=\"font-size:40px\"><br>%@<br>"
							  "<a href=\"%@\">Original article</a></div></div></body></html>",
							  title, rss.dateString, rss.title, rss.description, rss.link];

	map = false;
}

- (void)setMapLocationLat:(NSString *)lat lng:(NSString *)lng title:(NSString *)title
{
	self.title = title;
	self.dataToDisplay = [NSString stringWithFormat:

	@"<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\""
    "\"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">"
	"<html xmlns=\"http://www.w3.org/1999/xhtml\" xmlns:v=\"urn:schemas-microsoft-com:vml\">"
	"<head>"
    "<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\"/>"
	"<meta name=\"viewport\" content=\"width=320\" />"
    "<title>Google Maps JavaScript API Example: Simple Map</title>"
    "<script src=\"http://maps.google.com/maps?file=api&amp;v=2&amp;sensor=false&amp;key=ABQIAAAAq1xdzF_EwAwcKpHZKuXgbBQDwXD5r-eygncUTK_xh7woMivbuRQhVUe2iZwzc3GcAxdUkMjKTTqMcg\""
	"type=\"text/javascript\"></script>"
    "<script type=\"text/javascript\">"
	""
    "function initialize() {"
	"	if (GBrowserIsCompatible()) {"
	"		var map = new GMap2(document.getElementById(\"map_canvas\"));"
	"		var point = new  GLatLng(%@, %@);"
	"		map.setCenter(point, 15);"
	"		map.addOverlay(new GMarker(point));"
	"		map.addControl(new GMapTypeControl());"
	"		map.addControl(new GSmallMapControl());"
	"	}"
    "}"
	""
    "</script>"
	"</head>"
	""
	"<body onload=\"initialize()\" onunload=\"GUnload()\">"
    "<div id=\"map_canvas\" style=\"width: 305px; height: 360px\"></div>"
	"</body>"
	"</html>",lat, lng];
	
	self.urlToDisplay = [NSString stringWithFormat:@"http://map.google.com/?q=location@%@,%@",  
						 lat, lng];
	map = true;
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
        [toolbarItems addObject:[CustomToolbar autoFlexSpace]];
        [toolbarItems addObject:self.webForward];
        [toolbarItems addObject:[CustomToolbar autoFlexSpace]];
        [toolbarItems addObject:self.safari];
        [toolbarItems addObject:[CustomToolbar autoFlexSpace]];
    }
        
    
    [toolbarItems addObject:[self autoDoneButton]];
    [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];

}

#pragma mark UI callbacks

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSURL *address = [NSURL URLWithString:[self.webView stringByEvaluatingJavaScriptFromString:@"document.URL"]];
    OpenInChromeController *chrome = [OpenInChromeController sharedInstance];
    
	if (buttonIndex == 0)
	{
		[[UIApplication sharedApplication] openURL:address];
	}
    
    if (chrome.isChromeInstalled && buttonIndex == 1)
    {
        [[OpenInChromeController sharedInstance] openInChrome:address
                                              withCallbackURL:[NSURL URLWithString:@"pdxbus://back"]
                                                 createNewTab:YES];
    }
}

-(void)safariButton:(id)sender
{
	
	if (map)
	{
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Exit to Google Maps"
																 delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
														otherButtonTitles:@"Show on Google Maps", nil];
		actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
		[actionSheet showFromToolbar:self.navigationController.toolbar]; // show from our table view (pops up in the middle of the table)
		[actionSheet release];
	}
	else
	{
		UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Safari"
															 delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil
													otherButtonTitles:@"Show in Safari", nil];
        
        if ([OpenInChromeController sharedInstance].isChromeInstalled)
        {
            [actionSheet addButtonWithTitle:@"Show in Chrome"];
        }
        
        actionSheet.cancelButtonIndex  = [actionSheet addButtonWithTitle:@"Cancel"];
		actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
		[actionSheet showFromToolbar:self.navigationController.toolbar]; // show from our table view (pops up in the middle of the table)
		[actionSheet release];
	}
	
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
		[[self navigationController] popViewControllerAnimated:YES];
	}
}

#pragma mark Up down arrow

- (void)enableArrows:(UISegmentedControl*)seg
{
	[seg setEnabled:(_rssLinkItem > 0) forSegmentAtIndex:0];
	
	[seg setEnabled:(_rssLinkItem < (self.rssLinks.count-1)) forSegmentAtIndex:1];
	
}

- (void)upDown:(id)sender
{
	UISegmentedControl *segControl = sender;
	switch (segControl.selectedSegmentIndex)
	{
		case 0:	// UIPickerView
		{
			// Up
			if (_rssLinkItem > 0)
			{
				[self setRssItem:[self.rssLinks objectAtIndex:_rssLinkItem-1] title:nil];
				 _rssLinkItem--;
			}
			break;
		}
		case 1:	// UIPickerView
		{
			if (_rssLinkItem < (self.rssLinks.count-1) )
			{
				[self setRssItem:[self.rssLinks objectAtIndex:_rssLinkItem+1] title:nil];
				_rssLinkItem++;
			}
			break;
		}
	}
	[self.webView loadHTMLString:self.dataToDisplay baseURL:nil];
	[self enableArrows:segControl];
	
}

#pragma mark View methods


// OK - we need a little adjustment here for iOS7.  It took we a while to get this right - I'm exactly
// sure what is going on but on the iPad we need to make the height a little bigger in some cases.
// Annoying.

- (CGFloat) heightOffset
{
    if (self.iOS7style && (LargeScreenStyle([self screenWidth]) || (self.screenWidth == WidthiPadNarrow)))
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
		NSString *path = [[NSBundle mainBundle] bundlePath];
		NSURL *baseURL = [NSURL fileURLWithPath:path];
		
		// Remove the apps ID from the data
		NSMutableString *stringData = [[NSMutableString alloc] initWithData:self.rawDataToDisplay encoding:NSUTF8StringEncoding];
		
		[stringData replaceOccurrencesOfString:TRIMET_APP_ID 
									withString:@"[hidden application ID]" 
									   options:NSCaseInsensitiveSearch 
										 range:NSMakeRange(0, [stringData length])];

		
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
	
	
		
	if (self.rssLinks != nil)
	{
		UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects: 
																			 [TableViewWithToolbar getToolbarIcon7:kIconUp7 old:kIconUp],
																			 [TableViewWithToolbar getToolbarIcon7:kIconDown7 old:kIconDown], nil] ];
		seg.frame = CGRectMake(0, 0, 60, 30.0);
		seg.segmentedControlStyle = UISegmentedControlStyleBar;
		seg.momentary = YES;
		[seg addTarget:self action:@selector(upDown:) forControlEvents:UIControlEventValueChanged];
		
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView: seg]
                                                    autorelease];
		
		[self enableArrows:seg];
		[seg release];
		
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
	
	
	if ([self showErrors])
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
			UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Web Page Error"
														   message:error.localizedDescription
														  delegate:nil
												 cancelButtonTitle:@"OK"
												 otherButtonTitles:nil ] autorelease];
			[alert show];
		}
	}

}


- (void)displayPage:(UINavigationController *)nav animated:(BOOL)animated itemToDeselect:(id<DeselectItemDelegate>)deselect
{
    if ([UserPrefs getSingleton].useChrome && [OpenInChromeController sharedInstance].isChromeInstalled && self.urlToDisplay!=nil)
    {
        [[OpenInChromeController sharedInstance] openInChrome:[NSURL URLWithString:self.urlToDisplay]
                                              withCallbackURL:[NSURL URLWithString:@"pdxbus:"]
                                                 createNewTab:NO];
        
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
