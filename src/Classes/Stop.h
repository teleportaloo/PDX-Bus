//
//  Stop.h
//  PDXBus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "CoreLocation/CoreLocation.h"
#import "SearchFilter.h"
#import <Foundation/Foundation.h>

@protocol ReturnStopObject;
@protocol TaskController;

@interface Stop : NSObject <SearchFilter>

@property(nonatomic, copy) NSString *stopId;
@property(nonatomic, copy) NSString *desc;
@property(nonatomic, copy) NSString *dir;
@property(nonatomic) bool timePoint;
@property(nonatomic, strong) CLLocation *location;
@property(nonatomic, strong) id<ReturnStopObject> stopObjectCallback;
@property(nonatomic) NSUInteger index;
@property(nonatomic, readonly, copy) NSString *stringToFilter;

+ (Stop *)fromAttributeDict:(NSDictionary *)XML_ATR_DICT;

@end

@protocol ReturnStopObject

@property(nonatomic, readonly, copy) NSString *returnStopObjectActionText;

- (void)returnStopObject:(Stop *)stop progress:(id<TaskController>)progress;

@end
