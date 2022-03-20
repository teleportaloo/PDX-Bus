//
//  RailStation.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/4/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "RailStation.h"
#import "XMLStops.h"
#import "DebugLogging.h"
#import "RailMapView.h"
#import "TriMetInfo.h"
#import "RouteColorBlobView.h"
#import "AllRailStationView.h"
#import "NSString+Helper.h"

@implementation RailStation

@dynamic line;
@dynamic line0;
@dynamic line1;


- (RailLines)line {
    return [AllRailStationView railLines:self.index];
}

- (RailLines)line0 {
    return [AllRailStationView railLines0:self.index];
}

- (RailLines)line1 {
    return [AllRailStationView railLines1:self.index];
}

- (NSComparisonResult)compareUsingStation:(RailStation *)inStation {
    return [self.station compare:inStation.station
                         options:(NSNumericSearch | NSCaseInsensitiveSearch)];
}

+ (void)scannerInc:(NSScanner *)scanner {
    if (!scanner.atEnd) {
        scanner.scanLocation++;
    }
}

+ (void)nextSlash:(NSScanner *)scanner intoString:(NSString **)substr; {
    if (!scanner.atEnd) {
        [scanner scanUpToString:@"/" intoString:substr];
        
        // NSLog(@"%@", *substr);
        [self scannerInc:scanner];
    }
}

- (NSString *)longDirectionFromTableName:(NSString *)dir {
    static NSDictionary *names = nil;
    
    if (names == nil) {
        names = @{
            @"N": NSLocalizedString(@"Northbound",           @"Train direction"),
            @"S": NSLocalizedString(@"Southbound",           @"Train direction"),
            @"E": NSLocalizedString(@"Eastbound",            @"Train direction"),
            @"W": NSLocalizedString(@"Westbound",            @"Train direction"),
            @"NE": NSLocalizedString(@"Northeastbound",       @"Train direction"),
            @"SE": NSLocalizedString(@"Southeastbound",       @"Train direction"),
            @"SW": NSLocalizedString(@"Southwestbound",       @"Train direction"),
            @"NW": NSLocalizedString(@"Northwestbound",       @"Train direction"),
            @"MAXN": NSLocalizedString(@"MAX Northbound",       @"Train direction"),
            @"MAXS": NSLocalizedString(@"MAX Southbound",       @"Train direction"),
            @"WESS": NSLocalizedString(@"WES Southbound",       @"Train direction"),
            @"WESA": NSLocalizedString(@"WES Both Directions",  @"Train direction"),
        };
    }
    
    NSString *obj = names[dir];
    
    if (obj == nil) {
        obj = [dir stringByRemovingPercentEncoding];
    }
    
    return obj;
}

+ (NSString *)nameFromHotspot:(HotSpot *)hotspot {
    NSScanner *scanner = [NSScanner scannerWithString:hotspot->action];
    NSCharacterSet *colon = [NSCharacterSet characterSetWithCharactersInString:@":"];
    
    NSString *substr;
    NSString *stationName = @"";
    
    [scanner scanUpToCharactersFromSet:colon intoString:&substr];
    
    if (substr == nil) {
        return nil;
    }
    
    [RailStation scannerInc:scanner];
    [RailStation nextSlash:scanner intoString:&stationName];
    
    return [stationName stringByRemovingPercentEncoding];
}

+ (instancetype)fromHotSpot:(HotSpot *)hotspot index:(int)index {
    return [[[self class] alloc] initFromHotSpot:hotspot index:index];
}

- (instancetype)initFromHotSpot:(HotSpot *)hotspot index:(int)index {
    if ((self = [super init])) {
        NSScanner *scanner = [NSScanner scannerWithString:hotspot->action];
        NSCharacterSet *colon = [NSCharacterSet characterSetWithCharactersInString:@":"];
        NSCharacterSet *comma = [NSCharacterSet characterSetWithCharactersInString:@","];
        NSCharacterSet *slash = [NSCharacterSet characterSetWithCharactersInString:@"/"];
        
        NSString *substr = nil;
        NSString *stationName = nil;
        NSString *wiki = nil;
        
        [scanner scanUpToCharactersFromSet:colon intoString:&substr];
        
        if (substr == nil) {
            return nil;
        }
        
        [RailStation scannerInc:scanner];
        [RailStation nextSlash:scanner intoString:&stationName];
        [RailStation nextSlash:scanner intoString:&wiki];
        
        self.station = [stationName stringByRemovingPercentEncoding];
        self.wikiLink = (wiki != nil ? [wiki stringByRemovingPercentEncoding] : nil);
        self.stopIdArray = [NSMutableArray array];
        self.dirArray = [NSMutableArray array];
        self.transferStopIdArray = [NSMutableArray array];
        
        // NSString *stop = nil;
        NSString *dir = nil;
        NSString *stopId = nil;
        
        while ([scanner scanUpToCharactersFromSet:comma intoString:&dir]) {
            if (!scanner.atEnd) {
                scanner.scanLocation++;
            }
            
            [scanner scanUpToCharactersFromSet:slash intoString:&stopId];
            
            if ([dir isEqualToString:@"T"]) {
                [self.transferStopIdArray addObject:stopId];
            } else {
                [self.dirArray addObject:[self longDirectionFromTableName:dir]];
                [self.stopIdArray addObject:stopId];
            }
                
            if (!scanner.atEnd) {
                scanner.scanLocation++;
            }
        }
        
        self.index = index;
    }
    
    return self;
}


