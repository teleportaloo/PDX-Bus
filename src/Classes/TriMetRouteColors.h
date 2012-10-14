//
//  TriMetRouteColors.h
//  PDX Bus
//
//  Created by Andrew Wallace on 9/30/10.
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
#import "Hotspot.h"

typedef struct route_cols { 
	NSString *route;
	RAILLINES line;
	float r;
	float g;
	float b;
	NSString *wiki;
	NSString *name;
	NSString *type;
    bool  square;
} ROUTE_COL;

@interface TriMetRouteColors : NSObject {
	
}

+ (UIColor*)colorForRoute:(NSString *)route;
+ (ROUTE_COL *)rawColorForLine:(RAILLINES)line;
+ (ROUTE_COL *)rawColorForRoute:(NSString *)route;


@end
