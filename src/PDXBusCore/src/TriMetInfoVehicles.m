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

#define DEBUG_LEVEL_FOR_FILE LogData

#define BUS_FLEET(YEAR, MANU, MODEL, LENGTH, MIN, MAX, FUEL)                   \
    {                                                                          \
        MIN, MAX, TriMetTypeBus, @MANU, @MODEL, @YEAR, NO, FUEL, YES           \
    }

#define MAX_FLEET(TYPE, MIN, MAX, MANU, MODEL, YEAR)                           \
    {                                                                          \
        MIN, MAX, TriMetTypeMAX @" " TYPE, @MANU, @MODEL, @YEAR, YES, nil, YES \
    }
#define WES_FLEET(MIN, MAX, MANU, MODEL, YEAR)                                 \
    {                                                                          \
        MIN, MAX, TriMetTypeWES, @MANU, @MODEL, @YEAR, YES, nil, NO            \
    }
#define STREETCAR_FLEET(MANU, MODEL, N, YEAR, MIN, MAX)                        \
    {                                                                          \
        1##MIN - 1000, 1##MAX - 1000, TriMetTypeStreetcar, @MANU, @MODEL,      \
            @YEAR, NO, nil, NO                                                 \
    }

#define STREETCAR_SPECIAL(NUM, INFO) {1##NUM - 1000, INFO}

// Note - the weird macro for the streetcar numbers is because prefixing a
// number with 0 in C will make it octal, but the streetcar numbers are usually
// written with leading zeros, so we mangle them a bit by adding a leading 1 and
// then removing it.  So in the end they end up as decimal but I can use the
// leading zeros.

#define NO_VEHICLE_ID (-1)

// From Wikipedia - formatted like their tables to make it easy to check
// https://en.wikipedia.org/wiki/TriMet
// https://en.wikipedia.org/wiki/Portland_Streetcar

#define MORE_INFO "#b(more info)#b#T"
#define kBombardier                                                            \
    "Bombardier "                                                              \
    "#Lhttps://en.wikipedia.org/wiki/Bombardier_Transportation " MORE_INFO
#define kD40LF                                                                 \
    "D40LF #Lhttps://en.wikipedia.org/wiki/New_Flyer_Low_Floor " MORE_INFO
#define kD40LFR                                                                \
    "D40LFR #Lhttps://en.wikipedia.org/wiki/New_Flyer_Low_Floor " MORE_INFO
#define kLFBRT                                                                 \
    "Low Floor BRT "                                                           \
    "#Lhttps://en.wikipedia.org/wiki/Gillig_Low_Floor " MORE_INFO
#define kLFBRTH                                                                \
    "Low Floor BRT Hybrid "                                                    \
    "#Lhttps://en.wikipedia.org/wiki/Gillig_Low_Floor " MORE_INFO
#define kXC                                                                    \
    "Xcelsior CHARGE™ ⚡︎ "                                                     \
    "#Lhttps://en.wikipedia.org/wiki/New_Flyer_Xcelsior " MORE_INFO
#define kSD660 "SD660 #Lhttps://en.wikipedia.org/wiki/Siemens_SD660 " MORE_INFO
#define kS70                                                                   \
    "S70 #Lhttps://en.wikipedia.org/wiki/Siemens_S700_and_S70 " MORE_INFO
#define kS700                                                                  \
    "S700 #Lhttps://en.wikipedia.org/wiki/Siemens_S700_and_S70 " MORE_INFO
#define k10T "10 T #Lhttps://en.wikipedia.org/wiki/Skoda_10_T " MORE_INFO
#define kTrio12                                                                \
    "Trio type 12 #Lhttps://en.wikipedia.org/wiki/Inekon_12_Trio " MORE_INFO
#define kUnited                                                                \
    "United Streetcar "                                                        \
    "#Lhttps://en.wikipedia.org/wiki/United_Streetcar " MORE_INFO
#define kBrookville                                                            \
    "Brookville Equipment "                                                    \
    "#Lhttps://en.wikipedia.org/wiki/"                                         \
    "Brookville_Equipment_Corporation " MORE_INFO
#define kLFPlus                                                                \
    "Low Floor Plus "                                                          \
    "#Lhttps://en.wikipedia.org/wiki/Gillig_Low_Floor#Variants " MORE_INFO
#define kArtic                                                                 \
    "Nova LFS Artic  #Lhttps://en.wikipedia.org/wiki/Nova_Bus " MORE_INFO

