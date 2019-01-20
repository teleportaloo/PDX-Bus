//
//  DetourLocation+iOSUI.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/7/18.
//  Copyright © 2018 Teleportaloo. All rights reserved.
//

#import "DetourLocation.h"
#import "MapPinColor.h"

@interface DetourLocation (iOSUI) <MapPinColor>

// From Annotation
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;

// From MapPinColor
@property (nonatomic, readonly) MapPinColorValue pinColor;
@property (nonatomic, readonly) bool showActionMenu;

@end
