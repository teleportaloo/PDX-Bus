//
//  TriMetInfo.m
//  PDX Bus
//
//  Created by Andrew Wallace on 9/30/10.
//  Copyright 2010. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#import "TriMetInfo.h"
#import "PDXBusCore.h"
#import "DebugLogging.h"

@implementation TriMetInfo

#define RGB(R, G, B) (((((R) & 0xFF) << 16) | (((G) & 0xFF) << 8) | ((B) & 0xFF)))
#define RGB_RED   RGB(255,  0,  0)
#define RGB_WHITE RGB(255, 255, 255)

// These must be in route order and the line bits also in order so a binary search works on either!
// uncrustify-off
static const ROUTE_INFO allRailLines[] =
{//   Route     Route Bit      Op Dir Interline HTML Color  Back color  Wiki                            Name                            Short name    Streetcar Order   Phase   Pattern
    { 90,       (0x1 << 0),    kDir1, kNoRoute, 0xD31F43,   RGB_WHITE,  @"MAX_Red_Line",                @"MAX Red Line",                @"MAX",       NO,       3,      0,      2,          @"red",     },   // Red line
    { 100,      (0x1 << 1),    kDir1, kNoRoute, 0x0F6AAC,   RGB_RED,    @"MAX_Blue_Line",               @"MAX Blue Line",               @"MAX",       NO,       0,      0.5,    2,          @"blue"     },   // Blue Line
    { 190,      (0x1 << 2),    kDir1, 290,      0xFFC524,   RGB_RED,    @"MAX_Yellow_Line",             @"MAX Yellow Line",             @"MAX",       NO,       4,      1.0,    2,          @"yellow"   },   // Yellow line
    { 193,      (0x1 << 3),    kDir1, kNoRoute, 0x8CC63F,   RGB_WHITE,  @"Portland_Streetcar",          @"Portland Streetcar - NS Line",@"NS Line",   YES,      6,      0,      2,          @"ns"       },   // Streetcar Green
    { 194,      (0x1 << 4),    195,   kNoRoute, 0xE01D90,   RGB_WHITE,  @"Portland_Streetcar",          @"Portland Streetcar - A Loop", @"A Loop",    YES,      7,      1.5,    2,          @"a loop"   },   // Streetcar Blue
    { 195,      (0x1 << 5),    194,   kNoRoute, 0x00A9CC,   RGB_WHITE,  @"Portland_Streetcar",          @"Portland Streetcar - B Loop", @"B Loop",    YES,      8,      2,      2,          @"b loop"   },   // Streetcar Pink
    { 200,      (0x1 << 6),    kDir1, kNoRoute, 0x028953,   RGB_WHITE,  @"MAX_Green_Line",              @"MAX Green Line",              @"MAX",       NO,       1,      1.75,   2,          @"green"    },   // Green Line
    { 203,      (0x1 << 7),    kDir1, kNoRoute, 0x000000,   RGB_WHITE,  @"Westside_Express_Service",    @"WES Commuter Rail",           @"WES",       NO,       5,      0,      1,          @"wes"      },   // WES Black
    { 290,      (0x1 << 8),    kDir1, 190,      0xD15F27,   RGB_WHITE,  @"MAX_Orange_Line",             @"MAX Orange Line",             @"MAX",       NO,       2,      1.75,   2,          @"orange"   },   // MAX Orange
    { kNoRoute,  0x0,          kNoDir,kNoRoute, 0x000000,   RGB_WHITE,  nil,                            nil,                            nil,          NO,       9,      0,      0,          nil         }    // Terminator
};

