//
//  Trip.h
//  PDX Bus
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

#import <UIKit/UIKit.h>

#include "TriMetTypes.h"


@interface Trip : NSObject {
	NSString *_name;
	unsigned long _distance;
	unsigned long _progress;
	TriMetTime _startTime;
	TriMetTime _endTime;
	
}
@property (nonatomic, retain) NSString *name;
@property (nonatomic) unsigned long distance;
@property (nonatomic) unsigned long progress;
@property (nonatomic) TriMetTime startTime;
@property (nonatomic) TriMetTime endTime;

- (id)init;

@end
