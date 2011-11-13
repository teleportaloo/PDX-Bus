PDX Bus is an award winning application that displays arrival times for public transport in Portland, Oregon.

(PDX Bus won Best in Show at the [CivicApps.org](http://www.CivicApps.org) awards)

This little application uses the Internet to quickly access TriMet's live tracking data to display arrival times perfectly formatted for the iPhone. It allows you to bookmark frequently used stops, displays recently accessed stops, and gives details for arrivals which are en-route.

You can enter the stop "id" of the stop (as displayed at each stop or station) or you can browse the routes for the stop.

Feature includes:

* Interactive rail map, showing the MAX and WES stops.
* Embedded Google maps, showing locations of stops, and when available, the last known position of the bus or train.
* Use GPS to locate nearby stops or rail stations.
* Browse routes and stops, show an entire route on the map.
* Links to TriMet route information.
* Displays Rider Alerts, and Detours.
* A "Nighttime visibility flasher" - a flashing screen that can be used at night so that drivers can see you. TriMet suggests holding up a cell phone to make yourself visible to bus drivers.
* Trip Planning - now you can use the same trip planning feature that is available on TriMet's web site.
* Specially formatted text to work with the iPhone 3GS VoiceOver accessibility feature to speak arrivals.

Route and arrival data provided by permission of TriMet.

PDX Bus 6.1.0 sources
=====================

I am making the sources to PDX Bus version 6.1 available as part of the 
[Civic Apps](http://www.civicapps.org) competition.  These
sources were developed by me from Apple samples and documentation, except 
where explicitly mentioned in the code.  

I am choosing to release a copy of the code under the 
[MPL 1.1](http://www.mozilla.org/MPL/) License but I retain the copyright,
which enables me to release the iPhone app under the regular Apple iPhone 
license (this avoids any conflict of licenses for the time being).
 (No outside MPL or GPL code has been incorporated into the
code, some BSD License has been included, it is clearly marked).  
However - this really is the exact same code that was used to build the app, and 
I will continue to release the code for all future releases (the method of 
release may change).

I regret that I probably do not have the time to answer general support 
questions about iPhone application development - all you need to know can be 
found at [http://developer.apple.com](http://developer.apple.com)
(You need a Mac to develop for the iPhone, you will also need to purchase a 
$100 membership to get a certificate to put an application on
an actual device).

Because I wish to retain the copyright on the code, I am currently not
yet collaborating on development - but this may change as I work out
how open source iPhone development can work.

Of course this code can be used as a reference 
and in other code, but be sure to comply with the license! This code was 
written initially as a fun learning project for me to learn Objective-C, and 
has grown from there.  There may be better, more efficient, cleaner, more 
elegent or more correct ways to do all of it, but this is what I came up with 
in my spare time, and it gets the job done.  I am working on tidying it up 
to enable it to be of more use.

Links
-----
* [PDX Bus Blog](http://pdxbus.teleportaloo.org)
* [PDX Bus in the iTunes store](http://phobos.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=289814055&mt=8")
* [PDX Bus on Twitter](http://twitter.com/pdxbus)

Things to know before building
------------------------------
* PDX Bus is built with iPhone SDK 5.0 and Xcode 4.2 - available free 
from [Apple](http://developer.apple.com) in their Mac App store.
* Before building this code you will need to register with TriMet 
to get a free "AppID" from [TriMet](http://developer.trimet.org/registration/),
this is so that TriMet can track who is using their API. The AppID is 
placed in TriMetTypes.h as the #define TRIMET_APP_ID.  Without this id 
the application will not work, the code will not compile until this is 
addressed.
* For licensing reasons, some graphics are not included with this source 
(see below).
* Other graphics are included under Creative Commons Licenses - please check the
folders for the particular licenses used.
* The data feed from [Next Bus](http://www.civicapps.org/datasets/portland-streetcar-routes-arrivals) 
has terms and conditions (including a non-commercial clause) but does 
not need an application ID.
* Yahoo Place Finder can be used to do Reverse Geo Coding on GPS coordinates.  
This also needs a free API key which is not included.  
You will need to register with Yahoo [here](http://developer.yahoo.com/geo/placefinder)
for this to be utilized - otherwise the code will fall back to GeoNames.org. 


Graphics
--------
This source distribution builds and runs, but the project will not attempt 
to copy any missing graphics files into the application package.  
If you download the graphics from the sources below, you must enable 
the project to copy them into the application. 

### TriMet Graphics
Two graphics files were provided to me by permission of TriMet, and should 
be placed in the TriMet folder and then assigned to the target in the Xcode 
project (see below).
PDX Bus will work without them, except the Rail Map will not be displayed.

* The visittrimeticon.gif file is available from the TriMet page about 
[linking](http://www.trimet.org/help/linking.htm)
* The map of the rail system, railsystem.gif, is a 2000x765 gif file made 
from the PDF of the rail map.  
(The size here is important for the positioning of the hotspots). The original 
file is available here -
[http://www.trimet.org/maps/railsystem.htm](http://www.trimet.org/maps/railsystem.htm) - I was granted special permission to use it for PDX Bus with a disclaimer - 
you will need to ask permission if you want to distribute it
in some way.  Note that I took the PDF and made the GIF file - the GIF 
file provided by TriMet is too small
and will not work.

### Enabling the project to use the graphics
Once the graphics have been downloaded and copied into place you will need to 
enable them in the project.

* In the Xcode project, under Resouces you will find the Aha-Soft, 
TriMet and Glyphish folders. The file names
will be red for any missing files.
* For files that are not red, select them all, CTRL-Click then 
choose "Get Info" from the pop-up menu.
* On the Info dialog box, click on the Targets tab, and select 
"PDX Bus".


### Attributions


* Aha-Soft - some graphics files from Aha-Soft are used under a 
[Creative Commons Attribution-Share Alike 3.0 License](http://creativecommons.org/licenses/by/3.0/us/). 
These files are in a separate folder with attributions:

    * Attribution:  [http://www.small-icons.com/packs/24x24-free-application-icons.htm](http://www.small-icons.com/packs/24x24-free-application-icons.htm).
    * Attribution:  [http://www.small-icons.com/packs/48x48-free-time-icons.htm](http://www.small-icons.com/packs/48x48-free-time-icons.htm).
    * Attribution:  [http://www.small-icons.com/packs/48x48-free-object-icons.htm](http://www.small-icons.com/packs/48x48-free-object-icons.htm).

* Glyphish Attribution - some graphics files from Gliphish.com are used under a
[Creative Commons Attribution-Share Alike 3.0 License](http://creativecommons.org/licenses/by/3.0/us/)
These files are in a separate folder with attribution - 
[Icons by Joseph Wain / glyphish.com](http://glyphish.com)
The high-resolution retina toolbar icons are not redistributable so are not 
included in this distrubution.

* Rob Alan Attribution - some graphics files from Rob Alan are used under a
[Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License](http://creativecommons.org/licenses/by-nc-sa/3.0/).
These files are in a separate folder with attribution - [App Icon by Rob Alan](http://robalan.com)

* The Working Group Attribution - some graphics files from The Working Group are from [The Working Group](http://blog.twg.ca/2009/09/free-iphone-toolbar-icons/) and are used under a 
[Creative Commons Attribution-Share Alike 3.0 License](http://creativecommons.org/licenses/by/3.0/us/).

* Oxygen Attribution - some graphics files from Oxygen-Icons.org are from [Oxygen Icons](http://www.oxygen-icons.org) and are used under a 
[Creative Commons Attribution-Share Alike 3.0 License](http://creativecommons.org/licenses/by/3.0/us/)

* Mike Koenig Attribution - the Train Honk file is from Mike Koenig and are used under a 
    [Creative Commons Attribution License](http://creativecommons.org/licenses/by/3.0/)- location
[soundbible.com](http://soundbible.com/1695-Train-Honk-Horn-2x.html).

* Leah Culver - Pull to Refresh: [http://github.com/leah/PullToRefresh]

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    

Change log
----------

### Version 6.1 (November 2011)
* Support for Xcode 4.2; still compiles and runs on original iPhone.
* Fixed Xcode 4.2 analysis issues
* Added Pull to Refresh code
* Fixed issues with using Contacts with the Trip Planner in iOS5.
* Now caches arrivals for up to two hours for devices that are not always connected.
* Added a quick locate toolbar item to the first screen.
* Added code to flash the LED if the hardware is available and the OS version allows.
                         
### Version 6.0.1 (August 2011)
* Fixed locate nearby stops so that GPS cannot be left on.  
 
### Version 6.0
* Fixed locate nearby stops so that GPS cannot be left on.
* Updated PGE Park to JELD-WEN Field on the map.  Go Timbers!
* Added 'commuter bookmarks' - any bookmark can be configured to automatically display
    on your morning or evening commute.
* Added a proximity alarm to alert you when you get close to a stop (iOS 4.0 and above).
* Added an arrival alarm to alert you when a bus or train is getting close (iOS 4.0 and above).
* Added 'Plan trip from here' option to arrival screen.
* Arrivals have an arrow to expand the rows to include extra menu items for each stop.
* Locate by route now allows multiple route selection.
* Updated network error processing.
* Added in-app settings which are the same as the Settings app settings.
* Updated many user interface elements, including: reverse button on trip planner.
* Bug fixes - now loads on iOS5.
</ul>    

### Version 5.2
* User requested changes:
    * Arrival screen now shows  the scheduled time in addition to the estimated time (so you can tell if a bus is running late or early).   The arrival time screen has been adjusted to make space for this (e.g. arrivals are not shown to the nearest second and a button has been removed).The find stop by location feature has been updated to be more flexible and have more options (such as showing the nearest routes and going straight to a map).
    * The "busy" screen has been updated to show what stop is being downloaded.
    * Added a very large font Bus Line identifier screen. This is intended as an alternative to the large-print book provided to partially sighted travelers to let the operator know which bus they need to board.
* Other updates:
    * Updated the rail map to include Bike &amp; Ride Info.
    * Added a Facebook Fan Page.
    * Added a few more retina graphics.
    * Several bug fixes and new settings (to work around a continuous refresh issue).
    * Phone will not go to sleep while showing the Night Visibility Flashing Light (user is warned). 

### Version 5.1

* Updated to use TriMet's new location services API, removing the need for the stop location database (saving about 230K).
* Added new hi-res icons for the retina display.
* Bug fixes: e.g. fixed ability to add user-entered IDs to bookmarks.

### Version 5.0

* Trips can now be bookmarked and then re-planned with a single touch. Check out the bookmark icon in the toolbar on the trip screen.  Tip:  bookmark a trip from the Current Location to your home and call it "Take me home!"
* The Trip planner user interface has a new more intuitive flow, and the map has a previous/next button to step through the trip. 
* Trips are automatically saved to a new "Recent Trips" screen and can be viewed later without a network connection.
* Trips can be texted to other cell phone users directly from inside PDX Bus (requires an iPhone with iOS 4.0).
* Trips can be added as events to the calendar (iOS 4.0 required).
* Trips planned using the GPS now show the location's name instead of 'Current Location'.
* Added 'Search rail stations' screen.
* Rail arrivals include a colored circle to indicate the line.
* Stops can be sorted alphabetically.
* Recent stops now have their own screen.
* Added up/down arrows to the rider alerts and fixed fonts sizes.
* Settings now update instantly in iOS4;  added Color Themes and made it blue by default.

### Version 4.2.1

* Stylish new icon
* Updated attributions (including Civic App award!)
* Minor bug fixes
* Fixed issue with some Streetcar stops giving the wrong arrivals (e.g. Stop ID 12375).


### Version 4.2
* Support for iOS4 and fast switching between apps. Regular features are designed to work on all models of iPhone, iPad and iPod touch running OS version 3.0 and above.
* The current location "blue dot" is now shown on all maps.
* The tip planner map now shows the actual route of the busses and trains.
* Fixed usability issue with bookmarks - the bookmark icon can be used to edit or delete an existing bookmark was well as to add one.
* Routes, directions and stop names are cached until the end of each day (or optionally until the end of the week).  (TriMet tells me that routes only change at midnight - mostly they change weekly on Sunday but occasionally they change mid-week).
* Multiple bug fixes and tweaks (e.g.  fixed iPhone font issues introduced when adding iPad support, fixed different behavior of home button).

### Version 4.1
First Open Source Version.


HAVE FUN!

Andrew Wallace, November 2011.
