//
//  About.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"

#define kTips					2

@interface AboutView : TableViewWithToolbar {
	NSAttributedString *aboutText;
	NSAttributedString *helpText;
    NSArray *links;
    NSArray *legal;
    
    
    bool _hideButton;
}

@property (nonatomic) bool hideButton;

@end
