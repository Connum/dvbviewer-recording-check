# dvbviewer-recording-check
AutoIt script that checks [DVBViewer](http://dvbviewer.com) Recording Service recordings for errors at recording start, and if more than a specific amount of errors has been found in a short period of time, restarts the recording, which often fixes damaged recordings (especially caused by TBS drivers).

The idea for and the original version of this script came from user [beeswax](http://www.dvbviewer.tv/forum/user/139310-beeswax/) in this DVBViewer forum thread:
[Restart recording if [x] errors in [y] seconds](http://www.dvbviewer.tv/forum/topic/55885-restart-recording-if-x-errors-in-y-seconds/)

## requirements/installation
Obviously, besides DVBViewer and the Recording Service, this script is intended to be used by the automation software AutoIt for Windows. It's freeware and you can download it here: https://www.autoitscript.com/site/autoit/downloads/

It also needs the AutoIt _XMLDOMWrapper component. Copy the file Includes/_XMLDOMWrapper.au3 from this repository into the Include directory of your AutoIt installation, currently located at C:\Program Files (x86)\AutoIt3\Include

The reccheck.au3 script file can be saved anywhere you like, you can even rename it. It's probably a good idea to create a shortcut to it in your autostart folder, so you don't forget to run it whenever your computer is restarted (e.g. by automatic updates). It will run in the background and not consume many resources.

TODO: provide information about where to find the autostart directory for various Windows versions

## configuration

Before running the script, you'll have to adapt some settings in the script itself, especially the recording path. 
It should be quite obvious what you need to edit, however:
TODO: provide some more information on the configuration settings/variables

If you run the script on the same machine as the DVBViewer Recording Service, you can just leave 127.0.0.1 as the default IP.
In order to add your Recording Service login information, you can provide it in the $DVBip variable in the following form:
username:password@ipaddress

## usage

Once started, the script periodically checks for newly started recordings in the specified recording directory. If one is found, it will be checked for any errors via the Recording Service log file after 60 seconds. If more than 2 errors have been logged, the recording will be stopped and re-started via the Recording Service API, which should hopefully result in an error-free recording, provided that the source of the errors is a faulty DVB driver rather than a weak signal, for example caused by an incorrectly adjusted dish. ;-) If less or no errors have been found, the recording will just be left running.

The script will also create a log file (RecordMonitor.txt in the same directory by default) so you can check if everything is running as intended.

If you have multiple recording directories, currently the only solution is to have an appropriate amount of copies of the script with different recording paths set. (This has not been tested yet, but it should work.) It's probably a good idea to change the name of the log file as well.

## TODO / ideas (anyone is welcome to contribute!)
- support for multiple recording directories without having to run multiple copies of the script with different paths
- outsource the configuration to another script file so updating is easier in the future
- configurable login information with variables
- configurable error count threshold as variable
