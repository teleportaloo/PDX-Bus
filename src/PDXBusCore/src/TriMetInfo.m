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

#define RGB(R,G,B)      (((((R)&0xFF)<<16) | (((G)&0xFF) <<8) | ((B) & 0xFF)))
#define RGB_RED         RGB(255,  0,  0)
#define RGB_WHITE       RGB(255,255,255)

// These must be in route order and the line bits also in order so a binary search works on either!
static const ROUTE_INFO allRailLines[] =
{//   Route     Route Bit      Op Dir Interline HTML Color  Back color  Wiki                            Name                            Short name    Streetcar Order   Phase   Pattern
    { 90,       (0x1 << 0),    kDir1, kNoRoute, 0xD31F43,   RGB_WHITE,  @"MAX_Red_Line",                @"MAX Red Line",                @"MAX",       NO,       3,      0,      2},   // Red line
    { 100,      (0x1 << 1),    kDir1, kNoRoute, 0x0F6AAC,   RGB_RED,    @"MAX_Blue_Line",               @"MAX Blue Line",               @"MAX",       NO,       0,      0.5,    2},   // Blue Line
    { 190,      (0x1 << 2),    kDir1, 290,      0xFFC524,   RGB_RED,    @"MAX_Yellow_Line",             @"MAX Yellow Line",             @"MAX",       NO,       4,      1.0,    2},   // Yellow line
    { 193,      (0x1 << 3),    kDir1, kNoRoute, 0x8CC63F,   RGB_WHITE,  @"Portland_Streetcar",          @"Portland Streetcar - NS Line",@"NS Line",   YES,      6,      0,      2},   // Streetcar Green
    { 194,      (0x1 << 4),    195,   kNoRoute, 0xE01D90,   RGB_WHITE,  @"Portland_Streetcar",          @"Portland Streetcar - A Loop", @"A Loop",    YES,      7,      1.5,    2},   // Streetcar Blue
    { 195,      (0x1 << 5),    194,   kNoRoute, 0x00A9CC,   RGB_WHITE,  @"Portland_Streetcar",          @"Portland Streetcar - B Loop", @"B Loop",    YES,      8,      2,      2},   // Streetcar Pink
    { 200,      (0x1 << 6),    kDir1, kNoRoute, 0x028953,   RGB_WHITE,  @"MAX_Green_Line",              @"MAX Green Line",              @"MAX",       NO,       1,      1.75,   2},   // Green Line
    { 203,      (0x1 << 7),    kDir1, kNoRoute, 0x000000,   RGB_WHITE,  @"Westside_Express_Service",    @"WES Commuter Rail",           @"WES",       NO,       5,      0,      1},   // WES Black
    { 290,      (0x1 << 8),    kDir1, 190,      0xD15F27,   RGB_WHITE,  @"MAX_Orange_Line",             @"MAX Orange Line",             @"MAX",       NO,       2,      1.75,   2},   // MAX Orange
    { kNoRoute,  0x0,          kNoDir,kNoRoute, 0x000000,   RGB_WHITE,  nil,                            nil,                            nil,          NO,       9,      0,      0}    // Terminator
};


#define BUS_FLEET(Y, M, MO, LENGTH, MIN, MAX)   { MIN,         MAX,         @"Bus",      @M, @MO, @Y, NO  }
#define MAX_FLEET(T, MIN, MAX, M, MO, Y)        { MIN,         MAX,         @"MAX " T,   @M, @MO, @Y, YES }
#define WES_FLEET(MIN, MAX, M, MO, Y)           { MIN,         MAX,         @"WES",      @M, @MO, @Y, YES }
#define STREETCAR_FLEET(M, MO, N, Y, MIN, MAX ) { 1##MIN-1000, 1##MAX-1000, @"Streetcar",@M, @MO, @Y, NO  }

// Note - the weird macro for the streetcar numbers is because prefixing a number with 0 in C will make it octal,
// but the streetcar numbers are usually written with leading zeros, so we mangle them a bit by adding a leading 1
// and then removing it.  So in the end they end up as decimal but I can use the leading zeros.

#define NO_VEHICLE_ID (-1)

// From Wikipedia - formatted like their tables to make it easy to check
// https://en.wikipedia.org/wiki/TriMet
// https://en.wikipedia.org/wiki/Portland_Streetcar

