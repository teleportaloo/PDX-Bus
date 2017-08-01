//
//  ViewControllerBase.m
//  PDX Bus
//
//  Created by Andrew Wallace on 2/21/10.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "ViewControllerBase.h"
#import "FindByLocationView.h"
#import "FlashWarning.h"
#import "FlashViewController.h"
#import "WebViewController.h"
#import "NetworkTestView.h"
#import <Social/Social.h>
#import "OpenInChromeController.h"
#import "TicketAlert.h"
#import "UserPrefs.h"
#import "MemoryCaches.h"
#import "TriMetTimesAppDelegate.h"
#import "AppDelegateMethods.h"
#import "InterfaceOrientation.h"
#import "SafariServices/SafariServices.h"
#import "RootViewController.h"
#import "WatchAppContext.h"
#import "TriMetRouteColors.h"

enum
{
    kTweetButtonTweet,
    kTweetButtonApp,
    kTweetButtonWeb,
    kTweetButtonCancel
};
    

@implementation UINavigationController (Rotation_IOS6)

-(BOOL)shouldAutorotate
{
    return self.viewControllers.lastObject.shouldAutorotate;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return self.viewControllers.lastObject.supportedInterfaceOrientations;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return self.viewControllers.lastObject.preferredInterfaceOrientationForPresentation;
}

@end

@implementation ViewControllerBase

@synthesize backgroundTask	 = _backgroundTask;
@synthesize callback		 = _callback;
@synthesize docMenu          = _docMenu;
@synthesize tweetButtons     = _tweetButtons;


+ (instancetype)viewController
{
   return [[[[self class] alloc] init] autorelease]; 
}

- (void)dealloc {
    //
    // There is a weak reference to self in the background task - it must
    // be removed if we are dealloc'd.
    //
    if (self.backgroundTask)
    {
        self.backgroundTask.callbackComplete = nil;
	}
    self.backgroundTask   = nil;
	self.callback		  = nil;
    self.docMenu          = nil;
    self.tweetAlert       = nil;
    self.tweetAt          = nil;
    self.initTweet        = nil;
    self.xmlButton        = nil;
    self.tweetButtons     = nil;
    
	[_userData release];
	[super dealloc];
}

+ (UIColor*)htmlColor:(int)val
{
	return [UIColor colorWithRed:((CGFloat)((val >> 16) & 0xFF))/255.0 
						   green:((CGFloat)((val >> 8) & 0xFF))/255.0 
							blue:((CGFloat)(val & 0xFF))/255.0 alpha:1.0];

}

- (void)setTheme
{
    int color = [UserPrefs singleton].toolbarColors;
    
    if (color == 0xFFFFFF)
    {
        self.navigationController.toolbar.barTintColor = nil;
        self.navigationController.navigationBar.barTintColor = nil;
        self.navigationController.toolbar.tintColor = nil;
        self.navigationController.navigationBar.tintColor = nil;
    }
    else
    {
        self.navigationController.toolbar.barTintColor = [ViewControllerBase htmlColor:color];
        self.navigationController.navigationBar.barTintColor = [ViewControllerBase htmlColor:color];
        self.navigationController.toolbar.tintColor = [UIColor whiteColor];
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    }
}

- (bool)iOS9style
{
    return [UIDevice currentDevice].systemVersion.floatValue >= 9.0;
}


- (bool)iOS8style
{
    return [UIDevice currentDevice].systemVersion.floatValue >= 8.0;
}

- (bool)initMembers
{
	if (self.backgroundTask == nil)
	{
        _userData = [[SafeUserData singleton] retain];
		self.backgroundTask = [BackgroundTaskContainer create:self];
		return true;
	}
	return false;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
	{
		[self initMembers];
	}
	return self;
}

- (instancetype)init {
	if ((self = [super init]))
	{
		[self initMembers];
	}
	return self;
}

