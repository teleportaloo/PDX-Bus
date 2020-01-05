//
//  FindByLocationView.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "StopLocations.h"
#import "LocatingView.h"
#import "TriMetTypes.h"
#import "MapKit/Mapkit.h"
#import <IntentsUI/IntentsUI.h>



@interface FindByLocationView : TableViewWithToolbar<LocatingViewDelegate,MKMapViewDelegate,INUIAddVoiceShortcutViewControllerDelegate>  {
    int         _maxToFind;
    int         _maxRouteCount;
    TripMode    _mode;
    int         _show;
    int         _dist;
    double      _minMetres;
    int         _routeCount;
    int         _firstDisplay;
    bool        _locationAuthorized;
}

@property (nonatomic, strong) NSArray *cachedRoutes;
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSNumber*> *lastLocate;
@property (nonatomic)         int autoLaunch;
@property (nonatomic, copy)   NSString *startingLocationName;
@property (nonatomic, strong) CLLocation *startingLocation;
@property (nonatomic, strong) MKCircle *circle;
@property (nonatomic, strong) NSTimer *mapUpdateTimer;
@property (nonatomic, strong) NSUserActivity *userActivity;

- (instancetype)initWithLocation:(CLLocation*)location description:(NSString*)locationName;
- (instancetype)init;
- (void)distSegmentChanged:(id)sender;
- (void)modeSegmentChanged:(id)sender;
- (void)showSegmentChanged:(id)sender;
- (void)actionArgs:(NSDictionary *)args;

+ (NSDictionary *)nearbyArrivalInfo;


@end