// NOTE - this table is searched so must be in order of ID - the wikipedia article is not in order
static const VEHICLE_INFO vehicleTypes[] =
{
    // https://en.wikipedia.org/wiki/Portland_Streetcar
    // The numbers are not octal - they get mangled by the macro to be decimal.
    STREETCAR_FLEET("Škoda",            "10T",                  7,    "2001–02",        001,007),
    STREETCAR_FLEET("Inekon Trams",     "Trio type 12",         3,    "2006",           008,010),
    STREETCAR_FLEET("United Streetcar", "10T3 (prototype)",     1,    "2009",           015,015),
    STREETCAR_FLEET("United Streetcar", "100",                  6,    "2012–14",        021,026),
    
    MAX_FLEET("Type 1",     101,126,     "Bombardier",     "",         "1986" ),  //   76/166     26
    MAX_FLEET("Type 2",     201,252,     "Siemens",        "SD660",    "1997" ),  //   64/166     52
    MAX_FLEET("Type 3",     301,327,     "Siemens",        "SD660",    "2003" ),  //   64/166     27
    MAX_FLEET("Type 4",     401,422,     "Siemens",        "S70",      "2009" ),  //   68/172[58]     22
    MAX_FLEET("Type 5",     521,538,     "Siemens",        "S70",      "2015" ),  //   72/186[56]     18
  
    WES_FLEET(1001,1003, "Colorado Railcar",      "Aero", "2009 (made in 2008)"),   //      2009     Diesel multiple units (DMUs)
    WES_FLEET(1702,1702, "Budd",                  "RDC",  "2011 (made in 1953)"),   //      2011     Ex-Alaska Railroad 702; originally New Haven 129[36]
    WES_FLEET(1711,1711, "Budd",                  "RDC",  "2011 (made in 1952)"),   //      2011     Ex-Alaska Railroad 711; originally New Haven 121[36]
    WES_FLEET(2001,2001, "Colorado Railcar",      "Aero", "2009 (made in 2008)"),   //      2009     Unpowered control car
    
    BUS_FLEET("1998–99",    "New Flyer",    "D40LF",                "40", 2201, 2318 ),
    BUS_FLEET("2000–01",    "New Flyer",    "D40LF",                "40", 2501, 2560 ),
    BUS_FLEET("2002",       "New Flyer",    "D40LF",                "40", 2601, 2655 ),
    BUS_FLEET("2003",       "New Flyer",    "D40LF",                "40", 2701, 2725 ),
    BUS_FLEET("2005",       "New Flyer",    "D40LF",                "40", 2801, 2839 ),
    BUS_FLEET("2008–09",    "New Flyer",    "D40LFR",               "40", 2901, 2940 ),
    BUS_FLEET("2012",       "Gillig",       "Low Floor BRT",        "40", 3001, 3051 ),
    BUS_FLEET("2012",       "Gillig",       "Low Floor BRT Hybrid", "40", 3052, 3055 ),
    BUS_FLEET("2015",       "Gillig",       "Low Floor BRT Hybrid", "40", 3056, 3059 ),
    BUS_FLEET("2013",       "Gillig",       "Low Floor BRT",        "40", 3101, 3170 ),
    BUS_FLEET("2014",       "Gillig",       "Low Floor BRT",        "40", 3201, 3260 ),
    BUS_FLEET("2015",       "Gillig",       "Low Floor BRT",        "40", 3261, 3268 ),
    BUS_FLEET("2014",       "Gillig",       "Low Floor BRT",        "40", 3301, 3330 ),
    BUS_FLEET("2015",       "Gillig",       "Low Floor BRT",        "29", 3401, 3422 ),
    BUS_FLEET("2015",       "Gillig",       "Low Floor BRT",        "40", 3501, 3577 ),
    BUS_FLEET("2016",       "Gillig",       "Low Floor BRT",        "40", 3601, 3650 ),
    BUS_FLEET("2017",       "Gillig",       "Low Floor BRT",        "40", 3701, 3757 )
};

#define VEHICLES ((sizeof(vehicleTypes)/sizeof(vehicleTypes[0])))

#pragma mark Vehicle Tree

/* This is probably too much! I constructed a binary tree balanced by the number of vehicles on each side being the same */

