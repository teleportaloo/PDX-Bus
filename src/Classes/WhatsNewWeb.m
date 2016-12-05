//
//  WhatsNewWeb.m
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/14.
//  Copyright (c) 2014 Teleportaloo. All rights reserved.
//




/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "WhatsNewWeb.h"
#import "WebViewController.h"

@implementation WhatsNewWeb

+ (NSNumber*)getPrefix
{
    return @'+';
}

- (void)processAction:(NSString *)text parent:(ViewControllerBase*)parent
{
    NSString *url = [self prefix:text restOfText:nil];
    
    [WebViewController displayPage:url
                              full:nil
                         navigator:parent.navigationController
                    itemToDeselect:nil
                          whenDone:nil];
    
}


@end
