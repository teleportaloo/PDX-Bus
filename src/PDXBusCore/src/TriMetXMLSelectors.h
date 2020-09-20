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


#define XML_SHORT_SELECTORS 1

typedef NSDictionary<NSString *, NSString *> xmlAttributes;

#define XML_ATR_DICT                           attributeDict

#ifdef XML_SHORT_SELECTORS

#define XML_START_SELECTOR                     @"startX%@:"
#define XML_START_ELEMENT(typeName)            - (void)startX ## typeName: (xmlAttributes *)XML_ATR_DICT
#define CALL_XML_START_ELEMENT_ON(X, typeName) [X startX ## typeName:attributeDict]

#define XML_END_SELECTOR                       @"endX%@"
#define XML_END_ELEMENT(typeName)              - (void)endX ## typeName
#define CALL_XML_END_ELEMENT_ON(X, typeName)   [X endX ## typeName]

#else

#define XML_START_SELECTOR                     @"parser:didStartX%@:namespaceURI:qualifiedName:attributes:"
#define XML_START_ELEMENT(typeName)            - (void)parser: (NSXMLParser *)parser didStartX ## typeName: (NSString *)elementName namespaceURI: (NSString *)namespaceURI qualifiedName: (NSString *)qName attributes: (xmlAttributes *)XML_ATR_DICT
#define CALL_XML_START_ELEMENT_ON(X, typeName) [X parser:parser didStartX ## typeName:elementName namespaceURI:namespaceURI qualifiedName:qName attributes:attributeDict]

#define XML_END_SELECTOR                       @"parser:didEndX%@:namespaceURI:qualifiedName:"
#define XML_END_ELEMENT(typeName)              - (void)parser: (NSXMLParser *)parser didEndX ## typeName: (NSString *)elementName namespaceURI: (NSString *)namespaceURI qualifiedName: (NSString *)qName
#define CALL_XML_END_ELEMENT_ON(X, typeName)   [X parser:parser didEndX ## typeName:elementName namespaceURI:namespaceURI qualifiedName:qName]

#endif

#define CALL_XML_END_ELEMENT(typeName)         CALL_XML_END_ELEMENT_ON(self, typeName)
#define CALL_XML_START_ELEMENT(typeName)       CALL_XML_START_ELEMENT_ON(self, typeName)

#define XML_EQ(attr, val)                      ([attr caseInsensitiveCompare:val] == NSOrderedSame)

// Two options - we use a case-insensative search just in case the XML changed.
// #define XML_ATR_FOR_KEY(dict, X)               dict[X]
#define XML_ATR_FOR_KEY(dict, X)               [dict objectForCaseInsensitiveKey:(X)]


#define XML_ELNAME(typeName)                   (NSOrderedSame == [elementName caseInsensitiveCompare:typeName])
#define XML_NULLABLE_ATR_STR(attr)             ([XML_ATR_DICT nullOrSafeStringForKey:attr])
#define XML_NULLABLE_ATR_NUM(attr)             ([XML_ATR_DICT nullOrSafeNumForKey:attr])
#define XML_ATR_INT_ZERO(attr)                 ([XML_ATR_DICT zeroOrSafeIntForKey:attr])
#define XML_NON_NULL_ATR_STR(attr)             (XML_NON_NULL_STR(XML_ATR_FOR_KEY(XML_ATR_DICT, attr)))
#define XML_ATR_TIME(attr)                     ([XML_ATR_DICT getTimeForKey:attr])
#define XML_ATR_DATE(attr)                     ([XML_ATR_DICT getDateForKey:attr])
#define XML_ATR_INT(attr)                      ([XML_ATR_DICT getNSIntegerForKey:attr])
#define XML_ATR_BOOL(attr)                     ([XML_ATR_DICT getBoolForKey:attr])
#define XML_ATR_COORD(attr)                    ([XML_ATR_DICT getDoubleForKey:attr])
#define XML_ATR_LOCATION(lt, lg)               [CLLocation withLat:XML_ATR_COORD(lt) lng:XML_ATR_COORD(lg)]
#define XML_ATR_DISTANCE(attr)                 ([XML_ATR_DICT getDistanceForKey:attr])
#define XML_ZERO_LEN_ATR_STR(attr)             (XML_ATR_FOR_KEY(XML_ATR_DICT, attr))