- (void)backToRootButtons:(NSMutableArray *)toolbarItems
{
    [toolbarItems addObject:[self autoDoneButton]];
    [toolbarItems addObject:[UIToolbar autoFlexSpace]];
}

- (void)updateToolbar
{
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
//	[self.view bringSubviewToFront:self.toolbar];
    
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
    
    if (self.backgroundTask.running)
    {
        return NO;
    }
    return YES;

}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    CGRect bounds = [UIScreen mainScreen].bounds;
	
	// Small devices do not need to orient
	if (bounds.size.width <= MaxiPhoneWidth)
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
    
    // ios 5 bug - just return NO
    
    return NO;
    
    /*
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
     */
}

#pragma mark View helper methods

- (void)reloadData
{

}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    if (!self.backgroundTask.running)
    {
        [self reloadData];
    }
}

- (ScreenInfo)screenInfo
{
    ScreenInfo res;
    
    CGRect bounds = [UIApplication sharedApplication].delegate.window.bounds;

    res.appWinWidth = bounds.size.width;
    
    CGRect deviceBounds = [UIScreen mainScreen].bounds;
    
    UIInterfaceOrientation orientation = [InterfaceOrientation getInterfaceOrientation:self];
    
    if (bounds.size.width < deviceBounds.size.width)
    {
        orientation = UIInterfaceOrientationPortrait;
    }
    
	switch (orientation)
	{
		case UIInterfaceOrientationPortraitUpsideDown:	
		case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationUnknown:
			if (bounds.size.width <= WidthiPhone)
			{
				res.screenWidth = WidthiPhone;
			}
            else if (bounds.size.width <= WidthiPhone6)
            {
                res.screenWidth = WidthiPhone6;
            }
            else if (bounds.size.width <= WidthiPhone6Plus)
            {
                res.screenWidth = WidthiPhone6Plus;
            }
            else if (bounds.size.width <= WidthBigVariable)
            {
                res.screenWidth = WidthBigVariable;
            }
            else
            {
                res.screenWidth = WidthBigVariable;
            }
            break;
		case	UIInterfaceOrientationLandscapeLeft:
		case	UIInterfaceOrientationLandscapeRight:
            if (bounds.size.width <= WidthiPadWide)
            {
                res.screenWidth = WidthiPadWide;
            }
            else
            {
                res.screenWidth = WidthBigVariable;
            }
            break;
        default:
            res.screenWidth = WidthiPadWide;
	}

	return res;
}

- (CGFloat) heightOffset
{
	return 0.0;
}


- (CGRect)getMiddleWindowRect
{
	CGRect tableViewRect;
    
    tableViewRect.size.width = self.navigationController.view.frame.size.width;
    
	tableViewRect.size.height = [UIScreen mainScreen].applicationFrame.size.height-[self heightOffset];
	tableViewRect.origin.x = 0;
	tableViewRect.origin.y = 0;
    
    DEBUG_LOGR(tableViewRect);
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
	NSMutableString *res = [NSMutableString string];
	
	int i=0;
	unichar c;
	
	for (i=0; i< text.length; i++)
	{
		c = [text characterAtIndex:i];
		
		if (isnumber(c))
		{
			[res appendFormat:@"%C", c];
		}
	}
	
	return res;
	
}


- (void)notRailAwareButton:(NSInteger)button
{
	if (button == kRailAwareReloadButton)
	{
		// Push the detail view controller
		[self.navigationController pushViewController:[FindByLocationView viewController] animated:YES];
	}
}

#pragma mark Icon methods


- (UIImage *)alwaysGetIcon:(NSString *)name
{
	return [ViewControllerBase alwaysGetIcon:name];
}

- (UIImage *)alwaysGetIcon7:(NSString *)name old:(NSString *)old
{
    UIImage* icon =[self alwaysGetIcon:name];
    return icon != nil ? icon : [self alwaysGetIcon:old];
}

+ (UIImage *)alwaysGetIcon:(NSString *)name
{
    UIImage *image = [UIImage imageNamed:name];
    image.accessibilityHint = nil;
    image.accessibilityLabel = nil;
	return image; 
}

