//
//  ViewControllerBase.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/21/10.
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

#import "ViewControllerBase.h"
#import "FindByLocationView.h"
#import "FlashViewController.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"
#import "WebViewController.h"
#import "NetworkTestView.h"
#import "RssView.h"
#import <Twitter/TWTweetComposeViewController.h>

#define kTweetButtonList        1
#define kTweetButtonTweet       2
#define kTweetButtonApp         3
#define kTweetButtonWeb         4
#define kTweetButtonCancel      5


@implementation UINavigationController (Rotation_IOS6)

-(BOOL)shouldAutorotate
{
    return [[self.viewControllers lastObject] shouldAutorotate];
}

-(NSUInteger)supportedInterfaceOrientations
{
    return [[self.viewControllers lastObject] supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return [[self.viewControllers lastObject] preferredInterfaceOrientationForPresentation];
}

@end

@implementation ViewControllerBase

@synthesize backgroundTask	= _backgroundTask;
@synthesize callback		= _callback;
@synthesize docMenu             = _docMenu;


- (void)dealloc {
    //
    // There is a weak reference to self in the background task - it must
    // be removed if we are dealloc'd.
    //
    if (self.backgroundTask)
    {
        self.backgroundTask.callbackComplete = nil;
	}
    self.backgroundTask = nil;
	self.callback		= nil;
    self.docMenu        = nil;
    self.tweetAlert     = nil;
    self.tweetAt        = nil;
    self.initTweet      = nil;
    
	[_userData release];
	[super dealloc];
}

- (UIColor*)htmlColor:(int)val
{
	return [UIColor colorWithRed:((CGFloat)((val >> 16) & 0xFF))/255.0 
						   green:((CGFloat)((val >> 8) & 0xFF))/255.0 
							blue:((CGFloat)(val & 0xFF))/255.0 alpha:1.0];

}



- (void)setTheme
{
	int color = [UserPrefs getSingleton].toolbarColors;
	
	if (color == 0xFFFFFF)
	{
		self.navigationController.toolbar.tintColor = nil;
		self.navigationController.navigationBar.tintColor = nil;
	}
	else 
	{
		self.navigationController.toolbar.tintColor = [self htmlColor:color]; 
		self.navigationController.navigationBar.tintColor = [self htmlColor:color]; 
	}
}


- (bool)initMembers
{
	if (self.backgroundTask == nil)
	{
        _userData = [[SafeUserData getSingleton] retain];
		self.backgroundTask = [BackgroundTaskContainer create:self];
		return true;
	}
	return false;
}

- (id)init {
	if ((self = [super init]))
	{
		[self initMembers];
	}
	return self;
}


#pragma mark Overridden View Methods

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	
	[super loadView];
	
	[[self navigationController] setToolbarHidden:NO animated:NO];	 
	
	[self setTheme];
		
	[self createToolbarItems];
 }


- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}
 

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
//	[self.view bringSubviewToFront:self.toolbar];
}

// iOS6 methods

- (BOOL)shouldAutorotate {
    
    if (self.backgroundTask.backgroundThread !=nil)
    {
        return NO;
    }
    return YES;

}