// #define VEHICLE_TREE


#ifdef VEHICLE_TREE
typedef struct vehicle_node {
    struct vehicle_node *left;
    struct vehicle_node *right;
    PC_VEHICLE_INFO info;
} VEHICLE_NODE;

typedef const VEHICLE_NODE C_VEHICLE_NODE;
typedef C_VEHICLE_NODE *PC_VEHICLE_NODE;

PC_VEHICLE_INFO middle(PC_VEHICLE_INFO lower, PC_VEHICLE_INFO upper)
{
    PC_VEHICLE_INFO i;
    NSInteger total = 0;
    
    for (i=lower; i<=upper; i++)
    {
        total+= i->max - i->min + 1;
    }
    
    DEBUG_LOGLU(total);
    
    NSInteger middle = total / 2;
    total = 0;
    
    for (i=lower; i<=upper; i++)
    {
        total+= i->max - i->min + 1;
        if (total >= middle)
        {
            break;
        }
    }
    
    if (i>upper)
    {
        i=upper;
    }
    
    return i;
}

VEHICLE_NODE *makeTree(VEHICLE_NODE **next, PC_VEHICLE_INFO lower, PC_VEHICLE_INFO upper)
{
    VEHICLE_NODE *root = *next;
    (*next)++;
    
    if (lower == upper)
    {
        root->info  = upper;
        root->left  = nil;
        root->right = nil;
    }
    else
    {
        PC_VEHICLE_INFO mid = middle(lower, upper);
        root->info = mid;
        if (mid != lower && mid != upper)
        {
            root->left  = makeTree(next, lower, mid-1);
            root->right = makeTree(next, mid+1, upper);
        }
        else if (mid == lower)
        {
            root->left = nil;
            root->right = makeTree(next, mid+1, upper);
        }
        else if (mid == upper)
        {
            root->left = makeTree(next, lower, mid-1);
            root->right = nil;
        }
    }
    
    return root;
}

PC_VEHICLE_NODE searchTree(PC_VEHICLE_NODE tree, NSInteger vehicleId)
{
    while (tree!=nil)
    {
        DEBUG_LOG(@"%d tree %d-%d", (int)vehicleId, (int)tree->info->min, (int)tree->info->max);
        if (vehicleId < tree->info->min)
        {
            tree = tree->left;
        }
        else if (vehicleId > tree->info->max)
        {
            tree = tree->right;
        }
        else
        {
            break;
        }
    }
    
    return tree;
}

#if 0

void dumpTree(VEHICLE_NODE *tree, char *dir, int indent)
{
    if (tree!=nil)
    {
        char *pad = "########################################";
        DEBUG_LOG(@"IDs: %s %s %d %d\n", pad+(strlen(pad)-indent), dir, (int)tree->info->min,(int)tree->info->max);
        dumpTree(tree->left,  "L", indent+1);
        dumpTree(tree->right, "R", indent+1);
    }
}

#endif

#define MAKE_VEHICLE_NODE(N, L, R) { L==0 ? 0 : tree+L, R==0 ? 0 : tree+R, vehicleTypes+N  },