+ (UIImage *)getToolbarIcon7:(NSString *)name old:(NSString *)old
{
    UIImage* icon =[self alwaysGetIcon:name];
	return icon != nil ? icon : [self alwaysGetIcon:old];
}

+ (UIImage *)getToolbarIcon:(NSString *)name
{
	return [self alwaysGetIcon:name];
}

- (UIImage *)getActionIcon:(NSString *)name
{
	if ([UserPrefs singleton].actionIcons)
	{
		return [self alwaysGetIcon:name];
	}
	return nil;
}

- (UIImage *)getActionIcon7:(NSString *)name old:(NSString *)old
{
	if ([UserPrefs singleton].actionIcons)
	{
        return [self alwaysGetIcon7:name old:old];
    }
	return nil;
}

- (UIImage *)getFaveIcon:(NSString *)name
{
	if ([UserPrefs singleton].actionIcons)
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
		return [UIToolbar autoRedoButtonWithTarget:self action:@selector(backButton:)];
	}
	else
	{
		return [UIToolbar autoDoneButtonWithTarget:self action:@selector(backButton:)];
	}

}

- (bool)forceRedoButton
{
	return false;
}

- (void)maybeAddFlashButtonWithSpace:(bool)space buttons:(NSMutableArray *)array big:(bool)big
{
    if ([UserPrefs singleton].flashingLightIcon)
    {
        
        if (space)
        {
            [array addObject:[UIToolbar autoFlexSpace]];
        }
    
        if (big)
        {
            [array addObject:[self autoBigFlashButton]];
        }
        else
        {
            [array addObject:[self autoFlashButton]];
        }
    }
}

- (UIBarButtonItem *)autoFlashButton
{
	return [UIToolbar autoFlashButtonWithTarget:self action:@selector(flashButton:)];
}

- (UIBarButtonItem *)autoBigFlashButton
{
    return [UIToolbar autoFlashButtonWithTarget:self action:@selector(flashButton:)];
#if 0
	// create the system-defined "OK or Done" button
	UIBarButtonItem *flash = [[[UIBarButtonItem alloc]
							   initWithTitle:@" Flash" style:UIBarButtonItemStylePlain 
							   target:self action:@selector(flashButton:)] autorelease];
	return flash;
#endif
}


- (UIBarButtonItem *)autoTicketAppButton
{
	// create the system-defined "OK or Done" button
	UIBarButtonItem *tix = [[[UIBarButtonItem alloc]
							 // initWithBarButtonSystemItem:UIBarButtonSystemItemRewind
							 initWithImage:[TableViewWithToolbar getToolbarIcon:kIconTicket]
							 style:UIBarButtonItemStylePlain
							 target:self action:@selector(ticketButton:)] autorelease];
	
	tix.style = UIBarButtonItemStylePlain;
	tix.accessibilityLabel = @"Tickets";
    
    if (tix.image == nil)
    {
        tix.title = @"T";
    }
	return tix;
}

- (void)appendXmlData:(NSMutableData *)buffer
{
    
}

