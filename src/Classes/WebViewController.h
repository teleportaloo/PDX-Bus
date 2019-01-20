//
//  WebViewController.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "ViewControllerBase.h"
#import <WebKit/WebKit.h>

@interface WebViewController : ViewControllerBase <WKNavigationDelegate>{
    int                 _depth;
    bool               _navigated;
}

@property (nonatomic, strong) NSData *rawDataToDisplay;
@property (nonatomic, copy)   NSString *urlToDisplay;
@property (nonatomic, copy)   NSString *dataToDisplay;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIBarButtonItem *webBack;
@property (nonatomic, strong) UIBarButtonItem *webForward;
@property (nonatomic, strong) UIBarButtonItem *safari;
@property (nonatomic, strong) UIViewController *whenDone;
@property (nonatomic) bool showErrors;
@property (nonatomic, strong) NSURL *localURL;
@property (nonatomic)          NSInteger rssLinkItem;
@property (nonatomic,copy)    NSString *javsScriptCommand;

- (void)updateToolbarItems:(NSMutableArray*)toolbarItems;
- (void)setURLmobile:(NSString *)url full:(NSString *)full;
- (void)setRawData:(NSData *)rawData title:(NSString *)title;
- (void)displayPage:(UINavigationController *)nav animated:(BOOL)animated itemToDeselect:(id<DeselectItemDelegate>)deselect;

+ (void)displayPage:(NSString *)url
               full:(NSString*)full
          navigator:(UINavigationController *)nav
     itemToDeselect:(id<DeselectItemDelegate>)deselect
           whenDone:(UIViewController*)whenDone;

@end