+ (PC_VEHICLE_INFO)vehicleInfo:(NSInteger)vehicleId
{
#if 1
    static VEHICLE_NODE tree[]=
    {
        MAKE_VEHICLE_NODE(18, 1,19) /*  0 */
        MAKE_VEHICLE_NODE(13, 2,15) /*  1 */
        MAKE_VEHICLE_NODE( 5, 3, 8) /*  2 */
        MAKE_VEHICLE_NODE( 4, 4, 0) /*  3 */
        MAKE_VEHICLE_NODE( 1, 5, 6) /*  4 */
        MAKE_VEHICLE_NODE( 0, 0, 0) /*  5 */
        MAKE_VEHICLE_NODE( 3, 7, 0) /*  6 */
        MAKE_VEHICLE_NODE( 2, 0, 0) /*  7 */
        MAKE_VEHICLE_NODE( 7, 9,10) /*  8 */
        MAKE_VEHICLE_NODE( 6, 0, 0) /*  9 */
        MAKE_VEHICLE_NODE( 8, 0,11) /* 10 */
        MAKE_VEHICLE_NODE( 9, 0,12) /* 11 */
        MAKE_VEHICLE_NODE(10, 0,13) /* 12 */
        MAKE_VEHICLE_NODE(11, 0,14) /* 13 */
        MAKE_VEHICLE_NODE(12, 0, 0) /* 14 */
        MAKE_VEHICLE_NODE(15,16,17) /* 15 */
        MAKE_VEHICLE_NODE(14, 0, 0) /* 16 */
        MAKE_VEHICLE_NODE(17,18, 0) /* 17 */
        MAKE_VEHICLE_NODE(16, 0, 0) /* 18 */
        MAKE_VEHICLE_NODE(25,20,26) /* 19 */
        MAKE_VEHICLE_NODE(22,21,24) /* 20 */
        MAKE_VEHICLE_NODE(19, 0,22) /* 21 */
        MAKE_VEHICLE_NODE(20, 0,23) /* 22 */
        MAKE_VEHICLE_NODE(21, 0, 0) /* 23 */
        MAKE_VEHICLE_NODE(23, 0,25) /* 24 */
        MAKE_VEHICLE_NODE(24, 0, 0) /* 25 */
        MAKE_VEHICLE_NODE(28,27,29) /* 26 */
        MAKE_VEHICLE_NODE(27,28, 0) /* 27 */
        MAKE_VEHICLE_NODE(26, 0, 0) /* 28 */
        MAKE_VEHICLE_NODE(29, 0, 0) /* 29 */
    };
    
#else
    static VEHICLE_NODE *tree;

    /* This code will construct the static binary tree above */
    if (tree == nil)
    {
        VEHICLE_NODE *nodes = malloc (sizeof(VEHICLE_NODE) * VEHICLES);
        tree = makeTree(&nodes, vehicleTypes, vehicleTypes+VEHICLES-1);
        dumpTree(tree," ", 0);
        
        NSMutableString *output = [NSMutableString stringWithFormat:@"\n\n"];
        int i=0;
        for (nodes = tree,i=0; i<VEHICLES; i++, nodes++)
        {
            [output appendFormat:@"MAKE_VEHICLE_NODE(%2ld,%2ld,%2ld) /* %2ld */\n",
                    (long)(nodes->info - vehicleTypes),
                    (long)(nodes->left  ? (nodes->left -tree)  : 0),
                    (long)(nodes->right ? (nodes->right-tree)  : 0),
                    i];
        }
        
        DEBUG_LOG_RAW(@"%@", output);
    }
#endif
    
    PC_VEHICLE_NODE result = searchTree(tree, vehicleId);
    
    if (result!=nil)
    {
        return result->info;
    }
    
    return nil;
}

#else

int compareVehicle(const void *first, const void *second)
{
    NSInteger key = ((PC_VEHICLE_INFO)first)->min;
    PC_VEHICLE_INFO range = (VEHICLE_INFO*)second;
    
    // The documentation of bsearch says the first argument was
    // always the key i.e. the single item
    DEBUG_LOGL(key);
    DEBUG_LOGL(range->min);
    DEBUG_LOGL(range->max);
    
    if (key < range->min)
    {
        return -1;
    }
    else if (key > range->max)
    {
        return 1;
    }
    return 0;
}

+ (PC_VEHICLE_INFO)vehicleInfo:(NSInteger)vehicleId
{
    VEHICLE_INFO key = {vehicleId,NO_VEHICLE_ID,nil, nil, nil,nil};
    return bsearch(&key, vehicleTypes, VEHICLES, sizeof(VEHICLE_INFO), compareVehicle);
}


+ (NSString *)vehicleString:(NSString *)vehicleId;
{
    NSString *string;
    const VEHICLE_INFO *vehicle = [TriMetInfo vehicleInfo:vehicleId.integerValue];
    
    if (vehicle == nil)
    {
        if (vehicleId!=nil)
        {
            string = [NSString stringWithFormat:@"Vehicle ID #b%@#b\n#b#RNo vehicle info.#b", vehicleId];
        }
        else
        {
           string = @"#b#RNo vehicle info.#b";
        }
        
    }
    else
    {
        string =  [NSString stringWithFormat:@"Vehicle ID #b%@#b - #b%@#b\nMade by #b%@#b.%@\nIntroduced #b%@#b",
                                          vehicleId,
                                          vehicle->type,
                                          vehicle->manufacturer,
                                          vehicle->model.length!=0 ? [NSString stringWithFormat:@" Model #b%@#b", vehicle->model] : @"",
                                          vehicle->first_used];
    }
    
    return string;
    
}

