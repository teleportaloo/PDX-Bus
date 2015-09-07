PDX Bus is an award winning application that displays arrival times for public transport in Portland, Oregon.

(PDX Bus won Best in Show at the [CivicApps.org](http://www.CivicApps.org) awards)

This little application uses the Internet to quickly access TriMet's live tracking data to display arrival times perfectly formatted for the iPhone. It allows you to bookmark frequently used stops, displays recently accessed stops, and gives details for arrivals which are en-route.

You can enter the stop "id" of the stop (as displayed at each stop or station) or you can browse the routes for the stop.

Features include:

* Interactive rail maps, showing the MAX, WES and Streetcar stops.
* Embedded maps, showing locations of stops, and when available, the last known position of the bus or train.
* Use GPS to locate nearby stops or rail stations.
* Browse routes and stops, show an entire route on the map.
* Links to TriMet route information.
* Displays Rider Alerts, and Detours.
* A "Nighttime visibility flasher" - a flashing screen that can be used at night so that drivers can see you. TriMet suggests holding up a cell phone to make yourself visible to bus drivers.
* Trip Planning - now you can use the same trip planning feature that is available on TriMet's web site.
* Specially formatted text to work with the iPhone 3GS VoiceOver accessibility feature to speak arrivals.

Route and arrival data provided by permission of TriMet.

PDX Bus 7.11 sources
===================

I am making the sources to PDX Bus version 7.9 available as part of the
[Civic Apps](http://www.civicapps.org) competition.  These
sources were developed by me from Apple samples and documentation, except 
where explicitly mentioned in the code.  

I am choosing to release a copy of the code under the 
[MPL 2.0](http://www.mozilla.org/MPL/) License but I retain the copyright,
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

Because I wish to retain the sole copyright on the code, I am currently not
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
* [PDX Bus in the iTunes store](https://itunes.apple.com/app/pdx-bus-max-streetcar-and-wes/id289814055?mt=8)
* [PDX Bus on Twitter](http://twitter.com/pdxbus)
* [PDX Bus on Facebook](http://facebook.com/pdxbus)

Things to know before building
------------------------------
* PDX Bus is built with iPhone SDK 8.3 and Xcode 6.3.1 - available free
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
and will not work.  This gif file is converted into a set of tiles to enable a more efficient display.

### Enabling the project to use the graphics
Once the graphics have been downloaded and copied into place you will need to 
enable them in the project.

* In the Xcode project, under Resouces you will find graphics folders. The file names
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

* Gentleface Attribution - some graphics files from Gentleface are from [Gentleface](http://gentleface.com/free_icon_set.html) and are used under a 
[The Creative Commons Attribution-NonCommercial 3.0 License](http://creativecommons.org/licenses/by-nc/3.0/).

* Oxygen Attribution - some graphics files from Oxygen-Icons.org are from [Oxygen Icons](http://www.oxygen-icons.org) and are used under a 
[Creative Commons Attribution-Share Alike 3.0 License](http://creativecommons.org/licenses/by/3.0/us/)

* Mike Koenig Attribution - the Train Honk file is from Mike Koenig and are used under a 
    [Creative Commons Attribution License](http://creativecommons.org/licenses/by/3.0/)- location
[soundbible.com](http://soundbible.com/1695-Train-Honk-Horn-2x.html).

* QR Code Scanning - ZXing library [http://http://code.google.com/p/zxing/] is Apache 2.0 licensed with changes by A.R.Wallace.

* Leah Culver - Pull to Refresh: [http://github.com/leah/PullToRefresh] - license below:

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
### Version 7.11 (September 2015)
* Added Orange line support including new color and updated MAX and WES MAP
* Added A Loop and B Loop colors and new streetcar map
* TriMet API now uses HTTPS.


### Version 7.9 (August 2015)
* Refactored code into a framework to allow for an extension - refactored other code to separate out the UI from data.
* Added Apple Watch app with simple arrivals and locate nearby stops.
* Fixed Arrival table size for older iPhones.
* Added better support for localization authorization.
* Fixed date and time screen on iPads when rotated.
* Fixed Streetcat typo
* Merged Pebble support into mainline code
* Dropped support for iOS 5 and updated deprecated items.


### Version 7.2 (December 2014)
* Updated for iOS 8.
* Native support for iPhone 6 + 6 Plus screen sizes
* New MAX and WES map.
* Updated disclaimer for maps.
* Added text to explain the different colors used for the arrival times.
* Removed streetcar data tables;  streetcar data is fetched via TriMet feed now except for location data.
* Changed the keyboard type to allow emoji again.

### Version 7.1 (February 2014)
* Fix for Streetcar API changes
* Added back 'Bookmarks at the top' setting.
* Added Cross for canceled busses.
* Fixed refresh timer button so it doesn't flash.
* Fixed app store link from main screen.
* Fixed table alignment when using prompts on navigator bar in iOS7.
* Fixed window size for iPad rail map view and web view.
* Now uses Apple's geocoder for getting addresses from GPS locations
* Fixed issues when GPS is used for destination in Trip Planner.
* Added back proximity alarm icon.
* Moved machine generated into into their own files.
* Removed black color theme as it does not work well in iOS7.
* Changed JELD-WEN Field to Providence Park.
* Added Route map with stops to arrival details.
* Toolbar map icon now behaves consistantly & added new menu item to map arrivals.
* 64-bit type casting changes.
* Added new pdxbusroute: URL to support the BlindSquare app.
* Added tiling to the MAX and Steetcar maps - this reduces the number of hotspots to search by a lot as for each tile there is a short array to search.
* Moved streetcar data into a singleton instread of it being with the app object; removed streetcar exception code.
* Fixed circular references in the RailMapView - this caused a memory leak that was not spotted by static analyis or Instruments.
* Nearby stops now uses the FindByLocationView to show all the possible options.
* Re-allowed emoji keyboard for bookmark names
* Fixed iOS7 text height calculations.


### Version 7.0 (January 2014)
* Updated for iOS7.
* Updated user interface for iOS 7.
* New icon from Rob Alan.
* Added vehicle color "tags"
* Added TriMet Facebook page.
* Added support to launch TriMet Tickets App.
* Added warning for flashing light.
* Many toolbar icons are now optional - see settings.
* Fixed location search so that stops that are both bus and rail stops are correctly filtered.
* Fixed locator screen flow.
* Large bus line identifier now rotates on iPhone.
* Disabled screen rotation on old iPads as it did not fully work.
* Added rail map toolbar button to station list screen.
* Fixed streetcar arrivals on Harrison.
* Refactored trip planner

### Version 6.7 (May 2013)
* Added Streetcar CL line to stop ID 9600 (SW 11th & Alder).
* Added new options when pins on a map are selected - app can now open an external map app and display the location. Supported map apps include Google map app, Waze, MotionX-GPS, and Apple maps.
* Several map fixes including: Maps can track with location and rotate with compass heading (iOS 5 & above); updated maps button to only show stops (and not arrivals) when there are multiple stops.
* Updated Commuter toolbar icon.
* Rationalized locate options; added setting to change toolbar behavior, made locate icon the same.
* Updated URL scheme to add parameters for nearby command:  pdxbus://nearby&show=maps&distance=1&mode=trains where show can be maps, routes or arrivals, distance can be closest, 0.5, 1, or 3 and mode can be bus, train or both.
* User is now warned that the alarm will not sound if the device is muted (the app cannot detect if it is actually muted or not). This is to stop me sleeping through stops by accident.
* Added a new longer, more annoying sound that can be used for alarms.
* Fixed issue when keyboard did not show up when hitting the search button for the first time and fixed Help/Done buttons for the same editing case.
* Added option to open Google Chrome app instead of Safari.
* Updated to XCode 4.6 - fixed analysis errors found by latest analyser.
                         
### Version 6.6 (October 2012)
* Fixed stop ID 13604 - added NS Line arrivals.
* Optimized rail maps to use "tiles" - reducing crashes due to memory issues.
* Added additional informational hotspots to streetcar map.
* Trip planner min walk distances now match web site (1/10, 1/4, 1/2, 3/4, 1 & 2 miles).
* Commuter bookmarks fixed (startup sequence is different in iOS6).

### Version 6.5 (September 2012)
* Full support for New Portland Streetcar Central Loop Line, including Streetcar map.
* iOS6: Fixed crash when GPS finds no nearby stops,
* iOS6: Fixed calendaring.
* iOS6: Fixed orientation issues.
* Icon has been tweaked (thanks Rob!), improved launch screens.

### Version 6.4 (September 2012)
* Added partial support for new Streetcar Loop. Full support soon!
* New for iOS 6 - added support for transit routing from Apple's map app.
* Full screen iPhone 5 support.
* New retina display launch screens.
* Dropped support for original iPhone running iOS 3.2. :-(
* Extended URL scheme to include new keywords: "nearby", "commute", "tripplanner", "qrcode", "bookmarknumber=<number>"

### Version 6.3 (September 2012)
* Added QR code reader
* Added new higher resolution rail map with no zones and new PSU stations
* Added Twitter integration
* Added XML viewer integration
* Removed Rail Map from iOS3.1 - it crashes, low memory.
* Updated to XCode 4.4 and fixed analysis issues.
* Extended app URL scheme e.g. pdxbus://365 will launch PDX Bus and show stop 365.  (Useful for app launchers such as 'Icon Project' or 'Launch Center Pro').
* Trip planner allows min walking distance of 0.1 miles

### Version 6.2.4 (June 2012)
* Support for Xcode 4.3.2; still compiles and runs on original iPhone.
* Fixed Xcode 4.3.2 analysis issues
* Fixed VoiceOver issues with "segment controls" and buttons.
* Changed app name to "PDX Bus" (added the space).
* Increased size of 'X' icon to make easier to touch.
* Caches are more robust, if the app discovers it had previously crashed it will delete all caches.
* Fixed weak reference in background task container - this will now be cleared when the view object is dealloced - this is about 33% of crashes.
* Added alert for when an alarm will not be able to complete in the background so the user knows to go back to PDX Bus.
* Added short version string to budle version to allow archiving to get the version.
* Added debug option to turn off all caching (as caching sometimes causes crashes).
* Added Plan trip from here/to here options on the rail station screen.

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

Andrew Wallace, August 2015.
