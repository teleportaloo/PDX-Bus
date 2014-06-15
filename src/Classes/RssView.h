//
//  RssView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/4/10.



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"
#import "RssXML.h"


@interface RssView : TableViewWithToolbar {
	RssXML *_rssData; 
	NSString *_rssUrl;
    bool _gotoOriginalArticle;
}

- (void)fetchRssInBackground:(id<BackgroundTaskProgress>) callback url:(NSString*)rssUrl;

@property (nonatomic, retain) RssXML *rssData;
@property (nonatomic, retain) NSString *rssUrl;
@property (nonatomic) bool gotoOriginalArticle;


@end
