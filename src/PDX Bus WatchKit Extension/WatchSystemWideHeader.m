//
//  WatchSystemWideHeader.m
//  PDX Bus WatchKit Extension
//
//  Created by Andrew Wallace on 4/27/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//

#import "WatchSystemWideHeader.h"
#import "XMLDepartures.h"

@implementation WatchSystemWideHeader


+ (NSString*)identifier
{
    return @"SWH";
}

- (void)populate:(XMLDepartures *)xml departures:(NSArray<DepartureData*>*)deps
{
    Detour *det = xml.allDetours[self.index];
    self.label.text = det.headerText;
}

@end