#define BUS_FLEET(Y, M, MO, LENGTH, MIN, MAX)   { MIN,         MAX,         @"Bus",      @M, @MO, @Y, NO,   nil}
#define BUS_INFO1(Y, M, MO, LENGTH, NUM, INFO)  { NUM,         NUM,         @"Bus",      @M, @MO, @Y, NO,   INFO}
#define MAX_FLEET(T, MIN, MAX, M, MO, Y)        { MIN,         MAX,         @"MAX " T,   @M, @MO, @Y, YES,  nil}
#define WES_FLEET(MIN, MAX, M, MO, Y)           { MIN,         MAX,         @"WES",      @M, @MO, @Y, YES,  nil}
#define STREETCAR_FLEET(M, MO, N, Y, MIN, MAX ) { 1##MIN-1000, 1##MAX-1000, @"Streetcar",@M, @MO, @Y, NO,   nil}
#define STREETCAR_WINFO(M, MO, N, Y, MIN, MAX, I) { 1##MIN-1000, 1##MAX-1000, @"Streetcar",@M, @MO, @Y, NO,   I}
// Note - the weird macro for the streetcar numbers is because prefixing a number with 0 in C will make it octal,
// but the streetcar numbers are usually written with leading zeros, so we mangle them a bit by adding a leading 1
// and then removing it.  So in the end they end up as decimal but I can use the leading zeros.

#define NO_VEHICLE_ID (-1)

// From Wikipedia - formatted like their tables to make it easy to check
// https://en.wikipedia.org/wiki/TriMet
// https://en.wikipedia.org/wiki/Portland_Streetcar

#define MORE_INFO   "#b(more info)#b#T"
#define kBombardier "Bombardier #Lhttps://en.wikipedia.org/wiki/Bombardier_Transportation " MORE_INFO
#define kD40LF      "D40LF #Lhttps://en.wikipedia.org/wiki/New_Flyer_Low_Floor " MORE_INFO
#define kD40LFR     "D40LFR #Lhttps://en.wikipedia.org/wiki/New_Flyer_Low_Floor " MORE_INFO
#define kLFBRT      "Low Floor BRT #Lhttps://en.wikipedia.org/wiki/Gillig_Low_Floor " MORE_INFO
#define kLFBRTH     "Low Floor BRT Hybrid #Lhttps://en.wikipedia.org/wiki/Gillig_Low_Floor " MORE_INFO
#define kXC         "Xcelsior CHARGE™ ⚡︎ #Lhttps://en.wikipedia.org/wiki/New_Flyer_Xcelsior " MORE_INFO
#define kSD660      "SD660 #Lhttps://en.wikipedia.org/wiki/Siemens_SD660 " MORE_INFO
#define kS70        "S70 #Lhttps://en.wikipedia.org/wiki/Siemens_S70 " MORE_INFO
#define k10T        "10 T #Lhttps://en.wikipedia.org/wiki/Skoda_10_T " MORE_INFO
#define kTrio12     "Trio type 12 #Lhttps://en.wikipedia.org/wiki/Inekon_12_Trio " MORE_INFO
#define kUnited     "United Streetcar #Lhttps://en.wikipedia.org/wiki/United_Streetcar " MORE_INFO

