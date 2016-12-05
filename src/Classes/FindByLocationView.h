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


@interface FindByLocationView : TableViewWithToolbar<LocatingViewDelegate,MKMapViewDelegate>  {
	int                                             _maxToFind;
	TripMode                                        _mode;
	int                                             _show;
	int                                             _dist;
	double                                          _minDistance;
	int                                             _routeCount;
	int                                             _maxRouteCount;
	NSArray *                                       _cachedRoutes;
    int                                             _autoLaunch;
    NSDictionary *                                  _launchArgs;
    int                                             _firstDisplay;
    NSString *                                      _startingLocationName;
    CLLocation *                                    _startingLocation;
    MKCircle *                                      _circle;
    NSTimer *                                       _mapUpdateTimer;
    bool                                            _locationAuthorized;
    NSMutableDictionary<NSString*, NSNumber*> *     _lastLocate;
}

- (instancetype) initWithLocation:(CLLocation*)location description:(NSString*)locationName;
- (instancetype) init;
- (instancetype) initAutoLaunch;


@property (nonatomic, retain) NSArray *cachedRoutes;
@property (nonatomic, retain) NSMutableDictionary<NSString*, NSNumber*> *lastLocate;
@property (nonatomic)         int autoLaunch;
@property (nonatomic, copy)   NSString *startingLocationName;
@property (nonatomic, retain) CLLocation *startingLocation;
@property (nonatomic, retain) MKCircle *circle;
@property (nonatomic, retain) NSTimer *mapUpdateTimer;


- (void)distSegmentChanged:(id)sender;
- (void)modeSegmentChanged:(id)sender;
- (void)showSegmentChanged:(id)sender;
- (void)actionArgs:(NSDictionary *)args;

@end
