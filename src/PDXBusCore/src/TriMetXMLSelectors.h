//
//  TriMetXMLSelectors.h
//  PDX Bus
//
//  Created by Andrew Wallace on 7/11/20.
//  Copyright © 2020 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


typedef NSDictionary<NSString *, NSString *> XmlAttributes;

typedef void (*XML_PROP_SETTER_IMP)(id, SEL, NSString *);
#define XML_PROP_SETTER_NAME                                                   \
    ^(NSString * el) {                                                         \
      return [NSString stringWithFormat:@"setXml_%@:", el];                    \
    }

#define XML_PROP_DEBUG @"setXML"
#define XML_START_DEBUG @"start "
#define XML_END_DEBUG @"end   "

#define XML_ATR_DICT attributeDict

#define XML_START_PREFIX @"sX"

#define XML_START_SELECTOR_NAME                                                \
    ^(NSString * el) {                                                         \
      return [NSString stringWithFormat:XML_START_PREFIX @"%@:", el];          \
    }

#define XML_START_ELEMENT(typeName)                                            \
    -(void)sX##typeName : (XmlAttributes *)XML_ATR_DICT

typedef void (*XML_START_ELEMENT_IMP)(id, SEL, NSDictionary *);

#define CALL_XML_START_ELEMENT_ON(X, typeName) [X sX##typeName:XML_ATR_DICT]

#define XML_END_PREFIX @"eX"

#define XML_END_SELECTOR_NAME                                                  \
    ^(NSString * el) {                                                         \
      return [XML_END_PREFIX stringByAppendingString:el];                      \
    }

#define XML_END_ELEMENT(typeName) -(void)eX##typeName

typedef void (*XML_END_ELEMENT_IMP)(id, SEL);

#define CALL_XML_END_ELEMENT_ON(X, typeName) [X eX##typeName]

#define CALL_XML_END_ELEMENT(typeName) CALL_XML_END_ELEMENT_ON(self, typeName)
#define CALL_XML_START_ELEMENT(typeName)                                       \
    CALL_XML_START_ELEMENT_ON(self, typeName)

#define XML_EQ(attr, val) ([attr caseInsensitiveCompare:val] == NSOrderedSame)

#define XML_ATR_FOR_KEY(dict, X) dict[X]

#define XML_ELNAME(typeName)                                                   \
    (NSOrderedSame == [elementName caseInsensitiveCompare:typeName])
#define XML_NULLABLE_ATR_STR(attr) ([XML_ATR_DICT nullOrStringForKey:attr])
#define XML_NULLABLE_ATR_NUM(attr) ([XML_ATR_DICT nullOrNumForKey:attr])
#define XML_ATR_INT_OR_MISSING(attr, def)                                      \
    ([XML_ATR_DICT missingOrIntForKey:attr missing:def])
#define XML_ATR_INT(attr) ([XML_ATR_DICT missingOrIntForKey:attr missing:0])
#define XML_NON_NULL_ATR_STR(attr)                                             \
    (XML_NON_NULL_STR(XML_ATR_FOR_KEY(XML_ATR_DICT, attr)))
#define XML_ATR_TIME(attr) ([XML_ATR_DICT getTimeForKey:attr])
#define XML_ATR_DATE(attr) ([XML_ATR_DICT getDateForKey:attr])
#define XML_ATR_BOOL_DEFAULT_FALSE(attr) ([XML_ATR_DICT getBoolForKey:attr])
#define XML_ATR_COORD(attr) ([XML_ATR_DICT getDoubleForKey:attr])
#define XML_ATR_LOCATION(lt, lg)                                               \
    [CLLocation withLat:XML_ATR_COORD(lt) lng:XML_ATR_COORD(lg)]
#define XML_ATR_DISTANCE(attr) ([XML_ATR_DICT getDistanceForKey:attr])
#define XML_ZERO_LEN_ATR_STR(attr) ([XML_ATR_DICT zeroLenOrStringForKey:attr])