- (NSUInteger)supportedInterfaceOrientations {
    CGRect bounds = [[UIScreen mainScreen] bounds];
	
	// Small devices do not need to orient
	if (bounds.size.width <= kLargestSmallScreenDimension)
	{
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


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	CGRect bounds = [[UIScreen mainScreen] bounds];
	
	// Small devices do not need to orient
	if (bounds.size.width <= kLargestSmallScreenDimension)
	{
		return interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIDeviceOrientationPortraitUpsideDown;
	}
	
	if (self.backgroundTask.backgroundThread !=nil)
	{
		return NO;
	}
	return YES;
}

- (void)viewWillAppear:(BOOL)animated {
	[[self navigationController] setToolbarHidden:NO animated:YES];
	
}



#pragma mark View helper methods

- (void)reloadData
{

}

- (ScreenType)screenWidth
{
	CGRect bounds = [[UIScreen mainScreen] bounds];
	
	switch (self.interfaceOrientation)
	{
		case UIInterfaceOrientationPortraitUpsideDown:	
		case UIInterfaceOrientationPortrait:
			if (bounds.size.width <= kSmallestSmallScreenDimension)
			{
				return WidthiPhoneNarrow;
			}
			return WidthiPadNarrow;
		case	UIInterfaceOrientationLandscapeLeft:
		case	UIInterfaceOrientationLandscapeRight:
			return WidthiPadWide;
	}

	return WidthiPadWide;
}

- (CGFloat) heightOffset
{
	return 0.0;
}


- (CGRect)getMiddleWindowRect
{
	CGRect tableViewRect;
	tableViewRect.size.width = [[UIScreen mainScreen] applicationFrame].size.width;
	tableViewRect.size.height = [[UIScreen mainScreen] applicationFrame].size.height-[self heightOffset];
	tableViewRect.origin.x = 0;
	tableViewRect.origin.y = 0;
	return tableViewRect;
}

	

- (UIView *)clearView
{
	UIView *backView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
	backView.backgroundColor = [UIColor clearColor];
	return backView;
}

- (void)setBackfont:(UILabel *)label
{
	label.font =  TableViewBackFont;
	label.textColor = [UIColor colorWithRed:0.30f green:0.34f blue:0.42f alpha:1.0];
	label.shadowColor = [UIColor whiteColor];
	label.shadowOffset = CGSizeMake(0.0f, 1.0f);
	label.backgroundColor = [UIColor clearColor];
}

- (NSString *)justNumbers:(NSString *)text
{
	NSMutableString *res = [[[NSMutableString alloc] init] autorelease];
	
	int i=0;
	unichar c;
	
	for (i=0; i< [text length]; i++)
	{
		c = [text characterAtIndex:i];
		
		if (isnumber(c))
		{
			[res appendFormat:@"%C", c];
		}
	}
	
	return res;
	
}


- (void)notRailAwareButton:(int)button
{
	if (button == kRailAwareReloadButton)
	{
		FindByLocationView *findView = [[FindByLocationView alloc] init];
		
		// Push the detail view controller
		[[self navigationController] pushViewController:findView animated:YES];
		[findView release];
		
	}
}

- (void)noLocations:(NSString *)title delegate:(id<UIAlertViewDelegate>) delegate
{
	if (title == nil)
	{
		title = @"Nearby stops";
	}
	UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:title
													   message:@"You must download the stop location database to be able to locate stops. Do you want to do that now?"
													  delegate:delegate
											 cancelButtonTitle:@"No"
											 otherButtonTitles:@"Yes", nil ] autorelease];
	[alert show];
	
	
}

- (void)notRailAwareAlert:(id<UIAlertViewDelegate>) delegate
{
	UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"Nearest Rail Stations"
													   message:@"The stop location database is out-of-date as it does not contain rail specific information. You must update the database to be able to find rail stations. Do you want to do that now?"
													  delegate:delegate
											 cancelButtonTitle:@"No"
											 otherButtonTitles:@"Yes", nil ] autorelease];
	[alert show];
	
	
}


#pragma mark Icon methods


- (UIImage *)alwaysGetIcon:(NSString *)name
{
	return [ViewControllerBase alwaysGetIcon:name];
}

+ (UIImage *)alwaysGetIcon:(NSString *)name
{
    UIImage *image = [UIImage imageNamed:name];
    image.accessibilityHint = nil;
    image.accessibilityLabel = nil;
	return image; 
}

+ (UIImage *)getToolbarIcon:(NSString *)name
{
	return [self alwaysGetIcon:name];
}

- (UIImage *)getActionIcon:(NSString *)name
{
	if ([UserPrefs getSingleton].actionIcons)
	{
		return [self alwaysGetIcon:name];
	}
	return nil;
}

- (UIImage *)getFaveIcon:(NSString *)name
{
	if ([UserPrefs getSingleton].actionIcons)
	{
		return [self alwaysGetIcon:name];
	}
	return nil;
}

#pragma mark Toolbar methods

- (UIBarButtonItem *)autoDoneButton
{
	if (self.callback !=nil && ([self.callback getController] !=nil || [self forceRedoButton]))
	{
		return [CustomToolbar autoRedoButtonWithTarget:self action:@selector(backButton:)]; 
	}
	else
	{
		return [CustomToolbar autoDoneButtonWithTarget:self action:@selector(backButton:)]; 
	}

}

- (bool)forceRedoButton
{
	return false;
}

- (UIBarButtonItem *)autoFlashButton
{
	return [CustomToolbar autoFlashButtonWithTarget:self action:@selector(flashButton:)]; 
}