- (void)findTransfers {
    if (self.transferStopIdArray.count != 0 &&  self.transferNameArray == nil) {
        self.transferNameArray = [NSMutableArray array];
        self.transferDirArray = [NSMutableArray array];
        self.transferHotSpotIndexArray = [NSMutableArray array];
    
        for (NSString *stopId in self.transferStopIdArray) {
            
            RailStation *station = [AllRailStationView railstationFromStopId:stopId];
            
            if (station != nil) {
                NSInteger i;
                
                bool found = NO;
                
                for (i = 0;  i < station.stopIdArray.count; i++) {
                    if ([station.stopIdArray[i] isEqualToString:stopId]) {
                        [self.transferNameArray addObject:station.station];
                        [self.transferDirArray addObject:station.dirArray[i]];
                        [self.transferHotSpotIndexArray addObject:@(station.index)];
                        found = YES;
                        break;
                    }
                }
                
                
                if (!found) {
                    [self.transferNameArray addObject:@"unknown"];
                    [self.transferDirArray addObject:@"unknown"];
                    [self.transferHotSpotIndexArray addObject:@(0)];
                }
            }
            
            
            
        }
    }
}

#define MAX_TAG       2
#define MAX_LINES     4


+ (UITableViewCell *)tableView:(UITableView *)tableView cellWithReuseIdentifier:(NSString *)identifier rowHeight:(CGFloat)height {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) {
#define MAX_LINE_SIDE ROUTE_COLOR_WIDTH
        const CGFloat MAX_LINE_VOFFSET = (height - MAX_LINE_SIDE) / 2;
#define MAX_LINE_GAP  0
        
        UIView *maxColors = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MAX_LINE_SIDE * MAX_LINES, height)];
        CGRect rect;
        
        for (int i = 0; i < MAX_LINES; i++) {
            rect = CGRectMake((MAX_LINE_SIDE + MAX_LINE_GAP) * i, MAX_LINE_VOFFSET, MAX_LINE_SIDE, MAX_LINE_SIDE);
            RouteColorBlobView *max = [[RouteColorBlobView alloc] initWithFrame:rect];
            max.tag = MAX_LINES + MAX_TAG - i - 1;
            [maxColors addSubview:max];
        }
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.accessoryView = maxColors;
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:cell.textLabel.font.pointSize];
    }
    
    return cell;
}

+ (int)addLine:(UITableViewCell *)cell tag:(int)tag line:(RailLines)line lines:(RailLines)lines {
    if (tag - MAX_TAG > MAX_LINES) {
        return tag;
    }
    
    RouteColorBlobView *view = (RouteColorBlobView *)[cell.accessoryView viewWithTag:tag];
    
    
    if (lines & line) {
        if ([view setRouteColorLine:line]) {
            tag++;
        }
    }
    
    return tag;
}

+ (void)populateCell:(UITableViewCell *)cell station:(NSString *)station lines:(RailLines)lines {
    // [self label:cell tag:TEXT_TAG].text = station;
    
    int tag = MAX_TAG;
    
    // UILabel *label = (UILabel*)[cell.contentView viewWithTag:TEXT_TAG];
    cell.textLabel.attributedText = station.attributedStringFromMarkUp;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.accessibilityLabel = station.phonetic;
    
    for (PtrConstRouteInfo info = [TriMetInfo allColoredLines]; info->route_number != kNoRoute; info++) {
        tag = [RailStation addLine:cell tag:tag line:info->line_bit lines:lines];
    }
    
    for (; tag < MAX_TAG + MAX_LINES; tag++) {
        RouteColorBlobView *view = (RouteColorBlobView *)[cell.accessoryView viewWithTag:tag];
        view.hidden = YES;
    }
}

- (NSString *)stringToFilter {
    return self.station;
}


- (BOOL)isEqual:(id)other {
    if (self == other) {
        return TRUE;
    }
    
    if ([other isKindOfClass:RailStation.class]) {
        return [self.station isEqualToString: ((RailStation *)other).station];
    }
    
    return NO;
}

- (NSUInteger)hash {
    return self.station.hash;
}

@end
