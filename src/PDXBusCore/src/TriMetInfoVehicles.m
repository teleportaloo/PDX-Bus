//
//  TriMetInfoVehicles.c
//  PDX Bus
//
//  Created by Andrew Wallace on 4/18/21.
//  Copyright © 2021 Andrew Wallace. All rights reserved.
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


#include "TriMetInfoVehicles.h"
#include "DebugLogging.h"

#define DEBUG_LEVEL_FOR_FILE kLogDataManagement

#define BUS_FLEET(YEAR, MANU, MODEL, LENGTH, MIN, MAX)              { MIN,         MAX,         TriMetTypeBus,              @MANU, @MODEL, @YEAR, NO,   nil,    YES}
#define BUS_INFO1(YEAR, MANU, MODEL, LENGTH, NUM, INFO)             { NUM,         NUM,         TriMetTypeBus,              @MANU, @MODEL, @YEAR, NO,   INFO,   YES}
#define MAX_FLEET(TYPE, MIN, MAX, MANU, MODEL, YEAR)                { MIN,         MAX,         TriMetTypeMAX @" " TYPE,    @MANU, @MODEL, @YEAR, YES,  nil,    YES}
#define WES_FLEET(MIN, MAX, MANU, MODEL, YEAR)                      { MIN,         MAX,         TriMetTypeWES,              @MANU, @MODEL, @YEAR, YES,  nil,    NO}
#define STREETCAR_FLEET(MANU, MODEL, N, YEAR, MIN, MAX )            { 1##MIN-1000, 1##MAX-1000, TriMetTypeStreetcar,        @MANU, @MODEL, @YEAR, NO,   nil,    NO}
#define STREETCAR_WINFO(MANU, MODEL, N, YEAR, MIN, MAX, INFO)       { 1##MIN-1000, 1##MAX-1000, TriMetTypeStreetcar,        @MANU, @MODEL, @YEAR, NO,   INFO,   NO}

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
static const VehicleInfo vehicleInfo[] =
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
    BUS_FLEET("2013",       "Gillig",       kLFBRT,        "40", 3101, 3169 ),
    BUS_INFO1("2015",       "Gillig",       kLFBRT,        "40", 3170, @" 🎉 Celebrating #Lhttps://trimet.org/celebrate/nativeleaders.htm Native American Heritage and Leaders#T"),
    BUS_FLEET("2014",       "Gillig",       kLFBRT,        "40", 3201, 3260 ),
    BUS_FLEET("2015",       "Gillig",       kLFBRT,        "40", 3261, 3268 ),
    BUS_FLEET("2014",       "Gillig",       kLFBRT,        "40", 3301, 3330 ),
    BUS_FLEET("2015",       "Gillig",       kLFBRT,        "29", 3401, 3422 ),
    BUS_FLEET("2015",       "Gillig",       kLFBRT,        "40", 3501, 3514 ),
    BUS_INFO1("2015",       "Gillig",       kLFBRT,        "40", 3515, @" 🎉 Celebrating #Lhttps://trimet.org/celebrate/blackleaders.htm Black History and Leaders#T"),
    BUS_FLEET("2015",       "Gillig",       kLFBRT,        "40", 3516, 3535 ),
    BUS_INFO1("2015",       "Gillig",       kLFBRT,        "40", 3536, @" 🎉 Celebrating #Lhttps://trimet.org/celebrate/lgbtqleaders.htm LGBTQ+ History and Leaders#T"),
    BUS_FLEET("2015",       "Gillig",       kLFBRT,        "40", 3537, 3556 ),
    BUS_INFO1("2015",       "Gillig",       kLFBRT,        "40", 3557, @" 🎉 Celebrating #Lhttps://trimet.org/celebrate/aapileaders.htm Asian American and Pacific Islander History and Leaders#T"),
    BUS_FLEET("2015",       "Gillig",       kLFBRT,        "40", 3558, 3577 ),
    BUS_FLEET("2016",       "Gillig",       kLFBRT,        "40", 3601, 3650 ),
    BUS_FLEET("2017",       "Gillig",       kLFBRT,        "40", 3701, 3744 ),
    BUS_INFO1("2017",       "Gillig",       kLFBRT,        "40", 3745, @"🏳️‍🌈 #ball are welcome#b 🏳️‍🌈"),
    BUS_FLEET("2017",       "Gillig",       kLFBRT,        "40", 3746, 3757 ),
    BUS_FLEET("2018–19",    "New Flyer",    kXC,           "40", 3801, 3805 ),
    BUS_FLEET("2018-19",    "Gillig",       kLFBRT,        "40", 3901, 3964 ),
    BUS_FLEET("2019–20",    "Gillig",       kLFBRT,        "40", 4001, 4071 ),
    BUS_FLEET("2020-2021",  "Gillig",       kLFBRT,        "40", 4201, 4239 ),
    { NSIntegerMax, NSIntegerMax, nil, nil, nil, nil, NO, nil, NO }
};

// uncrustify-on

PtrConstVehicleInfo getTriMetVehicleInfo()
{
    return &(vehicleInfo[0]);
}

size_t noOfTriMetVehicles()
{
    return ((sizeof(vehicleInfo) / sizeof(vehicleInfo[0])) - 1);
}

int compareVehicle(const void *first, const void *second) {
    NSInteger key = ((PtrConstVehicleInfo)first)->min;
    PtrConstVehicleInfo range = (VehicleInfo *)second;
    
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
