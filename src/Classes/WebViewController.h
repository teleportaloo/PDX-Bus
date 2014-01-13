//
//  WebViewController.h
//  PDX Bus
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

#import <UIKit/UIKit.h>
#import "ViewControllerBase.h"
#import "RssLink.h"


@interface WebViewController : ViewControllerBase <UIWebViewDelegate, UIActionSheetDelegate>{
	UIWebView	*_webView;
	NSString	*_urlToDisplay;
	NSString	*_dataToDisplay;
	NSData		*_rawDataToDisplay;
	UIBarButtonItem *_webBack;
	UIBarButtonItem *_webForward;
	UIBarButtonItem *_safari;
	UIViewController *_whenDone;
	NSURL	*_localURL;
	NSArray *_rssLinks;
	int _rssLinkItem;
	bool map;
	bool _showErrors;
	int _depth;
}

- (void)updateToolbarItems:(NSMutableArray*)toolbarItems;
- (void)setRssItem:(RssLink *)rss title:(NSString *)title;
- (void)setURLmobile:(NSString *)url full:(NSString *)full title:(NSString*)title;
- (void)setRawData:(NSData *)rawData title:(NSString *)title;
- (void)setMapLocationLat:(NSString *)lat lng:(NSString *)lng title:(NSString *)title;
- (void)displayPage:(UINavigationController *)nav animated:(BOOL)animated tableToDeselect:(UITableView*)table;

@property (nonatomic, retain) NSData *rawDataToDisplay;
@property (nonatomic, retain) NSString *urlToDisplay;
@property (nonatomic, retain) NSString *dataToDisplay;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) UIBarButtonItem *webBack;
@property (nonatomic, retain) UIBarButtonItem *webForward;
@property (nonatomic, retain) UIBarButtonItem *safari;
@property (nonatomic, retain) UIViewController *whenDone;
@property (nonatomic) bool showErrors;
@property (nonatomic, retain) NSURL *localURL;
@property (nonatomic, retain) NSArray *rssLinks;
@property (nonatomic)		  int rssLinkItem;

@end
