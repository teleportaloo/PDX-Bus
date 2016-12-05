//
//  Route.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "SearchFilter.h"
#import "DataFactory.h"


@interface Route : DataFactory <SearchFilter> {
	NSString *              _route;
	NSString *              _desc;
	NSMutableDictionary	*   _directions;
}

@property (nonatomic, copy)   NSString *route;
@property (nonatomic, copy)   NSString *desc;
@property (nonatomic, retain) NSMutableDictionary *directions;

@end
