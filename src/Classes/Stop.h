//
//  Stop.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <UIKit/UIKit.h>
#import "MapPinColor.h"
#import "SearchFilter.h"


@protocol ReturnStop;
@protocol BackgroundTaskProgress;



@interface Stop : NSObject <MapPinColor, SearchFilter> {
	NSString		*_locid;
	bool			_tp;
	NSString		*_desc;
	NSString		*_lat;
	NSString		*_lng;
	id<ReturnStop> _callback;
	NSString        *_dir;
	int			    index;
}

@property (nonatomic, retain) NSString *locid;
@property (nonatomic, retain) NSString *desc;
@property (nonatomic, retain) NSString *dir;
@property (nonatomic) bool tp;
@property (nonatomic, retain) NSString *lat;
@property (nonatomic, retain) NSString *lng;
@property (nonatomic, retain) id<ReturnStop> callback;
@property (nonatomic) int index;

- (MKPinAnnotationColor) getPinColor;
- (bool) showActionMenu;
- (bool) mapTapped:(id<BackgroundTaskProgress>) progress;
- (NSString*)stringToFilter;

@end

@protocol ReturnStop
- (void) chosenStop:(Stop *)stop progress:(id<BackgroundTaskProgress>) progress;
- (NSString *)actionText;
@end

