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

All variable values are **double** if not indicated otherwise

| Variable                        | Description                                                  | Unit | Remarks                                       |
| ------------------------------- | :----------------------------------------------------------- | ---- | --------------------------------------------- |
| sstart                          | start time displayed in results sets                         | s    |                                               |
| sfinish                         | finish time displayed in results sets                        | s    | negative values - no finish                   |
| sdis                            | distance shown in results                                    | m    | negative values will be shown in parenthesis  |
| sspeed                          | speed shown in results                                       | m/s  | negative values will be shown in parenthesis  |
| points                          | points shown in results                                      |      |                                               |
| pointString                     | a string representation of points for custom output          |      | string                                        |
| Hcap                            | handicap factor as declared in pilot setup                   |      |                                               |
| penalty                         | penalty points defined in "Day performance" dialog           |      |                                               |
| start                           | start time of task                                           |      | -1 if no start                                |
| finish                          | finish time of task                                          |      | -1 if no finish                               |
| dis                             | flown distance                                               |      |                                               |
| speed                           | speed of finished taks                                       |      | -1 if no finish, takes into account task time |
| tstart                          | start time of task with time                                 |      | -1 if no start                                |
| tfinish                         | finish time of task with time                                |      |                                               |
| tdis                            | flown distance in task time                                  |      |                                               |
| tspeed                          | flown distance divided by task time                          |      |                                               |
| takeoff                         | takeoff time                                                 |      | -1 if no takeoff                              |
| landing                         | landing time                                                 |      | -1 if no landing                              |
| phototime                       | outlanding time                                              |      | -1 if no outlanding                           |
| isHc                            | set to TRUE if not competing is used                         |      | bool                                          |
| FinishAlt                       | altitude of task finish                                      |      |                                               |
| DisToGoal                       | distance between Task landing point and flight landing point |      |                                               |
| Tag                             | string value as defined in Day performace dialog             |      | string                                        |
| Leg, LegT                       | array of TLeg records                                        |      | array                                         |
| Warning                         | used to set up a user warning                                |      | string                                        |
| CompID                          | Competition ID of the glider                                 |      | string                                        |
| PilotTag                        | string value as defined in Pilot edit dialog                 |      | string                                        |
| user_str1, user_str2, user_str3 | user strings, use for anything                               |      | string                                        |
| td1, td2, td3                   | temprary variables, use for anything                         |      |                                               |
| Markers                         | array of TMarker (see definition for TMarker below)          |      | array                                         |
| PotStarts                       | Array of all valid crossings of the start line. In seconds since midnight | s    | array of integers                             |

### TLeg 

Type: record

Task leg information

| Entry  | Description     | Unit | Remarks |
| ------ | --------------- | ---- | ------- |
| start  | leg start time  | s    |         |
| finish | leg finish time | s    |         |
| d      | leg distance    | m    |         |
| crs    | leg course      | rad  |         |

### TMarkers

Type: record 

Records of Pilot Event Marker (PEM) events - created when pilot depressed "Event Marker" button.

| Entry        | Description                                      | Unit | Remarks |
| ------------ | ------------------------------------------------ | ---- | ------- |
| Tsec         | time of the PEM                                  | s    | integer |
| Msg          | optional message stored with the PEM in IGC file |      | string  |
| info1, info2 | information shown in the results                 |      | string  |
| DatTag       | value as defined in "Day properties" dialog      |      | string  |
| ShowMessage  | string for debugging purposes                    |      | string  |

### Task 

Type: record

Basic information about task

| Entry             | Description                     | Unit | Remarks |
| ----------------- | ------------------------------- | ---- | ------- |
| TotalDis          | task distance                   | m    |         |
| TaskTime          | task time                       | s    | integer |
| NoStartBeforeTime | start time                      | s    | integer |
| Point             | array of TTaskPoints            |      | array   |
| ClassID           | enum of existing glider classes |      | string  |

ClassID enum:

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

- ClassName: string; 
  Optional nice name for the given class - as entered at Soaring Spot.

### TTaskPoint

Type: record

Basic information about taskpoint and leg

| Entry         | Description                           | Unit | Remarks |
| ------------- | ------------------------------------- | ---- | ------- |
| lon           | longitude                             |      |         |
| lat           | lattitude                             |      |         |
| d             | distance to next point                | m    |         |
| crs           | course to next point                  | rad  |         |
| td1, td2, td3 | optional, used as temporary variables |      |         |

## Available variables for total results script

### Pilots

Type:  record

| Entry        | Description                                         | Unit | Remarks                                  |
| ------------ | --------------------------------------------------- | ---- | ---------------------------------------- |
| Total        | total points                                        |      | default value is sum of DayPoints, not 0 |
| TotalString  | format of the total points when shown as string     |      | string                                   |
| DayPts       | Points from each day as calculated in daily scripts |      | array of doubles                         |
| DayPtsString | format of the day points when shown as string       |      | string                                   |

# Contributing guidelines

You wrote a great script, found a bug and corrected it? Great! To incorportate changes to existing scripts or adding your own scripts, please fork the repo, make your changes in a new branch and create a pull request. Pull requests from forks are described in [pull request from fork](https://help.github.com/en/articles/creating-a-pull-request-from-a-fork) article.
