//
//  WatchDepartureUI.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/12/15.
//  Copyright (c) 2015 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DepartureData.h"
#import <WatchKit/WatchKit.h>

@interface WatchDepartureUI : NSObject
{
    DepartureData *_data;
}

@property (nonatomic, retain) DepartureData *data;

- (id)initWithData:(DepartureData*)data;
+ (WatchDepartureUI *)createFromData:(DepartureData*)data;

- (UIColor*)getFontColor;
- (UIImage*)getRouteColorImage;
- (NSString*)minsToArrival;
- (bool)hasRouteColor;
- (UIImage*)getBlockImageColor;
- (NSAttributedString *)headingWithStatus;
- (NSString *)exception;


@end
