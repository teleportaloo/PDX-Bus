//
//  RssLink.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/4/10.



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "ViewControllerBase.h"

#define VGAP 4.0

@interface RssLink : NSObject
{
	NSString *_title;
	NSString *_link;
	NSString *_description;
	NSDate *_date;
	NSString *_dateString;
}

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *link;
@property (nonatomic, retain) NSString *description;
@property (nonatomic, retain) NSString *dateString;
@property (nonatomic, retain) NSDate *date;

- (NSString *)cellReuseIdentifier:(NSString *)identifier width:(ScreenWidth)width;
- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier width:(ScreenWidth)width font:(UIFont*)font;
- (void)populateCell:(UITableViewCell *)cell;
- (CGFloat)getTimeHeight:(ScreenWidth)width;

@end