// NOTE - this table is searched so must be in order of ID - the wikipedia article is not in order
static const VEHICLE_INFO vehicleTypes[] =
{
    // https://en.wikipedia.org/wiki/Portland_Streetcar
    // The numbers are not octal - they get mangled by the macro to be decimal.
    STREETCAR_FLEET("Škoda",            k10T,                   7,    "2001–02",        001,007),
    STREETCAR_FLEET("Inekon Trams",     kTrio12,                3,    "2006",           008,010),
    STREETCAR_FLEET(kUnited,            "10T3 (prototype)",     1,    "2009",           015,015),
    STREETCAR_FLEET(kUnited,            "100",                  2,    "2012–14",        021,022),
    STREETCAR_WINFO(kUnited,            "100",                  1,    "2012–14",        023,023, @"🏳️‍🌈 Progress Pride Car #Lhttps://portlandstreetcar.org/news/2020/06/portland-streetcar-celebrates-pride-month-with-progress-flag-streetcar (more info)#T"),
    STREETCAR_FLEET(kUnited,            "100",                  3,    "2012–14",        024,026),
    
    MAX_FLEET("Type 1",     101,126,     kBombardier,      "",        "1986" ),  //   76/166     26
    MAX_FLEET("Type 2",     201,252,     "Siemens",        kSD660,    "1997" ),  //   64/166     52
    MAX_FLEET("Type 3",     301,327,     "Siemens",        kSD660,    "2003" ),  //   64/166     27
    MAX_FLEET("Type 4",     401,422,     "Siemens",        kS70,      "2009" ),  //   68/172[58]     22
    MAX_FLEET("Type 5",     521,538,     "Siemens",        kS70,      "2015" ),  //   72/186[56]     18
    
    WES_FLEET(1001,1003, "Colorado Railcar",      "Aero", "2009 (made in 2008)"),   //      2009     Diesel multiple units (DMUs)
    WES_FLEET(1702,1702, "Budd",                  "RDC",  "2011 (made in 1953)"),   //      2011     Ex-Alaska Railroad 702; originally New Haven 129[36]
    WES_FLEET(1711,1711, "Budd",                  "RDC",  "2011 (made in 1952)"),   //      2011     Ex-Alaska Railroad 711; originally New Haven 121[36]
    WES_FLEET(2001,2001, "Colorado Railcar",      "Aero", "2009 (made in 2008)"),   //      2009     Unpowered control car
    WES_FLEET(2007,2007, "Budd",                  "RDC",   "1957"),                 //      1957     Ex-Trinity Railway Express (Dallas) 2007; ex-Via Rail
    WES_FLEET(2011,2011, "Budd",                  "RDC",   "1957"),                 //      1957     Ex-Trinity Railway Express (Dallas) 2011;[40] ex-Via Rail
    
    BUS_FLEET("1998–99",    "New Flyer",    kD40LF,        "40", 2201, 2318 ),
    BUS_FLEET("2000–01",    "New Flyer",    kD40LF,        "40", 2501, 2560 ),
    BUS_FLEET("2002",       "New Flyer",    kD40LF,        "40", 2601, 2655 ),
    BUS_FLEET("2003",       "New Flyer",    kD40LF,        "40", 2701, 2725 ),
    BUS_FLEET("2005",       "New Flyer",    kD40LF,        "40", 2801, 2839 ),
    BUS_FLEET("2008–09",    "New Flyer",    kD40LFR,       "40", 2901, 2940 ),
    BUS_FLEET("2012",       "Gillig",       kLFBRT,        "40", 3001, 3051 ),
    BUS_FLEET("2012",       "Gillig",       kLFBRTH,       "40", 3052, 3055 ),
    BUS_FLEET("2015",       "Gillig",       kLFBRTH,       "40", 3056, 3059 ),
    BUS_FLEET("2013",       "Gillig",       kLFBRT,        "40", 3101, 3134 ),
    BUS_INFO1("2013",       "Gillig",       kLFBRT,        "40", 3135, @" 🎉 1970's bus - #bTriMet 50th Birthday bus#b"),
    BUS_FLEET("2013",       "Gillig",       kLFBRT,        "40", 3136, 3170 ),
    BUS_FLEET("2014",       "Gillig",       kLFBRT,        "40", 3201, 3260 ),
    BUS_FLEET("2015",       "Gillig",       kLFBRT,        "40", 3261, 3268 ),
    BUS_FLEET("2014",       "Gillig",       kLFBRT,        "40", 3301, 3330 ),
    BUS_FLEET("2015",       "Gillig",       kLFBRT,        "29", 3401, 3422 ),
    BUS_FLEET("2015",       "Gillig",       kLFBRT,        "40", 3501, 3577 ),
    BUS_FLEET("2016",       "Gillig",       kLFBRT,        "40", 3601, 3650 ),
    BUS_FLEET("2017",       "Gillig",       kLFBRT,        "40", 3701, 3744 ),
    BUS_INFO1("2017",       "Gillig",       kLFBRT,        "40", 3745, @"🏳️‍🌈 #ball are welcome#b 🏳️‍🌈"),
    BUS_FLEET("2017",       "Gillig",       kLFBRT,        "40", 3746, 3757 ),
    BUS_FLEET("2018–19",    "New Flyer",    kXC,           "40", 3801, 3805 ),
    BUS_FLEET("2018-19",    "Gillig",       kLFBRT,        "40", 3901, 3964 ),
    BUS_FLEET("2019–20",    "Gillig",       kLFBRT,        "40", 4001, 4071 )
};

