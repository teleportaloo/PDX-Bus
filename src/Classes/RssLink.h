//
//  RssLink.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/4/10.

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

- (NSString *)cellReuseIdentifier:(NSString *)identifier width:(ScreenType)width;
- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier width:(ScreenType)width font:(UIFont*)font;
- (void)populateCell:(UITableViewCell *)cell;
- (CGFloat)getTimeHeight:(ScreenType)width;

@end
