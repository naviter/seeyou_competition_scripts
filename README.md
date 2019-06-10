![SeeYou Competition Scoring Scripts](https://www.naviter.com/scoring_scripts_github.png)

### Table of contents
<!--ts-->
	* [Writing your own scripts](#writing-your-own-scripts)
		* [Available variables for daily points scripts](#available-variables-for-daily-points-scripts)
		* [Available variables for total results script](#available-variables-for-total-results-script)
	* [Contributing Guidelines](#contributing-guidelines)
<!--te-->

# Writing your own scripts

**Scripts for daily results**

SeeYou will calculate the day performance items like Marking Distance, speed, start and finish times etc.  It is the responsibility of the script to determine how many POINTS are awarded for the achieved  performance. 

SeeYou Competition scripts are implemented using the Innerfuse [Pascal Scripts](http://www.carlo-kok.com). They are very basic Pascal routines with some exceptions. 

You can write scripts in Notepad or any other Text  editor of your choice. You can assign scripts to each class of competition separately through Edit > Competition Properties > Scripts. 

![img](https://d33v4339jhl8k0.cloudfront.net/docs/assets/5a1c4392042863319924c769/images/5cf8efcc2c7d3a3837133075/file-TKhMl28z6o.png)

It is important to keep the general structure of the script: 

```pascal
Program Scoring_Script_Name;

begin

	// Your script here

end.
```

There are many variables available to the scoring script. See "Available variables for daily points script".

**Scripts for total rsults**

You can also write a script for Total results. Procedure is the same way as for daily scripts except that they are located in Edit > Competition Properties > Total Script. See "Available variables for total points script".

**How does it work?**

A TPilots record is provided by SeeYou to the Scoring script. TPilots record and a couple other fields determine all the information required to calculate the scoring for a given contest day. This is the definition of the TPilot record: 

## Available variables for daily points scripts

Pilots[i] = record (values are Double if not indicated otherwise)

- sstart start time displayed in results sets in seconds
- sfinish finish time displayed in results sets in seconds (negative values - no finish) 
- sdis distance shown in results in meters (negative values will be shown in parenthesis)
- sspeed speed shown in results in m/s (negative values will be shown in parenthesis)
- points points shown in results
- pointString: string; a string representation of points for custom output
- Hcap handicap factor as declared in pilot setup
- penalty penalty points defined in Day performance dialog
- start start time of task (-1 if no start)
- finish finish time of task (-1 if no finish)
- dis flown distance
- speed speed of finished taks (-1 if no finish, takes into account task time)
- tstart start time of task with time (-1 if no start)
- tfinish finish time of task with time
- tdis flown distance in task time
- tspeed flown distance divided by task time
- takeoff takeoff time (-1 if no takeoff)
- landing landing time (-1 if no landing)
- phototime outlanding time (-1 if no outlanding)
- isHc set to TRUE if not competing is used
- FinishAlt altitude of task finish
- DisToGoal distance between Task landing point and flight landing point
- Tag string value as defined in Day performace dialog
- Leg,LegT array of TLeg records (see definition for TLeg below)
- Warning: String; used to set up a user warning
- CompID: String; Competition ID of the glider
- PilotTag: String; string value as defined in Pilot edit dialog
- user_str1,user_str2,user_str3: String; user strings, use for anything
- td1,td2,td3: Double; temprary variables, use for anything
- Markers: array of TMarker (see definition for TMarker below)
- PotStarts: array of Integer; Array of all valid crossings of the start line. In seconds since midnight

TLeg = record; holding leg information

- start,finish,d,crs Double; time in seconds, distance in meters, crs in radians
- td1,td2,td3 Double; variables may be used as temporary variables  

TMarkers = record; this record holds information about all the times when Pilot Event Marker button has been pressed

- Tsec: Integer; Time of each press of the Pilote Event button
- Msg: Optional message that is stored with the Pilot Event marker in IGC file

Other variables

- info1..info2 informational strings shown on results
- DayTag string value as defined in Day properties dialog
- ShowMessage( s:string ); use this to debug your scripts 

Task = record; holding basic information about task

- TotalDis: Double; task distance in meters
- TaskTime: Integer; task time in second  
- NoStartBeforeTime: Integer; start time in second
- Point: Array of TTaskPoint; description of task
- ClassID: string; An enum of existing classes:
  - world
  - club
  - standard
  - 13_5_meter
  - 15_meter
  - 18_meter
  - double_seater
  - open
  - hang_glider_flexible
  - hang_glider_rigid
  - paraglider
  - unknown
- ClassName: string; Optional nice name for the given class (as entered at Soaring Spot)

TTaskPoint = record; holding basic information about taskpoint and leg

- lon,lat: Double; 
- d,crs: Double; distance, course to next point
- td1,td2,td3 Double; variables may be used as temporary variables

## Available variables for total results script

Pilots = record

- Total : Double; total points (default value is sum of DayPoints, not 0)
- TotalString : String; if this is not empty, total points will be shown as the string defined in this value 
- DayPts : array of Double; Points from each day as calculated in daily scripts
- DayPtsString : array of String; Same functionality as TotalString

# Contributing guidelines

You wrote a great script, found a bug and corrected it? Great! To incorportate changes to existing scripts or adding your own scripts, please fork the repo, make your changes in a new branch and create a pull request. Pull requests from forks are described in [pull request from fork](https://help.github.com/en/articles/creating-a-pull-request-from-a-fork) article.
