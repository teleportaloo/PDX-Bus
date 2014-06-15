//
//  RssXML.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/4/10.



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "TriMetXML.h"
#import "RssLink.h"

@interface RssXML : TriMetXML {
	RssLink *_currentItem;
	NSString *_title;
	NSDateFormatter *_rssDateFormatter;
}

@property (nonatomic, retain) RssLink *currentItem;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSDateFormatter *rssDateFormatter;

- (NSString *)fullErrorMsg;

@end
