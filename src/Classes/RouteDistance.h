//
//  RouteDistance.h
//  PDX Bus
//
//  Created by Andrew Wallace on 1/9/11.
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
#import "ScreenConstants.h"


#define kRouteCellHeight	55
#define kRouteWideCellHeight 85

@interface RouteDistance : NSObject {
	NSString *_desc;
	NSString *_route;
	NSString *_type;
	NSMutableArray *_stops;
}

- (void)sortStopsByDistance;
- (NSComparisonResult)compareUsingDistance:(RouteDistance*)inStop;
- (NSString *)cellReuseIdentifier:(NSString *)identifier width:(ScreenType)width;
- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier width:(ScreenType)width;
- (void)populateCell:(UITableViewCell *)cell wide:(BOOL)wide;




@property (nonatomic, retain) NSString *desc;
@property (nonatomic, retain) NSString *route;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSMutableArray *stops;

@end