#endif

+ (NSString*)vehicleIdFromStreetcarId:(NSString*)streetcarId
{
    if (streetcarId && streetcarId.length > 1)
    {
        // Streetcar ID is of the form S024 - we drop the S
        return [streetcarId substringFromIndex:1];
    }
    return nil;
}

#pragma mark Routes and Lines and Colors

int compareRoute(const void *first, const void *second)
{
    return (int)(((ROUTE_INFO*)first)->route_number - ((ROUTE_INFO*)second)->route_number);
}

int compareLine(const void *first, const void *second)
{
    return (int)((int)((ROUTE_INFO*)first)->line_bit - (int)((ROUTE_INFO*)second)->line_bit);
}

#define ROUTES ((sizeof(allRailLines)/sizeof(allRailLines[0]))-1)

+ (PC_ROUTE_INFO)infoForLine:(RAILLINES)line
{
    ROUTE_INFO key = {0,line,0,0,0,0, nil, nil, nil, NO};
    return bsearch(&key, allRailLines, ROUTES, sizeof(ROUTE_INFO), compareLine);
}

+ (PC_ROUTE_INFO)infoForRouteNum:(NSInteger)route
{
    ROUTE_INFO key = {route,0,0,0,0,0, nil, nil, nil, NO};
    return bsearch(&key, allRailLines, ROUTES, sizeof(ROUTE_INFO), compareRoute);
}

+ (PC_ROUTE_INFO)infoForRoute:(NSString *)route
{
    return [TriMetInfo infoForRouteNum:route.integerValue];
}

+ (UIColor*)cachedColor:(NSInteger)col
{
    static NSMutableDictionary<NSNumber*, UIColor*> *colorCache;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorCache = [NSMutableDictionary dictionary];
        
        for (PC_ROUTE_INFO col= allRailLines; col->route_number!=kNoRoute; col++)
        {
            [colorCache setObject:HTML_COLOR(col->html_color)     forKey:@(col->html_color)];
            [colorCache setObject:HTML_COLOR(col->html_bg_color) forKey:@(col->html_bg_color)];
        }
    });
    
    return colorCache[@(col)];
}

+ (UIColor*)colorForRoute:(NSString *)route
{
    PC_ROUTE_INFO routeInfo = [TriMetInfo infoForRoute:route];
    
    if (routeInfo == nil)
    {
        return nil;
    }
    return [TriMetInfo cachedColor:routeInfo->html_color];
}

+ (UIColor*)colorForLine:(RAILLINES)line
{
    PC_ROUTE_INFO routeInfo = [TriMetInfo infoForLine:line];
    
    if (routeInfo == nil)
    {
        return nil;
    }
    return [TriMetInfo cachedColor:routeInfo->html_color];
}

+ (NSSet<NSString*> *)streetcarRoutes
{
    static NSMutableSet<NSString*> *routeIds =  nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        routeIds = [NSMutableSet set];
        
        for (PC_ROUTE_INFO info = allRailLines; info->route_number!=kNoRoute; info++)
        {
            if (info->streetcar)
            {
                [routeIds addObject:[TriMetInfo routeString:info]];
            }
        }
        
    });
    
    return routeIds;
}

+ (NSSet<NSString*> *)triMetRailLines
{
    static NSMutableSet<NSString*> *routeIds = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        routeIds = [NSMutableSet set];
    
        for (PC_ROUTE_INFO routeInfo = allRailLines; routeInfo->route_number!=kNoRoute; routeInfo++)
        {
            if (!routeInfo->streetcar)
            {
                [routeIds addObject:[TriMetInfo routeString:routeInfo]];
            }
        }
    });
    
    return routeIds;
}

+ (NSString*)routeString:(const ROUTE_INFO*)info
{
    return [NSString stringWithFormat:@"%ld",(long)info->route_number];
}

+ (NSString*)interlinedRouteString:(const ROUTE_INFO*)info
{
    return [NSString stringWithFormat:@"%ld",(long)info->interlined_route];
}

+ (const ROUTE_INFO*)allColoredLines
{
    return allRailLines;
}

@end
