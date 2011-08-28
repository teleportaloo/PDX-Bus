//
//  Stop.h
//  TriMetTimes
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */

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
- (bool) mapDisclosure;
- (bool) mapTapped:(id<BackgroundTaskProgress>) progress;
-(NSString*)stringToFilter;

@end

@protocol ReturnStop
- (void) chosenStop:(Stop *)stop progress:(id<BackgroundTaskProgress>) progress;
- (NSString *)actionText;
@end