// uncrustify-on

#define VEHICLES ((sizeof(vehicleTypes) / sizeof(vehicleTypes[0])))

int compareVehicle(const void *first, const void *second) {
    NSInteger key = ((PC_VEHICLE_INFO)first)->min;
    PC_VEHICLE_INFO range = (VEHICLE_INFO *)second;
    
    // The documentation of bsearch says the first argument was
    // always the key i.e. the single item
    DEBUG_LOGL(key);
    DEBUG_LOGL(range->min);
    DEBUG_LOGL(range->max);
    
    if (key < range->min) {
        return -1;
    } else if (key > range->max) {
        return 1;
    }
    
    return 0;
}

void checkTable(const void *base, size_t nel, size_t width, int(*_Nonnull compar)(const void *, const void *), NSString *info) {
    const void *p = base;
    const void *c = base + width;
    bool error = NO;
    
    for (int i = 1; i < nel; i++) {
        if ((*compar)(p, c) > 0) {
            ERROR_LOG(@"%@:  %d is less than previous", info, (int)i);
            error = YES;
        }
        
        p += width;
        c += width;
    }
    
    if (!error) {
        DEBUG_LOG(@"Checked %@ - table is good", info);
    }
}

+ (PC_VEHICLE_INFO)vehicleInfo:(NSInteger)vehicleId {
#ifdef DEBUGLOGGING
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        checkTable(vehicleTypes, VEHICLES, sizeof(VEHICLE_INFO), compareVehicle, @"vehicleTypes");
    });
#endif
    
    VEHICLE_INFO key = { vehicleId, NO_VEHICLE_ID, nil, nil, nil, nil };
    return bsearch(&key, vehicleTypes, VEHICLES, sizeof(VEHICLE_INFO), compareVehicle);
}

+ (NSString *)vehicleString:(NSString *)vehicleId {
    NSString *string;
    const VEHICLE_INFO *vehicle = [TriMetInfo vehicleInfo:vehicleId.integerValue];
    
    if (vehicle == nil) {
        if (vehicleId != nil) {
            string = [NSString stringWithFormat:@"Vehicle ID #b%@#b\n#b#RNo vehicle info.#b", vehicleId];
        } else {
            string = @"#b#RNo vehicle info.#b";
        }
    } else {
        string = [NSString stringWithFormat:@"Vehicle ID #D#b%@#b - #b%@#b#D\nMade by #b%@#b#D%@\nIntroduced #b#D%@#b#D%@",
                   vehicleId,
                   vehicle->type,
                   vehicle->manufacturer,
                   vehicle->model.length != 0 ? [NSString stringWithFormat:@"\nModel #D#b%@#b", vehicle->model] : @"",
                   vehicle->first_used,
                   vehicle->specialInfo ? [NSString stringWithFormat:@"\n%@", vehicle->specialInfo] : @""
                   ];
    }
    
    return string;
}

+ (NSString *)vehicleIdFromStreetcarId:(NSString *)streetcarId {
    // Streetcar ID is of the form S024 - we drop the S
    
    if ([streetcarId hasPrefix:@"SC"]) {
        return [streetcarId substringFromIndex:2];
    }
    
    if ([streetcarId hasPrefix:@"S"]) {
        return [streetcarId substringFromIndex:1];
    }
    
    return streetcarId;
}

#pragma mark Routes and Lines and Colors

int compareRoute(const void *first, const void *second) {
    return (int)(((ROUTE_INFO *)first)->route_number - ((ROUTE_INFO *)second)->route_number);
}

int compareLine(const void *first, const void *second) {
    return (int)((int)((ROUTE_INFO *)first)->line_bit - (int)((ROUTE_INFO *)second)->line_bit);
}

