//
//  TriMetTypes.h
//  PDX Bus
//



/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */



typedef long long   TriMetTime;
typedef long long   TriMetDistance;

#define TriMetToUnixTime(X)    ((X) / 1000)
#define UnixToTriMetTime(X)    ((X) * 1000)
#define TriMetToNSDate(X)      [NSDate dateWithTimeIntervalSince1970:TriMetToUnixTime(X)]
#define MinsBetweenDates(T, Q) ([(T) timeIntervalSinceDate:(Q)] / 60)
#define SecsToMins(S)          ((NSInteger)(S) / 60)

#define kTriMetDisclaimerText NSLocalizedString(@"Route and departure data provided by permission of TriMet", @"Disclaimer")

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
