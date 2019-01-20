//
//  XMLDetoursAndMessages.h
//  PDX Bus
//
//  Created by Andrew Wallace on 4/29/18.
//  Copyright © 2018 Andrew Wallace
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import <Foundation/Foundation.h>
#import "XMLDetours.h"
#import "XMLStreetcarMessages.h"


@interface XMLDetoursAndMessages : TriMetXML

@property (nonatomic, strong) XMLStreetcarMessages * messages;
@property (nonatomic, strong) NSArray<NSString *> * routes;
@property (nonatomic, strong) XMLDetours * detours;

- (void)checkRoutesForStreetcar:(NSArray<NSString *>*)routes;
- (instancetype)initWithRoutes:(NSArray<NSString *>*)routes;
- (void)fetchDetoursAndMessages;

+ (instancetype)XmlWithRoutes:(NSArray<NSString *>*)routes;
@end
