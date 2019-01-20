//
//  SupportView.h
//  TriMetTimes
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



#import <UIKit/UIKit.h>
#import "TableViewWithToolbar.h"
#import <CoreLocation/CoreLocation.h>

#define kTips                    2

@interface SupportView : TableViewWithToolbar  <CLLocationManagerDelegate> {
    NSAttributedString *supportText;
    NSArray *tipText;

    bool _cameraGoesToSettings;
    bool _locationGoesToSettings;
}

@property (nonatomic) bool hideButton;
@property (nonatomic, strong) CLLocationManager *locMan;
@property (nonatomic, copy)   NSString *locationText;
@property (nonatomic, copy)   NSString *cameraText;

@end
