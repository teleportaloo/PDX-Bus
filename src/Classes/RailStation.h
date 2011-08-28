//
//  RailStation.h
//  PDX Bus
//
//  Created by Andrew Wallace on 10/4/10.
//  Copyright 2010. All rights reserved.
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

#import <Foundation/Foundation.h>
#import "HotSpot.h"
#import "ScreenConstants.h"
#import "SearchFilter.h"

@interface RailStation : NSObject <SearchFilter> {
	NSMutableArray *_locList;
	NSMutableArray *_dirList;
	NSString *_station;
	NSString *_wikiLink;
	int _index;
}

@property (nonatomic, retain) NSMutableArray *locList;
@property (nonatomic, retain) NSMutableArray *dirList;
@property (nonatomic, retain) NSString *station;
@property (nonatomic, retain) NSString *wikiLink;
@property (nonatomic) int index;
@property (readonly) RAILLINES line;


- (id)initFromHotSpot:(HOTSPOT *)hotspot index:(int)index;
- (NSComparisonResult)compareUsingStation:(RailStation*)inStation;
+ (NSString *)nameFromHotspot:(HOTSPOT *)hotspot;
+ (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier rowHeight:(CGFloat)height 
										  screenWidth:(ScreenType)screenWidth 
										  rightMargin:(BOOL)rightMargin
												 font:(UIFont*)font;
+ (void)populateCell:(UITableViewCell*)cell station:(NSString *)station lines:(RAILLINES)lines;
- (NSString*)url;
- (NSString*)stringToFilter;


@end
