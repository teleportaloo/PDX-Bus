# Some features require PDX Bus 11.3.2 - still in development
# Some links are being updated and may not work yet.


# Introduction

PDX Bus is scriptable using either Shortcuts and URL schemes.  The shortcuts app or other apps can also access URL schemes.

[The Apple shortcuts app](https://support.apple.com/en-us/HT208309) allows users to write scrips on their devices. Here are some examples of what is available.  Be nice.

Note:  to load any shortcuts you need to change the "Allow Untrusted Shortcuts" setting for the Shortcuts app.  I suggest turning that back off again when you are done.

# PDX Bus URL to Launch And Show Arrivals For Stops 
Launches PDXBus and displays arrivals for the listed stops.

Example:  <pdxbus:://355,366>

[An example shortcut link](https://www.icloud.com/shortcuts/4e7aa0543d9a4a52a200f4bd933d875e) 

# PDX Bus URL To Launch And Show Nearby Stops 
Opens PDXBus and locates nearby stops of a certain type within a certain distance.

Example: <pdxbus://nearby&show=maps&distance=0.5&mode=both>


[An example shortcut link](https://www.icloud.com/shortcuts/ec23d7f7e21849ad8d34313b2940f623)

## Arguments for Nearby command:

### mode=
* bus
* busses
* buses
* train
* trains
* both
* busandtrain

### distance=
* closest
* 0.5
* 1
* 3

### show=
* departures
* map
* routes


# PDX Bus URL To Launch and Show Map 
Opens PDXBus and shows a map with all routes and vehicles.

Example: <pdxbus://map>

[An example shortcut link](https://www.icloud.com/shortcuts/984c2d2f096a4bbc87681b2698cc86b4)

# PDX Bus URL To Launch and Show Bookmark
Opens PDXBus and opens a bookmark based on the name.

Example: <pdxbus://bookmark=4T%20Trail>

[An example shortcut link](https://www.icloud.com/shortcuts/d051eda5ebaf464990465589f219f4b5)

# PDX Bus URL To Launch and Show Bookmark By Number
Opens PDXBus and opens a bookmark based on the number, starting with 0.

Example: <pdxbus://bookmarknumber=0>

[An example shortcut link](https://www.icloud.com/shortcuts/ba09895d463c412f8214a771e23085d5)


# PDX Bus URL To Launch and Show Commuter Bookmark
Opens PDXBus and shows the commuter bookmark based on the current time.

Example: <pdxbus://commute>

[An example shortcut link](https://www.icloud.com/shortcuts/8bd75e96a5ec49b2939fcbd245ab4c79)

# PDX Bus URL To Launch and QR Code Reader
Opens PDXBus and displays the QR code reader.

Example: <pdxbus://qrcode>

[An example shortcut link](https://www.icloud.com/shortcuts/a9701d50b0874626a56dcd97cf025343)

# PDX Bus URL To Launch And Show Trip Planner
Opens PDXBus and launches trip planner.

Example: <pdxbus://trippplanner>

[An example shortcut link](https://www.icloud.com/shortcuts/f93c6e0ec066461383789480b62634c1)


# PDX Bus URL To Launch and Plan A Trip

Opens PDX Bus and plans a trip based on the arguments.   This was originally implemented to integrate with the BlindSquare application.

Note:  the "?" is a required part of the syntax.

Example: <pdxbusroute://?to_lat=45.5149925&to_lon=-122.6785488&from_here>

[An example shortcut link](https://www.icloud.com/shortcuts/981f6f65cd6e4479a448085036d7e44d)

## Supported Arguments
* from_lat=<number>
* from_lon=<number>
* to_lat=<number>
* to_lon=<number>
* to_here
* from_here
* from_name
* to_name


# PDX Bus Siri Shortcut To Get Nearest TriMet Stops
This is an action accessible from the Shortcuts app, and can be used to write a Siri shortcut.  The shortcut itself cam get the location from
a contact or the current location.

Arguments:  Location

The following shortcut uses this action, then also get and say the arrivals at the nearest stop.

[An example shortcut link](https://www.icloud.com/shortcuts/2c3d380624254d33af1d1418c1752446)

# PDX Bus Siri Shortcut To Locate A Stop ID
This is an action accessible from the Shortcuts app, and can be used to write a Siri shortcut.   The shortcut returns a location object for a 
specific stop ID.  This can then be passed along to another action.

Arguments:  Stop IDs

The following shortcut uses this action, then shows a map centered on the location.

[An example shortcut link](https://www.icloud.com/shortcuts/1a5500eb6273424084b56d09cb4dc540) 

# PDX Bus Siri Shortcut To Get TriMet Departures (Ordered By Time) For A Stop ID
This is an action accessible from the Shortcuts app, and can be used to write a Siri shortcut.  This shortcut returns the departures for a stop
ordered by time.

[An example shortcut link](https://www.icloud.com/shortcuts/67790699dd2946e0accc8bb88bac12a9)

Arguments:  Stop ID


# PDX Bus Siri Shortcut To Get Alerts For A Route
This is an action accessible from the Shortcuts app, and can be used to write a Siri shortcut.   This shortcut returns the alerts for a specific
route.  The route can be a bus number or a MAX color or streetcar line name.



[An example shortcut link](https://www.icloud.com/shortcuts/590e607c7b6845368ab10dcd25da4682)

Arguments:  Route

# PDX Bus Siri Shortcut To Get TriMet Departures (Ordered By Route) For A Stop ID
This is an action accessible from the Shortcuts app, and can be used to write a Siri shortcut.  This shortcut returns the departures for a stop
ordered by route.

Arguments: Stop ID

[An example shortcut link](https://www.icloud.com/shortcuts/2c3d380624254d33af1d1418c1752446)