- (void)didEnterBackground
{
    if (self.backgroundTask)
    {
        [self.backgroundTask cancel];
        [self.backgroundTask.progressModal removeFromSuperview];
        self.backgroundTask.progressModal= nil;

    };
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)xmlAction:(UIView *)sender
{
    // We replace some items in the XML to hide it or to make the reader
    // happy when concatonating.  This was learnt by trial and error!
    
    NSDictionary *replacements = @{
                                   TRIMET_APP_ID    : @"TRIMET_APP_ID",      // hide APP ID
                                   @"<?xml"         : @"<!--",               // XML encoding gets in the way
                                   @"?>"            : @"-->",
                                   @"<--?xml"       : @"<!--",               // XML encoding gets in the way
                                   @"?-->"          : @"-->",
                                   @"<body"         : @"<wasbody",           // This keyword gets dropped
                                   @"body>"         : @"wasbody>"
                                  };
    
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
        NSString *documentsDirectory = paths.firstObject;
    
        NSString * filePath = [documentsDirectory stringByAppendingPathComponent:@"PDXBusData.xml"];
        
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    
 
        NSMutableString *redactedData = [[NSMutableString alloc] initWithBytes:buffer.bytes
                                                                         length:buffer.length
                                                                       encoding:NSUTF8StringEncoding];
        
        [buffer release];
        
        
        [replacements enumerateKeysAndObjectsUsingBlock: ^void (NSString* key, NSString* replacement, BOOL *stop)
         {
            [redactedData replaceOccurrencesOfString:key
                                          withString:replacement
                                             options:NSCaseInsensitiveSearch
                                               range:NSMakeRange(0, redactedData.length)];
        
         }];
        
        [redactedData insertString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?><root>" atIndex:0];
        [redactedData appendString:@"</root>"];
        
        DEBUG_LOG(@"%@", redactedData);
        if ([redactedData writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil])
        {
            self.docMenu = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:filePath]];
            self.docMenu.delegate = self;
            self.docMenu.UTI = @"data.xml";

            if (self.xmlButton)
            {
                if (![self.docMenu presentOpenInMenuFromBarButtonItem:self.xmlButton animated:YES])
                {
                    UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"Debug XML", @"DNL")
                                                                       message:NSLocalizedString(@"No applications can read XML", @"DNL")
                                                                      delegate:nil
                                                             cancelButtonTitle:NSLocalizedString(@"OK", @"button text")
                                                             otherButtonTitles:nil] autorelease];
                    [alert show];
                    self.docMenu = nil;
                }
            }
            else
            {
                UIView *view = self.navigationController.view;
                CGRect rect = CGRectZero;
            
                if (sender!=nil)
                {
                    rect = [view convertRect:sender.frame fromView:sender.superview];
                }
                [self.docMenu presentOpenInMenuFromRect:rect
                                                 inView:view
                                               animated:YES];
        
            }
        }
        else
        {
            [redactedData release];
            UIAlertView *alert = [[[ UIAlertView alloc ] initWithTitle:NSLocalizedString(@"XML error", @"DNL")
                                                               message:NSLocalizedString(@"Could not write to file.", @"DNL")
                                                              delegate:nil
                                                     cancelButtonTitle:NSLocalizedString(@"OK", @"button text")
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



- (void)updateToolbarItems:(NSMutableArray *)toolbarItems
{
    [self maybeAddFlashButtonWithSpace:(toolbarItems.count == 0) buttons:toolbarItems big:NO];
}

- (void)updateToolbarItemsWithXml:(NSMutableArray *)toolbarItems
{    
    if ([UserPrefs singleton].debugXML)
    {
        [toolbarItems addObject:[self autoXmlButton]];
        [self maybeAddFlashButtonWithSpace:YES buttons:toolbarItems big:NO];
    }
    else
    {
        [self maybeAddFlashButtonWithSpace:NO buttons:toolbarItems big:NO];
    }
}


-(void)backButton:(id)sender
{
	if (self.callback !=nil && [self.callback getController] !=nil)
	{
		[self.navigationController popToViewController:[self.callback getController] animated:YES];
	}
	else
	{
       // TriMetTimesAppDelegate *app = [TriMetTimesAppDelegate singleton];
        
       // [self.navigationController popToViewController:(UIViewController*)app.rootViewController animated:YES];
        [ self.navigationController popToRootViewControllerAnimated:YES];
    }
}

-(void)ticketButton:(id)sender
{
	[self ticketApp];
}

+ (void)flashScreen:(UINavigationController *)nav
{
    FlashWarning *warning = [[FlashWarning alloc] initWithNav:nav];
    
    
	[warning release];
}


-(void)flashButton:(id)sender
{
    FlashWarning *warning = [[FlashWarning alloc] initWithNav:self.navigationController];
    
    warning.parentBase = self;
    
	[warning release];
    
}


- (void)showRouteSchedule:(NSString *)route
{
    if ([[TriMetRouteColors streetcarRoutes] containsObject:route])
    {
        [WebViewController displayPage:[NSString stringWithFormat:@"https://portlandstreetcar.org"]
                                  full:nil
                             navigator:self.navigationController
                        itemToDeselect:nil
                              whenDone:self.callbackWhenDone];
    }
    else
    {
        
        NSMutableString *padding = [NSMutableString string];
        
        [self padRoute:route padding:&padding];
        
        
        [WebViewController displayPage:[NSString stringWithFormat:@"https://www.trimet.org/schedules/r%@.htm",padding]
                                  full:nil
                             navigator:self.navigationController
                        itemToDeselect:nil
                              whenDone:self.callbackWhenDone];
    }
}

#pragma mark Common actions

- (bool)fullScreen
{
    CGRect myBounds = [UIApplication sharedApplication].delegate.window.bounds;
    CGRect fullScreen = [UIScreen mainScreen].bounds;
    
    if (fullScreen.size.width == myBounds.size.width)
    {
        return YES;
    }
    
    return NO;
}

- (bool)ZXingSupported
{
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (self.fullScreen && captureDeviceClass != nil)
    {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if (device == nil)
        {
            return NO;
        }
        
        
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        switch (authStatus)
        {
            case AVAuthorizationStatusAuthorized:
            case AVAuthorizationStatusNotDetermined:
                return YES;
            case AVAuthorizationStatusDenied:
            case AVAuthorizationStatusRestricted:
                return NO;
        }
    }
    
    return NO ;
}

- (void) padRoute:(NSString *)route padding:(NSMutableString **)padding
{
	while (route.length + (*padding).length < 3)
	{
		[*padding appendString:@"0"];
	}
	[*padding appendString:route];
}

- (void)networkTips:(NSData*)htmlError networkError:(NSString *)networkError
{
	
	if (htmlError)
	{
        WebViewController *errorScreen = [WebViewController viewController];
		[errorScreen setRawData:htmlError title:@"Error Message"];
		[errorScreen displayPage:self.navigationController animated:YES itemToDeselect:nil];
	}
	else {
        NetworkTestView *networkTest = [NetworkTestView viewController];
		networkTest.networkErrorFromQuery = networkError;
		[networkTest fetchNetworkStatusAsync:self.backgroundTask];
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
	textView.lineBreakMode =   NSLineBreakByWordWrapping;
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

- (bool)canTweet
{
    
    Class messageClass = (NSClassFromString(@"TWTweetComposeViewController"));
    
    if (messageClass != nil) {
        
        return YES;
        
        // if ([TWTweetComposeViewController canSendTweet]) {
        //    return YES;
        //}
    }
    
    return NO;
}


- (void) tweet
{
    self.tweetAlert = [[[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"@%@ on Twitter", self.tweetAt]
                                                   delegate:self
                                          cancelButtonTitle:nil
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:nil] autorelease];
    
    self.tweetButtons = [NSMutableArray array];
    
    if ([self canTweet])
    {
        self.tweetButtons[ [self.tweetAlert addButtonWithTitle:NSLocalizedString(@"Send tweet", @"button text")] ] = @(kTweetButtonTweet);
    }
    
    NSString *twitter=[NSString stringWithFormat:@"twitter:"];
    
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:twitter]])
    {
        self.tweetButtons[[self.tweetAlert addButtonWithTitle:NSLocalizedString(@"Show in Twitter app", @"button text")]] = @(kTweetButtonApp);
    }
    else
    {
        self.tweetButtons[[self.tweetAlert addButtonWithTitle:NSLocalizedString(@"Show in browser", @"button text")]]     = @(kTweetButtonWeb);
    }
        
    self.tweetAlert.cancelButtonIndex  = [self.tweetAlert addButtonWithTitle:NSLocalizedString(@"Cancel", @"button text")];
    self.tweetButtons[self.tweetAlert.cancelButtonIndex] = @(kTweetButtonCancel);
    
    [self.tweetAlert showFromToolbar:self.navigationController.toolbar];
    
}


-(void)clearSelection
{
    
}

- (UIViewController*)callbackWhenDone
{
    if (self.callback)
    {
        return [self.callback getController];
    }
    
    return nil;
}


- (bool)openBrowserFrom:(UIViewController *)view path:(NSString *)path
{
    if ([UserPrefs singleton].useChrome && [ OpenInChromeController sharedInstance].isChromeInstalled)
    {
        if ([[OpenInChromeController sharedInstance] openInChrome:[NSURL URLWithString:path]
                                                  withCallbackURL:[NSURL URLWithString:@"pdxbus:"]
                                                     createNewTab:NO])
        {
            return YES;
        }
    }
    
    return [self openSafariFrom:self path:path];
}

- (bool)openSafariFrom:(UIViewController *)view path:(NSString *)path
{
    Class safariClass = (NSClassFromString(@"SFSafariViewController"));
    
    NSURL *url = [NSURL URLWithString:path];
    
    if (safariClass!=nil)
    {
        SFSafariViewController *vc = [[SFSafariViewController alloc] initWithURL:url];
        
        // vc.delegate = self
        [view presentViewController:vc animated:YES completion:^{}];
        return TRUE;
    }
    else
    {
        if ([[UIApplication sharedApplication] canOpenURL:url])
        {
            [[UIApplication sharedApplication] openURL:url];
            return TRUE;
        }
    }

    return FALSE;
}


- (void)facebookWithId:(NSString*)fbid path:(NSString*)fbpath
{
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:fbid]])
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbid]];
    }
    else
    {
        [self openBrowserFrom:self path:fbpath];
    }
    [self clearSelection];
}

