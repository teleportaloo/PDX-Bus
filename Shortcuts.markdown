# Some features require PDX Bus 11.3.2 - still in development
# Some links are being updated and may not work yet.

PDX Bus is scriptable with using ShortCuts and URL schemes, using the shortcuts app or other apps that can access URL schemes.

# Introduction
[The Apple shortcuts app](https://support.apple.com/en-us/HT208309) allows users to write scrips on their devices. PDX Bus is scriptable.  Here are some examples of what is availabe.  Be nice.

# PDXBus URL Stops 
Opens PDXBus and displays arrivals for the listed stops.

Example:  <pdxbus:://355,366>

[An example shortcut link](https://www.icloud.com/shortcuts/2a56477b997e484b87d4644316cd31e8) 


# PDXBus URL Nearby 
Opens PDXBus and locates nearby stops of a certain type within a certain distance.

Example: <pdxbus://nearby&show=maps&distance=0.5&mode=both>

[An example shortcut link](https://www.icloud.com/shortcuts/18b1a2994c8f46eaa2769a8685f3e3a5)

## Arguments for Nearby command:

### mode
* bus
* busses
* buses
* train
* trains
* both
* busandtrain

### distance
* closest
* 0.5
* 1
* 3

### show
* arrivals"
* map
* routes


# PDXBus URL Map 
Opens PDXBus and shows a map with all routes and vehicles.

Example: <pdxbus://map>

[An example shortcut link](https://www.icloud.com/shortcuts/ece0a620361b41e19f63563752b4a229)

# PDXBus URL Bookmark Name
Opens PDXBus and opens a bookmark based on the name.

Example: <pdxbus://bookmark=4T%20Trail>

[An example shortcut link](https://www.icloud.com/shortcuts/8d975f7476c348aca2fa9b4f446e8189)

# PDXBus URL Bookmark Number
Opens PDXBus and opens a bookmark based on the number, starting with 0.

Example: <pdxbus://bookmarknumber=0>

[An example shortcut link](https://www.icloud.com/shortcuts/5f2a6ea26b3c4ed69df37ef5a9b017fa)


# PDXBus URL Commute
Opens PDXBus and shows the commuter bookmark.

Example: <pdxbus://commute>

[An example shortcut link](https://www.icloud.com/shortcuts/603d52d0f69e4e7a96436f85a3abbb80)

# PDXBus URL QR Code
Opens PDXBus and shows QR reader.

Example: <pdxbus://qrcode>

[An example shortcut link](https://www.icloud.com/shortcuts/90488a82a2dc4ba39a0f4ff7a19140c7)

# PDXBus URL Trip Planner
Opens PDXBus and launches trip planner.

Example: <pdxbus://trippplanner>

[An example shortcut link](https://www.icloud.com/shortcuts/6ea5920fbae342548f1e310b3d511a4f)


# PDXBus URL Trip Planner with arguments

Example: <pdxbusroute://?to_lat=45.5149925&to_lon=-122.6785488&from_here>

[An example shortcut link](https://www.icloud.com/shortcuts/b48a1063245d4f9aaea67b6aac0c7fc7)

## Arguments
* from_lat
* from_lon
* to_here
* from_here
* from_name
* to_name


# Shortcuts - Get nearest TriMet Stops
This is an action accessible from the Shortcuts app, and can be used to write a Siri shortcut.  The shortcut itself cam get the location from
a contact or the current location.

Arguments:  Location

[An exmple shortcut link](https://www.icloud.com/shortcuts/58eeb246627246c49fe605fea0fbec05)

# Shortcuts - Get location of a TriMet Stop ID
This is an action accessible from the Shortcuts app, and can be used to write a Siri shortcut.   The shortcut returns a location object for a 
specific stop ID.  This can then be passed along to another action.

Arguments:  Stop IDs

[An exmple shortcut link](https://www.icloud.com/shortcuts/6b3982506afc48f680d3570153e15e93) 

# Shortcuts - Get TriMet Alerts for a route
This is an action accessible from the Shortcuts app, and can be used to write a Siri shortcut.   This shortcut returns the alerts for a specific
route.  THe route can be a bus number or a MAX color or streetcar line name.

[An example shortcut link](https://www.icloud.com/shortcuts/9b6a6f72a0fc431e8a3d2d5dd7d21696)

Arguments:  Route

# Shortcuts - Get TriMet departures for a Stop ID
This is an action accessible from the Shortcuts app, and can be used to write a Siri shortcut.  This shortcut returns the departures for a stop
orderd by time.

[An example shortcut link](https://www.icloud.com/shortcuts/cb8c5831601a4c1988d8c333b924c4d4)

Arguments:  Stop ID


# Shortcuts - Get TriMet routes and departures for a Stop ID
This is an action accessible from the Shortcuts app, and can be used to write a Siri shortcut.  This shortcut returns the departures for a stop
orderd by route.

Arguments: Stop ID

[An exmple shortcut link](https://www.icloud.com/shortcuts/58eeb246627246c49fe605fea0fbec05)