- (UIBarButtonItem *)autoBigFlashButton
{
	// create the system-defined "OK or Done" button
	UIBarButtonItem *flash = [[[UIBarButtonItem alloc]
							   initWithTitle:@"Night Visibility Flash" style:UIBarButtonItemStyleBordered 
							   target:self action:@selector(flashButton:)] autorelease];
	return flash;
}

- (void)appendXmlData:(NSMutableData *)buffer
{
    
}


- (void)xmlAction:(id)arg
{
    // This only for debugging so we can be a little bit slap dash.
    // We replace some items in the XML to hide it or to make the reader
    // happy when concatonating.  This was learnt by trial and error!
    NSArray *finders = [NSArray arrayWithObjects:
                        TRIMET_APP_ID,              // hide APP ID
                        @"<?xml", @"?>",            // XML encoding gets in the way
                        @"<--?xml", @"?-->",        // XML encoding gets in the way
                        @"<body", @"body>",         // This keyword gets dropped
                        nil];
    
    NSArray *replacers = [NSArray arrayWithObjects:
                          @"TRIMET_APP_ID",
                          @"<!--", @"-->",
                          @"<!--", @"-->",
                          @"<wasbody", @"wasbody>",
                          nil];


  
    NSMutableData *buffer = [[NSMutableData alloc] init];
       
    [self appendXmlData:buffer];
    
    
    
    if (self.docMenu)
    {
        [self.docMenu dismissMenuAnimated:YES];
        self.docMenu = nil;
        [buffer release];
    }
    else 
    {
        // NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
    
        NSString * filePath = [documentsDirectory stringByAppendingPathComponent:@"PDXBusData.xml"];
        
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    
 
        NSMutableString *redactedData = [[NSMutableString alloc] initWithBytes:buffer.bytes
                                                                         length:buffer.length
                                                                       encoding:NSUTF8StringEncoding];
        
        [buffer release];
        
        for (int i=0; i<finders.count; i++)
        {
            
            [redactedData replaceOccurrencesOfString:[finders objectAtIndex:i]
                                          withString:[replacers objectAtIndex:i]
                                             options:NSCaseInsensitiveSearch
                                               range:NSMakeRange(0, redactedData.length)];
        
        }
        
        [redactedData insertString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><root>" atIndex:0];
        [redactedData appendString:@"</root>"];
        
        DEBUG_LOG(@"%@", redactedData);
        if ([redactedData writeToFile:filePath atomically:FALSE encoding:NSUTF8StringEncoding error:nil])
        {
    
            self.docMenu = [UIDocumentInteractionController
                            interactionControllerWithURL:[NSURL fileURLWithPath:filePath]];
            self.docMenu.delegate = self;
            self.docMenu.UTI = @"data.xml";

            if (self.xmlButton)
            {
                [self.docMenu presentOpenInMenuFromBarButtonItem:self.xmlButton animated:YES];
            }
            else
            {
                UIView *view = self.navigationController.view;
                CGRect rect = CGRectZero;
            
                if (arg!=nil)
                {
                    UIView *button = arg;
                    rect = [view convertRect:button.frame fromView:button.superview];
                }
                [self.docMenu presentOpenInMenuFromRect:rect
                                                 inView:view
                                               animated:YES];
        
            }
        }
        else
        {
            UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:@"XML error"
                                                               message:@"Could not write to file."
                                                              delegate:nil
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil] autorelease];
            [alert show];
        }
        
        [redactedData release];
    }
}

- (UIBarButtonItem*)autoXmlButton
{
    // create the system-defined "OK or Done" button
	self.xmlButton = [[[UIBarButtonItem alloc]
                             initWithImage:[TableViewWithToolbar getToolbarIcon:kIconXml]
                             style:UIBarButtonItemStylePlain
							 target:self action:@selector(xmlAction:)] autorelease];
    
	self.xmlButton.style = UIBarButtonItemStylePlain;
	self.xmlButton.accessibilityLabel = @"Show XML";
	
	return self.xmlButton;
}



- (void)createToolbarItems
{
	NSArray *items = [NSArray arrayWithObjects: [self autoDoneButton], [CustomToolbar autoFlexSpace], [self autoFlashButton], nil];
	[self setToolbarItems:items animated:NO];
}

