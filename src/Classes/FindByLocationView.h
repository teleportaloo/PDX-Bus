//
//  FindByLocationView.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "LocatingView.h"
#import "TriMetTypes.h"
#import "MapKit/Mapkit.h"
#import <IntentsUI/IntentsUI.h>

#define kMetresNextToMe MetresForMiles(0.1)
#define kMetresHalfMile MetresForMiles(0.5)
#define kMaxStops       20
#define kAccNextToMe    150
#define kAccHalfMile    150
#define kAccClosest     250
#define kAccMile        300
#define kAcc3Miles      800

@interface FindByLocationView : TableViewWithToolbar<LocatingViewDelegate, MKMapViewDelegate, INUIAddVoiceShortcutViewControllerDelegate>

- (instancetype)initWithLocation:(CLLocation *)location description:(NSString *)locationName;
- (instancetype)  init;

- (void)actionArgs:(NSDictionary *)args;

+ (NSDictionary *)nearbyArrivalInfo;


@end
