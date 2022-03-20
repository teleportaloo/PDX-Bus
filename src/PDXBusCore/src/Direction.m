//
//  Direction.m
//  PDX Bus
//
//  Created by Andrew Wallace on 10/11/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//

#import "Direction.h"

@implementation Direction

+ (Direction*)withDir:(NSString *)dir desc:(NSString *)desc
{
    Direction *direction = [Direction new];
    
    direction.dir = dir;
    direction.desc = desc;
    
    return direction;
}


- (NSComparisonResult)compare:(Direction *)other
{
    return [self.dir compare:other.dir];
}

@end
