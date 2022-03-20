//
//  XMLAttributeTester.h
//  PDX BusTests
//
//  Created by Andrew Wallace on 10/3/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */




#import "../PDXBusCore/src/TriMetXML.h"
#import "../PDXBusCore/src/TriMetXMLSelectors.h"

NS_ASSUME_NONNULL_BEGIN

#define XML_TEST_ATTRIBUTE_TAG @"action"

@class XMLAttributeTester;

typedef void (^TestAction) (XmlAttributes *attributeDict, XMLAttributeTester *xml);

@interface XMLAttributeTester<ItemType> : TriMetXML<ItemType> 

@property (nonatomic, strong) NSDate *queryTime;
@property (nonatomic, copy) TestAction action;
@property (nonatomic)   NSInteger itemPos;

- (ItemType)nextItem;


@end

NS_ASSUME_NONNULL_END