- (void)createToolbarItemsWithXml
{    
    if ([UserPrefs getSingleton].debugXML)
    {
        NSArray *items = [NSArray arrayWithObjects:
                                [self autoDoneButton],
                                [CustomToolbar autoFlexSpace],
                                [self autoXmlButton],
                                [CustomToolbar autoFlexSpace],
                                [self autoFlashButton],
                                 nil];
        [self setToolbarItems:items animated:NO];

    }
    else
    {
        NSArray *items = [NSArray arrayWithObjects: [self autoDoneButton], [CustomToolbar autoFlexSpace], [self autoFlashButton], nil];
        [self setToolbarItems:items animated:NO];
    }
}


-(void)backButton:(id)sender
{
	if (self.callback !=nil && [self.callback getController] !=nil)
	{
		[[self navigationController] popToViewController:[self.callback getController] animated:YES];
	}
	else
	{
		[[self navigationController] popToRootViewControllerAnimated:YES];
	}
}

+ (void)flashScreen:(UINavigationController *)nav
{
	FlashViewController *flash = [[FlashViewController alloc] init];
	[nav pushViewController:flash animated:YES];
	[flash release];
}


-(void)flashButton:(id)sender
{
	[TableViewWithToolbar flashScreen:[self navigationController]];
}


- (void)showRouteSchedule:(NSString *)route
{
	WebViewController *webPage = [[WebViewController alloc] init];
	NSMutableString *padding = [[NSMutableString alloc] init];
	
	webPage.whenDone = [self.callback getController];
	[self padRoute:route padding:&padding];
	[webPage setURLmobile: [NSString stringWithFormat:@"http://www.trimet.org/schedules/r%@.htm",padding]
					 full:nil
					title:@"Map & schedule"]; 
	[[self navigationController] pushViewController:webPage animated:YES];
	[webPage release];
	[padding release];
	
}

#pragma mark Common actions

- (void)showRouteAlerts:(NSString *)route fullSign:(NSString *)fullSign
{
	RssView *rssPage = [[RssView alloc] init];
	
	NSMutableString *padding = [[NSMutableString alloc] init];
	
	[self padRoute:route padding:&padding];
	
	// MAX Route Conversion
	NSScanner *scanner = [NSScanner scannerWithString:fullSign];
	
	[scanner setCaseSensitive:YES];
	
	NSString *tmp = nil;
	[scanner scanUpToString:@"MAX" intoString:&tmp];
	
	if (![scanner isAtEnd])
	{
		[padding setString:@"100"];
	}
	
	// WES Route conversion
	if ([route isEqualToString:@"203"])
	{
		[padding setString:@"40"];
	}
	
	rssPage.callback = self.callback;
	
	[rssPage fetchRssInBackground:self.backgroundTask url:[NSString stringWithFormat:@"http://service.govdelivery.com/service/rss/item_updates.rss?code=ORTRIMET_%@", padding]];
	 

	[rssPage release];
	[padding release];
	
}

- (void) padRoute:(NSString *)route padding:(NSMutableString **)padding
{
	while ([route length] + [*padding length] < 3)
	{
		[*padding appendString:@"0"];
	}
	[*padding appendString:route];
}

- (void)networkTips:(NSData*)htmlError networkError:(NSString *)networkError
{
	
	if (htmlError)
	{
		WebViewController *errorScreen = [[WebViewController alloc] init];
		[errorScreen setRawData:htmlError title:@"Error Message"];
		[[self navigationController] pushViewController:errorScreen animated:YES];
		[errorScreen release];
	}
	else {
		NetworkTestView *networkTest = [[NetworkTestView alloc] init];
		networkTest.networkErrorFromQuery = networkError;
		[networkTest fetchNetworkStatusInBackground:self.backgroundTask];
		[networkTest release];
	}
}

#pragma mark Text Manipulation Methods

- (UILabel *)create_UITextView:(UIColor *)backgroundColor font:(UIFont *)font;
{
	CGRect frame = CGRectMake(0.0, 0.0, 100.0, 200.0);
	
	
	UILabel *textView = [[[UILabel alloc] initWithFrame:frame] autorelease];
    textView.textColor = [UIColor blackColor];
    textView.font = font; // ;
	//    textView.delegate = self;
	//	textView.editable = NO;
	if (backgroundColor ==nil)
	{
		textView.backgroundColor = [UIColor clearColor];
	}
	else
	{
		textView.backgroundColor = backgroundColor;
		
	}
	textView.lineBreakMode =   UILineBreakModeWordWrap;
	textView.adjustsFontSizeToFitWidth = YES;
	textView.numberOfLines = 0;
	
	// note: for UITextView, if you don't like autocompletion while typing use:
	// myTextView.autocorrectionType = UITextAutocorrectionTypeNo;
	
	return textView;
}