#define ROUTES ((sizeof(allRailLines) / sizeof(allRailLines[0])) - 1)


+ (PC_ROUTE_INFO)infoForKeyword:(NSString *)key {
    NSString *lower = [key lowercaseString];
    
    for (PC_ROUTE_INFO info = allRailLines; info->route_number != kNoRoute; info++) {
        if ([lower containsString:info->key_word]) {
            return info;
        }
    }
    
    return nil;
}

+ (PC_ROUTE_INFO)infoForLine:(RAILLINES)line {
#ifdef DEBUGLOGGING
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        checkTable(allRailLines, ROUTES, sizeof(ROUTE_INFO), compareLine, @"compareLine");
    });
#endif
    
    ROUTE_INFO key = { 0, line, 0, 0, 0, 0, nil, nil, nil, NO };
    return bsearch(&key, allRailLines, ROUTES, sizeof(ROUTE_INFO), compareLine);
}

+ (PC_ROUTE_INFO)infoForRouteNum:(NSInteger)route {
#ifdef DEBUGLOGGING
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        checkTable(allRailLines, ROUTES, sizeof(ROUTE_INFO), compareRoute, @"compareRoute");
    });
#endif
    
    ROUTE_INFO key = { route, 0, 0, 0, 0, 0, nil, nil, nil, NO };
    return bsearch(&key, allRailLines, ROUTES, sizeof(ROUTE_INFO), compareRoute);
}

+ (PC_ROUTE_INFO)infoForRoute:(NSString *)route {
    return [TriMetInfo infoForRouteNum:route.integerValue];
}

+ (UIColor *)cachedColor:(NSInteger)col {
    static NSMutableDictionary<NSNumber *, UIColor *> *colorCache;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        colorCache = [NSMutableDictionary dictionary];
        
        for (PC_ROUTE_INFO col = allRailLines; col->route_number != kNoRoute; col++) {
            [colorCache setObject:HTML_COLOR(col->html_color)     forKey:@(col->html_color)];
            [colorCache setObject:HTML_COLOR(col->html_bg_color)  forKey:@(col->html_bg_color)];
        }
    });
    
    return colorCache[@(col)];
}

+ (UIColor *)colorForRoute:(NSString *)route {
    PC_ROUTE_INFO routeInfo = [TriMetInfo infoForRoute:route];
    
    if (routeInfo == nil) {
        return nil;
    }
    
    return [TriMetInfo cachedColor:routeInfo->html_color];
}

+ (UIColor *)colorForLine:(RAILLINES)line {
    PC_ROUTE_INFO routeInfo = [TriMetInfo infoForLine:line];
    
    if (routeInfo == nil) {
        return nil;
    }
    
    return [TriMetInfo cachedColor:routeInfo->html_color];
}

+ (NSSet<NSString *> *)streetcarRoutes {
    static NSMutableSet<NSString *> *routeIds = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        routeIds = [NSMutableSet set];
        
        for (PC_ROUTE_INFO info = allRailLines; info->route_number != kNoRoute; info++) {
            if (info->streetcar) {
                [routeIds addObject:[TriMetInfo routeString:info]];
            }
        }
    });
    
    return routeIds;
}

+ (NSSet<NSString *> *)triMetRailLines {
    static NSMutableSet<NSString *> *routeIds = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        routeIds = [NSMutableSet set];
        
        for (PC_ROUTE_INFO routeInfo = allRailLines; routeInfo->route_number != kNoRoute; routeInfo++) {
            if (!routeInfo->streetcar) {
                [routeIds addObject:[TriMetInfo routeString:routeInfo]];
            }
        }
    });
    
    return routeIds;
}

+ (NSString *)routeString:(const ROUTE_INFO *)info {
    return [NSString stringWithFormat:@"%ld", (long)info->route_number];
}

+ (NSString *)interlinedRouteString:(const ROUTE_INFO *)info {
    return [NSString stringWithFormat:@"%ld", (long)info->interlined_route];
}

+ (const ROUTE_INFO *)allColoredLines {
    return allRailLines;
}

@end
