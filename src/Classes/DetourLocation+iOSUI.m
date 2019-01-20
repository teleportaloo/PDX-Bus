//
//  DetourLocation+DetourLocation_iOSUI.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/7/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//

#import "DetourLocation+iOSUI.h"

@implementation DetourLocation (iOSUI)


- (CLLocationCoordinate2D) coordinate
{
    return self.location.coordinate;
}

- (NSString*)title
{
    return self.desc;
}


- (NSString*)subtitle
{
    if (self.noServiceFlag)
    {
        return [NSString stringWithFormat:@"No service at Stop ID %@", self.locid];
    }
    return [NSString stringWithFormat:@"Stop ID %@", self.locid];
}

// From MapPinColor
- (MapPinColorValue) pinColor
{
    if (self.noServiceFlag)
    {
        return MAP_PIN_COLOR_RED;
    }
    return MAP_PIN_COLOR_GREEN;
}
- (bool)showActionMenu
{
    return YES;
}



- (NSString *)mapStopId
{
    return self.locid;
}

- (NSString *)mapStopIdText
{
    if (self.noServiceFlag)
    {
        return [NSString stringWithFormat:@"No service at ID %@", self.locid];
    }
    
     return [NSString stringWithFormat:@"Arrivals at Stop ID %@", self.locid];
}

- (UIColor *)pinTint
{
    return nil;
}


- (bool)hasBearing
{
    return NO;
}

- (double)doubleBearing
{
    return 0.0;
}

@end
