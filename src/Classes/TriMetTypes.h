//
//  TriMetTypes.h
//  PDX Bus
//

/*

``The contents of this file are subject to the Mozilla Public License
     Version 1.1 (the "License"); you may not use this file except in
     compliance with the License. You may obtain a copy of the License at
     http://www.mozilla.org/MPL/

     Software distributed under the License is distributed on an "AS IS"
     basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
     License for the specific language governing rights and limitations
     under the License.

     The Original Code is PDXBus.

     The Initial Developer of the Original Code is Andrew Wallace.
     Copyright (c) 2008-2011 Andrew Wallace.  All Rights Reserved.''

 */


typedef long long TriMetTime;
typedef long long TriMetDistance;

#define TriMetToUnixTime(X) ((X)/1000)

typedef enum {
	TripModeBusOnly,
    TripModeTrainOnly,
    TripModeAll,
	TripModeNone
} TripMode;


//
// This is a constant NS string containing the app ID from 
// http://developer.trimet.org/registration/
// 

#error Get an APP ID from TriMet then copy it into the string below and delete this line!

#define TRIMET_APP_ID @""