#define FUEL_HYBRID @"Diesel-electric hybrid"
#define FUEL_BIODIESEL @"Biodiesel"
#define FUEL_ELECTRIC @"Battery electric"

// clang-format off
// NOTE - this table is searched so must be in order of ID - the wikipedia article is not in order
static const TriMetInfo_Vehicle vehicleInfo[] =
{
    // https://en.wikipedia.org/wiki/Portland_Streetcar
    // The numbers are not octal - they get mangled by the macro to be decimal.
    // Checked 9/5/22
    STREETCAR_FLEET("Škoda",            k10T,                   7,    "2001–02",        001,007),
    STREETCAR_FLEET("Inekon Trams",     kTrio12,                3,    "2006",           008,010),
    STREETCAR_FLEET(kUnited,            "10T3 (prototype)",     1,    "2009",           015,015),
    STREETCAR_FLEET(kUnited,            "100",                  2,    "2012–14",        021,026),
    STREETCAR_FLEET(kBrookville,        "Liberty",              3,    "2023",           031,033),
    
    // https://en.wikipedia.org/wiki/TriMet_rolling_stock
    // Checked 9/5/22
    MAX_FLEET("Type 1",     101,126,     kBombardier,      "",        "1986" ),  //   76/166     26
    MAX_FLEET("Type 2",     201,252,     "Siemens",        kSD660,    "1997" ),  //   64/166     52
    MAX_FLEET("Type 3",     301,327,     "Siemens",        kSD660,    "2003" ),  //   64/166     27
    MAX_FLEET("Type 4",     401,422,     "Siemens",        kS70,      "2009" ),  //   68/172     22
    MAX_FLEET("Type 5",     521,538,     "Siemens",        kS700,     "2015" ),  //   72/186     18
    MAX_FLEET("Type 6",     601,630,     "Siemens",        kS700,     "2025" ),  //   62/168     30
    
    // https://en.wikipedia.org/wiki/WES_Commuter_Rail#Rolling_stock
    // Checked 9/5/22
    WES_FLEET(1001,1003, "Colorado Railcar",      "Aero", "2009 (made in 2008)"),   //      2009     Diesel multiple units (DMUs)
    WES_FLEET(1702,1702, "Budd",                  "RDC",  "2011 (made in 1953)"),   //      2011     Ex-Alaska Railroad 702; originally New Haven 129[36]
    WES_FLEET(1711,1711, "Budd",                  "RDC",  "2011 (made in 1952)"),   //      2011     Ex-Alaska Railroad 711; originally New Haven 121[36]
    WES_FLEET(2001,2001, "Colorado Railcar",      "Aero", "2009 (made in 2008)"),   //      2009     Unpowered control car
    WES_FLEET(2007,2007, "Budd",                  "RDC",   "1957"),                 //      1957     Ex-Trinity Railway Express (Dallas) 2007; ex-Via Rail
    WES_FLEET(2011,2011, "Budd",                  "RDC",   "1957"),                 //      1957     Ex-Trinity Railway Express (Dallas) 2011;[40] ex-Via Rail
    
    // https://en.wikipedia.org/wiki/TriMet
    // Checked 7/21/25
    BUS_FLEET("2012",       "Gillig",       kLFBRT,        "40", 3001, 3051, FUEL_BIODIESEL), // Checked 7/21/25
    BUS_FLEET("2012",       "Gillig",       kLFBRTH,       "40", 3052, 3055, FUEL_HYBRID   ), // Checked 7/21/25
    BUS_FLEET("2015",       "Gillig",       kLFBRTH,       "40", 3056, 3059, FUEL_HYBRID   ), // Checked 7/21/25

    BUS_FLEET("2013",       "Gillig",       kLFBRT,        "40", 3101, 3170, FUEL_BIODIESEL ), // Checked 7/21/25
     
    BUS_FLEET("2014",       "Gillig",       kLFBRT,        "40", 3201, 3260, FUEL_BIODIESEL ), // Checked 7/21/25
    BUS_FLEET("2015",       "Gillig",       kLFBRT,        "40", 3261, 3268, FUEL_BIODIESEL ), // Checked 7/21/25
    BUS_FLEET("2014",       "Gillig",       kLFBRT,        "40", 3301, 3330, FUEL_BIODIESEL ), // Checked 7/21/25
    BUS_FLEET("2015",       "Gillig",       kLFBRT,        "29", 3401, 3422, FUEL_BIODIESEL ), // Checked 7/21/25
    
    BUS_FLEET("2015",       "Gillig",       kLFBRT,        "40", 3501, 3577, FUEL_BIODIESEL ), // Checked 7/21/25
        
    BUS_FLEET("2016",       "Gillig",       kLFBRT,        "40", 3601, 3650, FUEL_BIODIESEL ), // Checked 7/21/25
     
    BUS_FLEET("2017",       "Gillig",       kLFBRT,        "40", 3701, 3757, FUEL_BIODIESEL ), // Checked 7/21/25
      
    BUS_FLEET("2018",       "New Flyer",    kXC,           "40", 3801, 3805, FUEL_ELECTRIC  ), // Checked 7/21/25
    BUS_FLEET("2018",       "Gillig",       kLFBRT,        "40", 3901, 3964, FUEL_BIODIESEL ), // Checked 7/21/25
    BUS_FLEET("2019",       "Gillig",       kLFBRT,        "40", 4001, 4071, FUEL_BIODIESEL ), // Checked 7/21/25
    
    BUS_FLEET("2020",       "Gillig",       kLFBRT,        "40", 4201, 4239, FUEL_BIODIESEL ), // Checked 7/21/25
      
    BUS_FLEET("2021",       "Gillig",       kLFPlus,       "40", 4301, 4305, FUEL_ELECTRIC ),  // Checked 7/21/25
    BUS_FLEET("2024",       "Gillig",       kLFPlus,       "40", 4401, 4424, FUEL_ELECTRIC ),  // Checked 7/21/25
    
    BUS_FLEET("2022",       "Nova Bus",     kArtic,        "62", 4501, 4531, FUEL_BIODIESEL ), // Checked 7/21/25
    
    { NSIntegerMax, NSIntegerMax, nil, nil, nil, nil, NO, nil, NO }
};

