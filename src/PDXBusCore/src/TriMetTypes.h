//
//  TriMetTypes.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



typedef long long TriMetTime;
typedef long long TriMetDistance;

#define TriMetToUnixTime(X)     ((X)/1000)
#define UnixToTriMetTime(X)     ((X)*1000)
#define TriMetToNSDate(X)       [NSDate dateWithTimeIntervalSince1970:TriMetToUnixTime(X)]



typedef enum {
	TripModeBusOnly,
    TripModeTrainOnly,
    TripModeAll,
	TripModeNone
} TripMode;

typedef enum {
    TripMinQuickestTrip,
    TripMinFewestTransfers,
    TripMinShortestWalk
} TripMin;

//
// This is a constant NS string containing the app ID from 
// http://developer.trimet.org/registration/
// 

// #error Get an APP ID from TriMet then copy it into the string below and delete this line!

#define TRIMET_APP_ID @""