- (bool)ticketApp
{
#if 1
    static NSString *ticket = @"trimettickets://";
    

    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:ticket]])
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:ticket]];
        return YES;
    }
#endif
    TicketAlert *alert = [[[TicketAlert alloc] initWithParent:self] autorelease];
    [alert.sheet showFromToolbar:self.navigationController.toolbar];
    
    return NO;
    
}

- (void)facebookTriMet
{
    static NSString *fbid=@"fb://profile/270344585472";
    static NSString *fbpath = @"https://m.facebook.com/TriMet";
    
    [self facebookWithId:fbid path:fbpath];
}

- (void)facebook
{
    static NSString *fbid=@"fb://profile/218101161593";
    static NSString *fbpath = @"https://m.facebook.com/PDXBus";
    
    [self facebookWithId:fbid path:fbpath];
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
{
    
    if (actionSheet != self.tweetAlert)
    {
        return;
    }
    switch (self.tweetButtons[buttonIndex].integerValue)
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
            [self openBrowserFrom:self path:twitter];
            [self clearSelection];
            break;
        }
            
        case kTweetButtonCancel:
        {
            [self clearSelection];
            break;
        }
            
        case kTweetButtonTweet:
        {
            SLComposeViewController *picker = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            [picker setInitialText:self.initTweet];
            
            picker.completionHandler =
            ^(SLComposeViewControllerResult result) {
                [self clearSelection];
            };
            
            [self presentViewController:picker animated:YES completion:nil];
            
            break;
        }
    }
    
    self.tweetButtons = nil;
}

- (void)favesChanged
{
    _userData.favesChanged = YES;
    [self updateWatch];
}

- (void)updateWatch
{
    
    TriMetTimesAppDelegate *app = [TriMetTimesAppDelegate singleton];
    RootViewController *root = (RootViewController*)app.rootViewController;
    
    if (root.session)
    {
        [WatchAppContext updateWatch:root.session];
    }
    
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.backgroundTask cancel];
}



@end
