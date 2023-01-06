Hacking on the Camera App
=========================

Hey There, Welcome to camera app development crash course :) 
Current structure is the code is pretty flat and need refactoring but thats  what we have for now...

````
 - Root directory :
 |      Contain most of the QML files that build the UI and the basic logic of the camera-app
 |- CameraApp directory : 
 |       Contains the backend / c++ code of the camera app.
 |- assets directory :
 |      Contains icons/images used in the app
 |- debain directory : 
 |      Conatins the debian packaging information
 |- qml directory :
 |      Conatin some of the newer features added after UT hand off and what was refactored 
 |      when it was possible to refactor and move the new files to here under (logically) structured }  |      directories.
 |- snap directory :
 |      Contain scripts to be used when packaging the app as a snap.
 |- tests directory :
        Conatins the application unit/UI tests scripts
````

Building the app
----------------

*Building a click package*
We are using [clickable](https://clickable.bhdouglass.com/en/latest/install.html) to build the click package, building the package and installing on the device should be simple just run :

1. `cd <Project Root directory>`
1. `clickable`

package should be under `<Project Root directory>/build/<device architecture>/` and the application should be installed to the device if it`s connected and has the Developer mode enabled.

*Building the snap package*
**Currently still under development**
For building the snap we are using [snapcraft](https://snapcraft.io/docs) to build a the snap pacakge, building the package should be simple just run :

1. `cd <Project Root directory>`
1. `snapcraft`
1. Install with : `snap install --devmode  --dangerous <snap paackage>`

Running the tests
-----------------
There are tests...  currently not working that good ... further explnation wil be add or in other words TODO :)
