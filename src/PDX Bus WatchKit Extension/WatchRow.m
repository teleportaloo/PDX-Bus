//
//  WatchRow.m
//  PDX Bus WatchKit Extension
//
//  Created by Andrew Wallace on 4/26/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//

#import "WatchRow.h"

@implementation WatchRow


+ (NSString *)identifier
{
    return @"None";
}


- (void)populate:(XMLDepartures *)xml departures:(NSArray<DepartureData*>*)deps
{
    
}

- (bool)select:(XMLDepartures*)xml from:(WKInterfaceController *)from context:(WatchArrivalsContext*)context 
{
    return NO;
}
@end