static const TriMetInfo_VehicleSpecial vehicleInfo_Special[] =
{
    STREETCAR_SPECIAL(023, @"🏳️‍🌈 Progress Pride Car"),
    { 3111, @"🏳️‍🌈 All Are Welcome"},
    { 3126, @" 🎉 Celebrating Hispanic Heritage and Leaders" },
    { 3170, @" 🎉 Celebrating Native American Heritage and Leaders" },
    { 3515, @" 🎉 Celebrating Black History and Leaders" },
    { 3536, @" 🏳️‍🌈🏳️‍⚧️ Celebrating LGBTQ+ History and Leaders" },
    { 3557, @" 🎉 Celebrating Asian American and Pacific Islander History and Leaders" },
    { 3745, @"🏳️‍🌈 #ball are welcome#b 🏳️‍🌈"},
    { 4234, @" 🎉 Celebrating Women's History Month"},
    { 0, nil }
};

// clang-format on

// uncrustify-on

TriMetInfo_VehicleConstPtr TriMetInfo_getVehicle(void) {
    return &(vehicleInfo[0]);
}

TriMetInfo_VehicleSpecialConstPtr TriMetInfo_getVehicleSpecial(void) {
    return &(vehicleInfo_Special[0]);
}

size_t TriMetInfo_noOfVehicles(void) {
    return ((sizeof(vehicleInfo) / sizeof(vehicleInfo[0])) - 1);
}

int TriMetInfo_compareVehicle(const void *first, const void *second) {
    NSInteger key = ((TriMetInfo_VehicleConstPtr)first)->vehicleIdMin;
    TriMetInfo_VehicleConstPtr range = (TriMetInfo_Vehicle *)second;

    // The documentation of bsearch says the first argument was
    // always the key i.e. the single item
    DEBUG_LOG_long(key);
    DEBUG_LOG_long(range->vehicleIdMin);
    DEBUG_LOG_long(range->vehicleIdMax);

    if (key < range->vehicleIdMin) {
        return -1;
    } else if (key > range->vehicleIdMax) {
        return 1;
    }

    return 0;
}

int TriMetInfo_compareVehicleSpecial(const void *first, const void *second) {
    return (int)(((TriMetInfo_VehicleSpecialConstPtr)first)->vehicleId -
                 ((TriMetInfo_VehicleSpecialConstPtr)second)->vehicleId);
}

size_t TriMetInfo_noOfVehicleSpecials(void) {
    return ((sizeof(vehicleInfo_Special) / sizeof(vehicleInfo_Special[0])) - 1);
}
