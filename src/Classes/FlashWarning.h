//
//  FlashWarning.h
//  PDX Bus
//
//  Created by Andrew Wallace on 11/27/13.
//  Copyright (c) 2013 Teleportaloo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ViewControllerBase.h"

@interface FlashWarning : NSObject <UIAlertViewDelegate>
{
    UINavigationController  *_nav;
    UIAlertView             *_alert;
    ViewControllerBase      *_parentBase;
}

@property (nonatomic, retain) UINavigationController *nav;
@property (nonatomic, retain) UIAlertView        *alert;
@property (nonatomic, retain) ViewControllerBase *parentBase;

- (id)initWithNav:(UINavigationController *)newNav;



@end
