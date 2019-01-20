//
//  WatchRow.h
//  PDX Bus WatchKit Extension
//
//  Created by Andrew Wallace on 4/26/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@class XMLDepartures;
@class DepartureData;
@class WatchArrivalsContext;

@interface WatchRow : NSObject

@property (nonatomic, strong) NSNumber *index;

+ (NSString *)identifier;

- (void)populate:(XMLDepartures *)xml departures:(NSArray<DepartureData*>*)deps;
- (bool)select:(XMLDepartures*)xml from:(WKInterfaceController *)from context:(WatchArrivalsContext*)context;

@end
