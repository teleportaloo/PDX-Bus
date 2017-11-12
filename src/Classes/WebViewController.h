//
//  WebViewController.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "ViewControllerBase.h"

@interface WebViewController : ViewControllerBase <UIWebViewDelegate>{
	UIWebView *         _webView;
	NSString *          _urlToDisplay;
	NSString *          _dataToDisplay;
	NSData *            _rawDataToDisplay;
	UIBarButtonItem *   _webBack;
	UIBarButtonItem *   _webForward;
	UIBarButtonItem *   _safari;
	UIViewController *  _whenDone;
	NSURL *             _localURL;
	bool                _showErrors;
	int                 _depth;
}

- (void)updateToolbarItems:(NSMutableArray*)toolbarItems;
- (void)setURLmobile:(NSString *)url full:(NSString *)full;
- (void)setRawData:(NSData *)rawData title:(NSString *)title;
- (void)displayPage:(UINavigationController *)nav animated:(BOOL)animated itemToDeselect:(id<DeselectItemDelegate>)deselect;
+ (void)displayPage:(NSString *)url
               full:(NSString*)full
          navigator:(UINavigationController *)nav
     itemToDeselect:(id<DeselectItemDelegate>)deselect
           whenDone:(UIViewController*)whenDone;



@property (nonatomic, retain) NSData *rawDataToDisplay;
@property (nonatomic, copy)   NSString *urlToDisplay;
@property (nonatomic, copy)   NSString *dataToDisplay;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) UIBarButtonItem *webBack;
@property (nonatomic, retain) UIBarButtonItem *webForward;
@property (nonatomic, retain) UIBarButtonItem *safari;
@property (nonatomic, retain) UIViewController *whenDone;
@property (nonatomic) bool showErrors;
@property (nonatomic, retain) NSURL *localURL;
@property (nonatomic)		  NSInteger rssLinkItem;

@end
