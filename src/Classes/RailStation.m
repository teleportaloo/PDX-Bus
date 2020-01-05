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


- (RAILLINES)line
{    
    return [AllRailStationView railLines:self.index];
}

- (RAILLINES)line0
{
    return [AllRailStationView railLines0:self.index];
}

- (RAILLINES)line1
{
    return [AllRailStationView railLines1:self.index];
}

-(NSComparisonResult)compareUsingStation:(RailStation*)inStation
{
    return [self.station caseInsensitiveCompare:inStation.station];
}


+ (void)scannerInc:(NSScanner *)scanner 
{    
    if (!scanner.atEnd)
    {
        scanner.scanLocation++;
    }
}


+ (void)nextSlash:(NSScanner *)scanner intoString:(NSString **)substr;
{
    if (!scanner.atEnd)
    {
        [scanner scanUpToString:@"/" intoString:substr];
        
        // NSLog(@"%@", *substr);
        [self scannerInc:scanner];
    }
    
}

- (NSString *)longDirectionFromTableName:(NSString *)dir
{
    static NSDictionary *names = nil;
    
    if (names == nil)
    {
        names = @{
                  @"N"      : NSLocalizedString(@"Northbound",           @"Train direction"),
                  @"S"      : NSLocalizedString(@"Southbound",           @"Train direction"),
                  @"E"      : NSLocalizedString(@"Eastbound",            @"Train direction"),
                  @"W"      : NSLocalizedString(@"Westbound",            @"Train direction"),
                  @"NE"     : NSLocalizedString(@"Northeastbound",       @"Train direction"),
                  @"SE"     : NSLocalizedString(@"Southeastbound",       @"Train direction"),
                  @"SW"     : NSLocalizedString(@"Southwestbound",       @"Train direction"),
                  @"NW"     : NSLocalizedString(@"Northwestbound",       @"Train direction"),
                  @"MAXN"   : NSLocalizedString(@"MAX Northbound",       @"Train direction"),
                  @"MAXS"   : NSLocalizedString(@"MAX Southbound",       @"Train direction"),
                  @"WESS"   : NSLocalizedString(@"WES Southbound",       @"Train direction"),
                  @"WESA"   : NSLocalizedString(@"WES Both Directions",  @"Train direction"),
                  };
    }

    
    NSString * obj = names[dir];
    
    if (obj == nil)
    {
        obj = [dir stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    }
    return obj;
}

+ (NSString *)nameFromHotspot:(HOTSPOT *)hotspot
{
    NSScanner *scanner = [NSScanner scannerWithString:hotspot->action];
    NSCharacterSet *colon = [NSCharacterSet characterSetWithCharactersInString:@":"];
    
    NSString *substr;
    NSString *stationName = @"";
    
    [scanner scanUpToCharactersFromSet:colon intoString:&substr];
    
    if (substr == nil)
    {
        return nil;
    }
    
    [RailStation scannerInc:scanner];
    [RailStation nextSlash:scanner intoString:&stationName];
    
    return [stationName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
}

+ (instancetype)fromHotSpot:(HOTSPOT *)hotspot index:(int)index
{
   return  [[[self class] alloc] initFromHotSpot:hotspot index:index];
}

- (instancetype)initFromHotSpot:(HOTSPOT *)hotspot index:(int)index
{
    if ((self = [super init]))
    {
        NSScanner *scanner = [NSScanner scannerWithString:hotspot->action];
        NSCharacterSet *colon = [NSCharacterSet characterSetWithCharactersInString:@":"];
        NSCharacterSet *comma = [NSCharacterSet characterSetWithCharactersInString:@","];
        NSCharacterSet *slash = [NSCharacterSet characterSetWithCharactersInString:@"/"];
        
        NSString *substr=nil;
        NSString *stationName=nil;
        NSString *wiki=nil;
        
        [scanner scanUpToCharactersFromSet:colon intoString:&substr];
        
        if (substr == nil)
        {
            return nil;
        }
        
        [RailStation scannerInc:scanner];
        [RailStation nextSlash:scanner intoString:&stationName];
        [RailStation nextSlash:scanner intoString:&wiki];
        
        self.station = [stationName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        self.wikiLink =  (wiki !=nil ? [wiki stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] : nil);
        self.locList = [NSMutableArray array];
        self.dirList = [NSMutableArray array];
        
        // NSString *stop = nil;
        NSString *dir = nil;
        NSString *locId = nil;
        
        
        while ([scanner scanUpToCharactersFromSet:comma intoString:&dir])
        {    
            if (!scanner.atEnd)
            {
                scanner.scanLocation++;
            }
            
            [scanner scanUpToCharactersFromSet:slash intoString:&locId];
            
            [self.dirList addObject:[self longDirectionFromTableName:dir]];
            [self.locList addObject:locId];
            
            if (!scanner.atEnd)
            {
                scanner.scanLocation++;
            }
            
        }
        
        self.index = index;
    }
    return self;
    
}

#define MAX_TAG 2
#define MAX_LINES 4


+ (UITableViewCell *)tableView:(UITableView*)tableView cellWithReuseIdentifier:(NSString *)identifier rowHeight:(CGFloat)height
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil)
    {
#define MAX_LINE_SIDE ROUTE_COLOR_WIDTH
        const CGFloat MAX_LINE_VOFFSET = (height - MAX_LINE_SIDE)/2;
#define MAX_LINE_GAP  0
        
        UIView *maxColors = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MAX_LINE_SIDE * MAX_LINES, height)];
        CGRect rect;
        
        for (int i=0; i< MAX_LINES;i++)
        {
            rect = CGRectMake((MAX_LINE_SIDE + MAX_LINE_GAP ) *i, MAX_LINE_VOFFSET , MAX_LINE_SIDE, MAX_LINE_SIDE);
            RouteColorBlobView *max = [[RouteColorBlobView alloc] initWithFrame:rect];
            max.tag = MAX_LINES+MAX_TAG-i-1;
            [maxColors addSubview:max];
        }
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.accessoryView = maxColors;
        
    }

    return cell;    
}

+ (int)addLine:(UITableViewCell*)cell tag:(int)tag line:(RAILLINES)line lines:(RAILLINES)lines
{
    if (tag-MAX_TAG > MAX_LINES)
    {
        return tag;
    }
        
    RouteColorBlobView *view = (RouteColorBlobView *)[cell.accessoryView viewWithTag:tag];
    

    if (lines & line)
    {
        if ([view setRouteColorLine:line])
        {
            tag++;
        }
    }
    
    return tag;
}

+ (void)populateCell:(UITableViewCell*)cell station:(NSString *)station lines:(RAILLINES)lines
{
    // [self label:cell tag:TEXT_TAG].text = station;
    
    int tag = MAX_TAG;
    
    // UILabel *label = (UILabel*)[cell.contentView viewWithTag:TEXT_TAG];
    cell.textLabel.text = station;
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    cell.accessibilityLabel = station.phonetic;
    
    
    for (PC_ROUTE_INFO info = [TriMetInfo allColoredLines]; info->route_number!=kNoRoute; info++)
    {
        tag = [RailStation addLine:cell tag:tag line:info->line_bit lines:lines];
    }
    
    for (; tag < MAX_TAG + MAX_LINES; tag++)
    {
        RouteColorBlobView *view = (RouteColorBlobView *)[cell.accessoryView viewWithTag:tag];
        view.hidden = YES;
    }
    
}



- (NSString*)stringToFilter
{
    return self.station;
}


@end
