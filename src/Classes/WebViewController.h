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
#import "DeselectItemDelegate.h"

@interface WebViewController : ViewControllerBase <WKNavigationDelegate>

@property (nonatomic, copy)   NSString *javsScriptCommand;
@property (nonatomic, copy)   NSString *urlToDisplay;

- (void)setURLmobile:(NSString *)url full:(NSString *)full;
- (void)setRawData:(NSData *)rawData title:(NSString *)title;
- (void)displayPage:(UINavigationController *)nav animated:(BOOL)animated itemToDeselect:(id<DeselectItemDelegate>)deselect;

+ (void)displayPage:(NSString *)url
               full:(NSString *)full
          navigator:(UINavigationController *)nav
     itemToDeselect:(id<DeselectItemDelegate>)deselect
           whenDone:(UIViewController *)whenDone;

@end