#pragma mark Background Task methods

-(void)BackgroundTaskDone:(UIViewController *)viewController cancelled:(bool)cancelled
{
	if (!cancelled)
	{
		[self.navigationController pushViewController:viewController animated:YES];
	}
}

- (UIInterfaceOrientation)BackgroundTaskOrientation
{
	return self.interfaceOrientation;	
}

#pragma mark Standard Object methods


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


#pragma mark Document interaction methods

-(void)documentInteractionController:(UIDocumentInteractionController *)controller
       willBeginSendingToApplication:(NSString *)application {
    
}

-(void)documentInteractionController:(UIDocumentInteractionController *)controller
          didEndSendingToApplication:(NSString *)application {
    self.docMenu = nil;
}

-(void)documentInteractionControllerDidDismissOpenInMenu:
(UIDocumentInteractionController *)controller {
    //   [controller dismissMenuAnimated:YES];
    self.docMenu = nil;
}

- (void) tweet
{
    self.tweetAlert = [[[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"@%@ on Twitter", self.tweetAt]
                                                   delegate:self
                                          cancelButtonTitle:nil
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:nil] autorelease];
    
    
    
    if ([[TriMetTimesAppDelegate getSingleton] canTweet])
    {
        _tweetButtons[ [self.tweetAlert addButtonWithTitle:@"Send tweet"] ] = kTweetButtonTweet;
    }
    
    
    NSString *twitter=[NSString stringWithFormat:@"twitter:"];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:twitter]])
    {
        _tweetButtons[ [self.tweetAlert addButtonWithTitle:@"Show in Twitter app"] ] = kTweetButtonApp;
    }
    
    _tweetButtons[ [self.tweetAlert addButtonWithTitle:@"Show in Safari"] ] = kTweetButtonWeb;
    
    
    // _tweetButtons[[sheet addButtonWithTitle:@"Recent tweets"] ] = kTweetButtonList;
    
    self.tweetAlert.cancelButtonIndex  = [self.tweetAlert addButtonWithTitle:@"Cancel"];
    _tweetButtons[self.tweetAlert.cancelButtonIndex ] = kTweetButtonCancel;
    
    [self.tweetAlert showFromToolbar:self.navigationController.toolbar];
    
}


-(void)clearSelection
{
    
}

- (void)facebook
{
    static NSString *fb=@"fb://profile/218101161593";
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:fb]])
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fb]];
    }
    else
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://m.facebook.com/PDXBus"]];
    }
    [self clearSelection];
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
{
    
    if (actionSheet != self.tweetAlert)
    {
        return;
    }
    switch (_tweetButtons[buttonIndex])
    {
        default:
        case kTweetButtonApp:
        {
            NSString *twitter=[NSString stringWithFormat:@"twitter://user?screen_name=%@", self.tweetAt];
            
            if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:twitter]])
            {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:twitter]];
                [self clearSelection];
            }
            break;
        }
        case kTweetButtonWeb:
        {
            NSString *twitter=[NSString stringWithFormat:@"https://mobile.twitter.com/%@", self.tweetAt];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:twitter]];
            [self clearSelection];
            break;
        }
            
        case kTweetButtonCancel:
        {
            [self clearSelection];
            break;
        }
        case kTweetButtonList:
        {
            
            RssView *rss = [[[RssView alloc] init] autorelease];
            
            rss.gotoOriginalArticle = YES;
            
            [rss fetchRssInBackground:self.backgroundTask url:[NSString stringWithFormat:@"http://api.twitter.com/1/statuses/user_timeline.rss?screen_name=%@", self.tweetAt]];
            break;
        }
            
        case kTweetButtonTweet:
        {
            TWTweetComposeViewController *picker = [[TWTweetComposeViewController alloc] init];
            [picker setInitialText:self.initTweet];
            
            picker.completionHandler =
            ^(TWTweetComposeViewControllerResult result) {
                [self clearSelection];
                [self dismissModalViewControllerAnimated:YES];
            };
            
            [self presentModalViewController:picker animated:YES];
            
            [picker release];
            break;
        }
    }
}




@end
