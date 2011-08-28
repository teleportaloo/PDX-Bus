//
//  BigRouteView.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/26/10.
//  Copyright 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewControllerBase.h"
#import "Departure.h"


@interface BigRouteView : ViewControllerBase {
	Departure *_departure;
	UIView *_textView;	}

@property (nonatomic, retain) Departure *departure;
@property (nonatomic, retain) UIView *textView;

@end
