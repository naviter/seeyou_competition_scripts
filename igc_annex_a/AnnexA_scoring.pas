Program Annex_A_scoring_2026_TEST;
// Collaborate on writing scripts at Github:
// https://github.com/naviter/seeyou_competition_scripts/
//
// Version 11.00, Date 3.06.2026 by Wojciech Scigala
//   . no negative daily points after penalties deduction
//   . add missed PEV-gate information (in seconds)
//   . AllUserWarn renamed to PevUserWarn
//   . if PevUserWarn = 0 all data is shown anyway if there is PEV fault
//   . show warning if there is potential start after selected one
//   . limited support for Cylinder Start: set CylinderStart=1 in DayTag
//     throws an error if PEV is different than calculated Start Time
//   . start groundspeed calculated now for +/- 8 seconds period, but this is still
//     not compliant with Annex A (not possible to implement completely)

// Version 10.00 Date 30.10.2023 by Neil Campbell
//   . Incorporate changes required for Annex A 2023 Edition and WGC 2023 Local Procedures
//       . Support for 7.4.5b Starting Procedures - Pre-start altitude
//       . enter "PreStartAlt=nnn" in DayTag where nnn is altitude in m
//   . User warning for below minimum height above airfield elevation - copy Ian's from Australia Rules
//   . fix calculation of n3 to only count actual finishers.
//   . include newline between user warnings to improve readability
//   . ignore PEV markers after start
//
// Version 9.03, Date 19.04.2023 by Andrej Kolar
//   . Renamed Vo to V0 for consistency with T0 and D0
// Version 9.02, Date 17.07.2022 by Andrej Kolar
//   . Reintroduced Hmin parameter to be able to calculate results for Handicaps between 80-130
// Version 9.01, Date 08.07.2022 by Andrej Kolar
//   . Removed reference to Hmin in all calculations to be compliant with the latest version of Annex A
// Version 9.00, Date 07.02.2022 by Lothar Dittmer
//   . support for PEV start scoring 
//   . enter "PEVWaitTime=10" in DayTag to have PEV gate opening 10 min after PEV.
//   . enter "PEVStartWindow=10" in DayTag to have 10 min long startwindows after PEV. 
//   . separate Tags with Blank ' ' (required)
//   . example: DayTag: "PEVWaitTime=10 PEVStartWindow=10" allows 3 possible start windows with length 10min starting 10 min after PEV 1,2 or 3
//   . if "AllUserWrng" in DayTag is set to 0 user warning with PEVs is only shown if penalty should be necessary otherwise PEVs are displayed
//   . buffer zone as a script parameter
//   . added start speed interpolation according to DAEC SWO 7.3.5
//   . enter "MaxStSpd=130" in DayTag to have interpolation and userwarnings if average start speed is higher than 130km/h 
// Version 8.01, Date 20.04.2021
//   . added ReadDayTagParameter() function to read any DayTag parameter
//   . parameters in DayTag now have to be separated by space (only)
//   . example: "PEVWaitTime=10 PEVStartWindow=10"
// Version 8.00, Date 26.06.2019
//   . merged all scripts into one
//   . by default UseHandicaps is in auto mode
//   . new n3 and n4 parameters (currently unused)
//   . redesigned Info fields
//   . renamed V0 to Vo
// Version 7.01
//   . D1 is set to a default value. Previously it did not work with unknown class
// Version 7.00
//   . Support for new Annex A rules for minimum distance & 1000 points allocation per class
// Version 5.02, Date 25.04.2018
//   . Bugfix in Fcr formula
// Version 5.01, Date 03.04.2018
//   . Bugfix division by zero
// Version 5.00, Date 23.03.2018
//   . Task Completion Ratio factor added according to SC03 2017 Edition valid from 1 October 2017, updated 4 January 2018
// Version 3.30, Date 10.01.2013
//   . BugFix: Td exchanged with Task.TaskTime - This fix is critical for all versions of SeeYou later than SeeYou 4.2
// Version 3.20, Date 04.07.2008
// Version 3.0
//   . Added Hmin instead of H0. Score is now calculated using minimum handicap as opposed to maximum handicap as before
// Version 3.01
//   . Changed if Pilots[i].takeoff > 0 to if Pilots[i].takeoff >= 0. It is theoretically possible that one takes off at 00:00:00 UTC
//   . Changed if Pilots[i].start > 0 to if Pilots[i].start >= 0. It is theoretically possible that one starts at 00:00:00 UTC
// Version 3.10
//   . removed line because it doesn't exist in Annex A 2006:
// 			if Pilots[i].dis*Hmin/Pilots[i].Hcap < (2.0/3.0*D0) Then Pd := Pdm*Pilots[i].dis*Hmin/Pilots[i].Hcap/(2.0/3.0*D0);
// Version 3.20
//   . added warnings when Exit 

const UseHandicaps = 2;   // set to: 0 to disable handicapping, 1 to use handicaps, 2 is auto (handicaps only for club and multi-seat)
      PevStartTimeBuffer = 30; // PEV which is less than PevStartTimeBuffer seconds later than last PEV will be ignored and not counted

var
  Dm, D1,
  Dt, n1, n2, n3, n4, N, D0, V0, T0, Hmin,
  Pm, Pdm, Pvm, Pn, F, Fcr, Day: Double;

  D, H, Dh, M, T, Dc, Pd, V, Vh, Pv, S : double;
  
  PmaxDistance, PmaxTime : double;
  
  i,j : integer;
  PevWaitTime,PEVStartWindow,PevUserWrng, PilotStartInterval, PilotStartTime, PilotPEVStartTime,StartTimeBuffer,MaxStartSpeed : Integer;
  AAT : boolean;
  Auto_Hcaps_on : boolean;
  
  // Starttime calculation and PEV Warnings
  PilotStartSpeed, PilotStartSpeedSum, PilotStartSpeedFixes : double;
  ActMarker  : TMarker; 
  PevWarning : String;
  Ignore_PEV,PEVStartNotValid : boolean;  
  Pevcount, LastPev  : Integer; 
  PevFault : boolean;

  //Prestart Altitude 
  PreStartAltLimit, NbrFixes,  MinPreStartAltTime : Integer;
  MinPreStartAlt : Double;
  PreStartInfo : string;
  PreStartLimitOK : boolean;

  //below altitude on task
  BelowAltFound : boolean;
  FixDuration, LaunchAboveAltFix, LastFixTime, FGAboveAltFix, LowPointTsec : Integer;
  MinimumAlt, LowPoint : Double;

  //Loss of height
  MaxLoH : integer;
  PilotStartAlt : double;

  //Cylinder Start
  CylinderStart : integer;


Function MinValue( a,b,c : double ) : double;
var m : double;
begin
  m := a;
  if b < m Then m := b;
  if c < m Then m := c;

  MinValue := m;
end;

Function GetTimeString (time: integer) : string;    // converts integer time in seconds to "hh:mm:ss" string
var
  h,min,sec: Integer;
  sth,stmin,stsec:String; 
begin
  h:=Trunc(time/3600);
  min:=Trunc((time-h*3600)/60);
  sec:=time-h*3600-min*60;
  sth:=IntToStr(h);
  if Length(sth)=1 Then sth:='0'+sth;   
  stmin:=IntToStr(min);
  if Length(stmin)=1 Then stmin:='0'+stmin;   
  stsec:=IntToStr(sec); 
  if Length(stsec)=1 Then stsec:='0'+stsec;    
  GetTimeString :=sth+':'+stmin+':'+stsec;           
end;

Function ReadDayTagParameter ( name : string; default : double ) : double;
var
  sp, tp : Integer;
  sub : string;
begin
  sp := Pos(UpperCase(name) + '=',UpperCase(DayTag));

  if (sp > 0) then
  begin
    sub:= Copy(DayTag,sp + Length(name) + 1,Length(DayTag));

    tp := Pos(' ',sub);
    if (tp > 0) then
      sub:= Copy(sub,0,tp-1);

    tp := Pos(',',sub);
    if (tp > 0) then
      sub := Copy (sub,0,tp-1) + '.' + Copy (sub,tp+1,Length(sub));
    ReadDayTagParameter := StrToFloat(sub);
  end
  else
    ReadDayTagParameter := default;            // string not found
end;

//  Main Code
begin
  // initial checks
  if GetArrayLength(Pilots) <= 1 then
    exit;

  if (UseHandicaps < 0) OR (UseHandicaps > 2) then
  begin
    Info1 := '';
    Info2 := 'ERROR: constant UseHandicaps is set wrong';
    exit;
  end;

  if Task.TaskTime = 0 then
    AAT := false
  else
    AAT := true;

  if (AAT = true) AND (Task.TaskTime < 1800) then
  begin
    Info1 := '';
    Info2 := 'ERROR: Incorrect Task Time';
    exit;
  end;


  // Minimum Distance to validate the Day, depending on the class [meters]
  Dm := 100000;
  if Task.ClassID = 'club' Then Dm := 100000;
  if Task.ClassID = '13_5_meter' Then Dm := 100000;
  if Task.ClassID = 'standard' Then Dm := 120000;
  if Task.ClassID = '15_meter' Then Dm := 120000;
  if Task.ClassID = 'double_seater' Then Dm := 120000;
  if Task.ClassID = '18_meter' Then Dm := 140000;
  if Task.ClassID = 'open' Then Dm := 140000;
  
  // Minimum distance for 1000 points, depending on the class [meters]
  D1 := 250000;
  if Task.ClassID = 'club' Then D1 := 250000;
  if Task.ClassID = '13_5_meter' Then D1 := 250000;
  if Task.ClassID = 'standard' Then D1 := 300000;
  if Task.ClassID = '15_meter' Then D1 := 300000;
  if Task.ClassID = 'double_seater' Then D1 := 300000;
  if Task.ClassID = '18_meter' Then D1 := 350000;
  if Task.ClassID = 'open' Then D1 := 350000;

  // Handicaps for club and 20m multi-seat and unknown (formerly 'mixed') class
  Auto_Hcaps_on := false;
  if Task.ClassID = 'club' Then Auto_Hcaps_on := true;
  if Task.ClassID = 'double_seater' Then Auto_Hcaps_on := true;
  if Task.ClassID = 'unknown' Then Auto_Hcaps_on := true;

  // PEV Start PROCEDURE
  // Read PEV Gate Parameters from DayTag. Return zero PEVWaitTime or PEVStartWindow are unparsable or missing
  
  StartTimeBuffer:=30; // Start time buffer zone. if one starts 30 seconds too early he is scored by his actual start time
  PEVWaitTime := Trunc(ReadDayTagParameter('PEVWAITTIME',0)) * 60;	// WaitTime in seconds 
  PEVStartWindow := Trunc(ReadDayTagParameter('PEVSTARTWINDOW',0))* 60; // StartWindow open in seconds
  MaxStartSpeed := Trunc(ReadDayTagParameter('MAXSTSPD',0));		// Startspeed interpolation done if MaxStartSpeed (in km/h) >0
  PevUserWrng := Trunc(ReadDayTagParameter('PEVUSERWRNG',0));		// Output of All UserWarnings with PEVs: ON=1(for debugging and testing) OFF=0  
  MaxLoH := Trunc(ReadDayTagParameter('MAXLOH',-1));			// Loss of Height limit
  CylinderStart := Trunc(ReadDayTagParameter('CYLINDERSTART',0));	// Cylinder Start option (only checks if PEV = Start time)

  // if DayTag variables PEVWaitTime and PEVStartWindow are set (>0) then PEV Marker Start Warnings are shown 
  if (PEVWaitTime > 0) and (PEVStartWindow> 0) then																					// Only display number of intervals if it is not zero
    begin
    Info3 :='PEVWaitTime: '+IntToStr(PevWaitTime div 60)+'min, PEVStartWindow: '+IntToStr(PevStartWindow div 60)+'min, ';
    end
  else 
    begin
    Info3:='PEVStarts: OFF, ';
    PEVWaitTime:=0;
    PEVStartWindow:=0;
    end;  

  // Prestart Altitude
  PreStartAltLimit := Trunc(ReadDayTagParameter('PRESTARTALT',0));		// Prestart altitude in m >0
  if PreStartAltLimit > 0 then
  begin
    Info3 := Info3 + 'PreStart Alt = '+IntToStr(PreStartAltLimit)+'m, ';
  end;


  // altitude less than minimum altitude
  MinimumAlt := Trunc(ReadDayTagParameter('MINIMUMALT',0));	
  if MinimumAlt > 0 then
  begin
    Info3 := Info3 + 'Minimum Alt = '+FloatToStr(MinimumAlt)+'m, ';
  end;


  // Calculation of basic parameters
  N := 0;  // Number of pilots having had a competition launch
  n1 := 0;  // Number of pilots with Marking distance greater than Dm - normally 100km
  n4 := 0;  // Number of competitors who achieve a Handicapped Distance (Dh) of at least Dm/2
  Hmin := 100000;  // Lowest Handicap of all competitors in the class
  
  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    if UseHandicaps = 0 Then Pilots[i].Hcap := 1;
    if (UseHandicaps = 2) and (Auto_Hcaps_on = false) Then Pilots[i].Hcap := 1;

    if not Pilots[i].isHC Then
    begin
      if Pilots[i].Hcap < Hmin Then Hmin := Pilots[i].Hcap; // Lowest Handicap of all competitors in the class
    end;
  end;
  
  // Annex A version 2022 has removed the capability of Hmin in the results. Simply removing Hmin doesn't work for comps where Handicaps are given as 108, 125 etc. Hence this addition.
  if Hmin >= 500 then Hmin := 1000;                   // Not sure if there are any comps that uses Annex A rules with Handicaps over 10000?
  if (Hmin >= 50) and (Hmin < 500) then Hmin := 100; // For comps that use Handicaps typically between 70 and 130
  if (Hmin >= 5) and (Hmin < 50) then Hmin := 10;    // Just in case
  if (Hmin >= 0.5) and (Hmin < 5) then Hmin := 1;    // Typical IGC Annex A comps with handicaps around 1.000
  if (Hmin >= 0) and (Hmin < 0.5) then Hmin := Hmin; // Just in case

  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    if not Pilots[i].isHC Then
    begin
      if (Pilots[i].Hcap = 0) and (UseHandicaps <> 0) then
        begin
         info1 := 'Warning: Glider ' + Pilots[i].compID + ' ihas a hadicap 0, fix handicaps or set in script UseHandicaps=0';
         exit;
        end;
      if Pilots[i].dis*Hmin/Pilots[i].Hcap >= Dm Then n1 := n1+1;  // Competitors who have achieved at least Dm
      if Pilots[i].dis*Hmin/Pilots[i].Hcap >= ( Dm / 2.0) Then n4 := n4+1;  // Number of competitors who achieve a Handicapped Distance (Dh) of at least Dm/2
      if Pilots[i].takeoff >= 0 Then N := N+1;    // Number of competitors in the class having had a competition launch that Day
    end;
  end;
  if N=0 Then begin
          Info1 := '';
	  Info2 := 'Warning: Number of competition pilots launched is zero';
  	Exit;
  end;
  
  D0 := 0;
  T0 := 0;
  V0 := 0;
  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    if not Pilots[i].isHC Then
    begin
      // Find the highest Corrected distance
      if Pilots[i].dis*Hmin/Pilots[i].Hcap > D0 Then D0 := Pilots[i].dis*Hmin/Pilots[i].Hcap;
      
      // Find the highest finisher's speed of the day
      // and corresponding Task Time
      if Pilots[i].speed*Hmin/Pilots[i].Hcap = V0 Then // in case of a tie, lowest Task Time applies
      begin
        if (Pilots[i].finish-Pilots[i].start) < T0 Then
        begin
          V0 := Pilots[i].speed*Hmin/Pilots[i].Hcap;
          T0 := Pilots[i].finish-Pilots[i].start;
        end;
      end
      else
      begin
        if Pilots[i].speed*Hmin/Pilots[i].Hcap > V0 Then
        begin
          V0 := Pilots[i].speed*Hmin/Pilots[i].Hcap;
          T0 := Pilots[i].finish-Pilots[i].start;
          if (AAT = true) and (T0 < Task.TaskTime) Then       // if marking time is shorter than Task time, Task time must be used for computations
            T0 := Task.TaskTime;
        end;
      end;
    end;
  end;

  if D0=0 Then begin
	  Info1 := '';
          Info2 := 'Warning: Longest handicapped distance is zero';
  	Exit;
  end;
  
  // Maximum available points for the Day
  PmaxDistance := 1250 * (D0/D1) - 250;
  PmaxTime := (400*T0/3600.0)-200;
  if T0 <= 0 Then PmaxTime := 1000;
  Pm := MinValue( PmaxDistance, PmaxTime, 1000.0 );
  
  // Day Factor
  F := 1.25* n1/N;
  if F>1 Then F := 1;
  
  // Number of competitors who have achieved at least 2/3 of best speed for the day V0
  n2 := 0;
  // Number of finishers, regardless of speed
  n3 := 0;

  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    if not Pilots[i].isHC Then
    begin
      // n3 to count only finishers...
      if Pilots[i].finish > 0 Then n3 := n3+1;
      if Pilots[i].speed*Hmin/Pilots[i].Hcap > (2.0/3.0*V0) Then
      begin
        n2 := n2+1;
      end;
    end;
  end;
  
  // Completion Ratio Factor
  Fcr := 1;
  if n1 > 0 then
    Fcr := 1.2*(n2/n1)+0.6;
  if Fcr>1 Then Fcr := 1;

  Pvm := 2.0/3.0 * (n2/N) * Pm;  // maximum available Speed Points for the Day
  Pdm := Pm-Pvm;                 // maximum available Distance Points for the Day
  
  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    // For any finisher
    if Pilots[i].finish > 0 Then
    begin
      Pv := Pvm * (Pilots[i].speed*Hmin/Pilots[i].Hcap - 2.0/3.0*V0)/(1.0/3.0*V0);
      if Pilots[i].speed*Hmin/Pilots[i].Hcap < (2.0/3.0*V0) Then Pv := 0;
      Pd := Pdm;
    end
    else
    //For any non-finisher
    begin
      Pv := 0;
      Pd := Pdm * (Pilots[i].dis*Hmin/Pilots[i].Hcap/D0);
    end;
    
    // Pilot's score - can't be negative after penalties
    Pilots[i].Points := Round( F*Fcr*(Pd+Pv) - Pilots[i].Penalty );
    if Pilots[i].Points < 0 Then
      Pilots[i].Points := 0
  end;
  
  // Data which is presented in the score-sheets
  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    Pilots[i].sstart:=Pilots[i].start;
    Pilots[i].sfinish:=Pilots[i].finish;
    Pilots[i].sdis:=Pilots[i].dis;
    Pilots[i].sspeed:=Pilots[i].speed;
  end;
  
  // Info fields, also presented on the Score Sheets
  if AAT = true Then
    Info1 := 'Assigned Area Task, '
  else
    Info1 := 'Racing Task, ';

  Info1 := Info1 + 'Maximum Points: '+IntToStr(Round(Pm));
  Info1 := Info1 + ', F = '+FormatFloat('0.000',F);
  Info1 := Info1 + ', Fcr = '+FormatFloat('0.000',Fcr);
  Info1 := Info1 + ', Max speed pts: '+IntToStr(Round(Pvm));

  if (n1/N) <= 0.25 then
    Info1 := 'Day not valid - rule 8.2.1b';

  Info2 := 'Dm = ' + IntToStr(Round(Dm/1000.0)) + 'km';
  Info2 := Info2 + ', D1 = ' + IntToStr(Round(D1/1000.0)) + 'km';
  if (UseHandicaps = 0) or ((UseHandicaps = 2) and (Auto_Hcaps_on = false)) Then
    Info2 := Info2 + ', no handicaps'
  else
    Info2 := Info2 + ', handicapping enabled';

  // for debugging:
  Info3 := Info3 +' N: ' + IntToStr(Round(N));
  Info3 := Info3 + ', n1: ' + IntToStr(Round(n1));
  Info3 := Info3 + ', n2: ' + IntToStr(Round(n2));
  Info3 := Info3 + ', Do: ' + FormatFloat('0.00',D0/1000.0) + 'km';
  Info3 := Info3 + ', Vo: ' + FormatFloat('0.00',V0*3.6) + 'km/h';

  
  // Give out PEV as Warnings
  // PevStartTimeBuffer is set to 30
  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    Pilots[i].Warning := ''; 
    PevFault := false;
    if (Pilots[i].start > 0) Then
    begin	
      if (PEVWaitTime>0) and (PEVStartWindow>0) then   
      begin
        PevWarning:='';
        PevCount:=0; LastPev:=0;
        Ignore_PEV:=false;

        for j:=0 to GetArrayLength(Pilots[i].Markers)-1 do
        begin
          Ignore_Pev:= ((Pilots[i].Markers[j].Tsec-LastPev<=PevStartTimeBuffer) and (Lastpev>0)) or (Pevcount=3) or (Pilots[i].Markers[j].Tsec > Pilots[i].Start);
          if Ignore_Pev Then
             begin
               PevWarning := PevWarning + ' (PEV ignored='+ GetTimestring(Pilots[i].Markers[j].Tsec) +'!), ';
             end
          else
             begin
               PevCount:=PevCount+1;
               LastPev:= Pilots[i].Markers[j].Tsec;
               PevWarning := PevWarning + 'PEV'+IntTostr(Pevcount)+'='+ GetTimestring(Pilots[i].Markers[j].Tsec)+', ';
             end;
        end;
        
        if PEVCount>0 Then 
        begin
          PevStartNotValid:=(Trunc(Pilots[i].Start)<(LastPEV+PEVWaitTime)) or (Trunc(Pilots[i].Start)>(LastPEV+PEVWaitTime+PEVStartWindow));
          if PevStartNotValid Then
            begin
               PevFault := true;
               PevWarning:=PevWarning+' Start='+GetTimestring(Trunc(Pilots[i].Start))+' PEV Gate not open!'+', ' ;

               if (Trunc(Pilots[i].Start) < (LastPEV+PEVWaitTime)) Then
                 PevWarning := PevWarning + '(' + IntToStr(LastPEV+PEVWaitTime - Trunc(Pilots[i].Start)) + 's too early)'
               else
                 PevWarning := PevWarning + '(' + IntToStr(Trunc(Pilots[i].Start) - (LastPEV+PEVWaitTime+PEVStartWindow)) + 's too late)'

            end
          else
            if (Pilots[i].start>=Task.NoStartBeforeTime) Then
              PevWarning:=PevWarning+' Start='+GetTimestring(Trunc(Pilots[i].Start))+' OK'+', '; 
        end
        else
           begin
             PevWarning:='PEV not found!'+', ';
             PevFault := true;
           end;
      end;
      if Pilots[i].start<Task.NoStartBeforeTime then
      begin
        PevWarning := PevWarning + #10' Start='+GetTimestring(Trunc(Pilots[i].start))+' before gate opens!'+', ';
        PevFault := true;
      end;

      if (PevFault) OR (PevUserWrng = 1) Then
        Pilots[i].Warning:= Pilots[i].Warning + PevWarning;     
    end;
  end;

  // PEV - check and alert for possible starts after chosen one
  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    for j:=0 to GetArrayLength(Pilots[i].PotStarts)-1 do
      begin
        if (Pilots[i].PotStarts[j] > Pilots[i].Start+5) Then
          Pilots[i].Warning := Pilots[i].Warning+  #10'Possible next start:' +GetTimestring(Trunc(Pilots[i].PotStarts[j]));
    end;
  end;


  // Cylinder start - check if Pilots[i].start is same as PEV
  //    (reusing PevFault variable)
  if CylinderStart = 1 Then
  begin
    for i:=0 to GetArrayLength(Pilots)-1 do
    begin
      if (Trunc(Pilots[i].start) = -1) Then
        continue;

      PevFault := true;
      for j:=0 to GetArrayLength(Pilots[i].Markers)-1 do
      begin
        // allow +/-1 second difference due SeeYou Competition bug
        if (Abs(Pilots[i].Markers[j].Tsec - Trunc(Pilots[i].start)) <= 1) Then
          PevFault := false
      end;

      if PevFault = true Then
        Pilots[i].Warning := Pilots[i].Warning+  #10'Check cylinder start: no PEV found at the start time';

    end;
  end;



  // Loss of Height calculation
  if MaxLoH>=0 Then
  begin
    for i:=0 to GetArrayLength(Pilots)-1 do
    begin
      if (Pilots[i].finish > 0) and (Pilots[i].start > 0) Then
      begin
         for j := 0 to GetArrayLength(Pilots[i].Fixes)-1 do
         begin
           if Pilots[i].Fixes[j].Tsec >= Pilots[i].start Then
           begin
             if Pilots[i].Fixes[j].Tsec = Pilots[i].start Then	// exact fix
               PilotStartAlt := Pilots[i].Fixes[j].AltQnh
             else
               PilotStartAlt := Pilots[i].Fixes[j-1].AltQnh
                                + ((Pilots[i].Fixes[j].AltQnh - Pilots[i].Fixes[j-1].AltQnh)/(Pilots[i].Fixes[j].Tsec - Pilots[i].Fixes[j-1].Tsec))
                                * (Pilots[i].start - Pilots[i].Fixes[j-1].Tsec);

             if (PilotStartAlt - Pilots[i].FinishAlt > MaxLoH) Then
			 begin
               Pilots[i].Warning := Pilots[i].Warning+ #10 + 'LoH exceeded (' + IntToStr(Round(PilotStartAlt - Pilots[i].FinishAlt)) + 'm)';
			 end;

             break;
           end;
         end;
      end;
    end;
  end;


  // +/- 8 sec start speed interpolation if variable MaxStartSpeed is set by daytag "MaxStSpd= " to values >0
  // NOTE: this is not exactly compliant with Annex A defition
  if MaxStartSpeed>0 Then 
  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    PilotStartSpeed := 0;
	PilotStartSpeedSum := 0;
	PilotStartSpeedFixes := 0;	
	if (Pilots[i].start > 0) Then
	begin
	  for j := 0 to GetArrayLength(Pilots[i].Fixes)-1 do
	  begin
	    if (Pilots[i].Fixes[j].Tsec >= Pilots[i].start-7) and (Pilots[i].Fixes[j].Tsec <= Pilots[i].start+8) Then
		begin
		  PilotStartSpeedSum := PilotStartSpeedSum + Pilots[i].Fixes[j].Gsp;
		  PilotStartSpeedFixes := PilotStartSpeedFixes + 1;
	    end;
	  end;

      if PilotStartSpeedfixes>0 then 
	    PilotStartSpeed := PilotStartSpeedSum / PilotStartSpeedFixes;
      if (Round(PilotStartSpeed*3.6) > MaxStartSpeed) Then begin
        if Pilots[i].Warning <> '' then Pilots[i].Warning := Pilots[i].Warning+ #10;
	      Pilots[i].Warning := Pilots[i].Warning+ 'Startspeed=' + FloatToStr(Round(PilotStartSpeed*3.6)) + ' km/h-> ' + FloatToStr(Round(PilotStartSpeed*3.6)- MaxStartSpeed) + ' km/h too fast';
      end;
    end;
  end;

  // Support for 7.4.5b Starting Procedures - Pre-start altitude
  // 
  if PreStartAltLimit > 0 then
  begin
    for i:=0 to GetArrayLength(Pilots)-1 do
    begin
      //if pilot has started check prestart    
      if (Pilots[i].start > 0) Then
      begin
        PreStartLimitOK := FALSE;
        j := 0;
        NbrFixes := GetArrayLength(Pilots[i].Fixes)-1;
        //skip through to start gate open
        if NbrFixes > 0 then
        begin
          while  (j < NbrFixes) and (Pilots[i].Fixes[j].TSec < Task.NoStartBeforeTime) do 
          begin
            j := J + 1;
          end;
          //now check for lowest altitude from start gate open to start
          if j <= NbrFixes then 
          begin
            MinPreStartAlt := Pilots[i].Fixes[j].AltQnh;
            MinPreStartAltTime := Pilots[i].Fixes[j].TSec;
          end;
          while (Pilots[i].Fixes[j].TSec <= Pilots[i].start) and (j < NbrFixes) and not(PreStartLimitOK) do 
          begin
            if Pilots[i].Fixes[j].AltQnh < MinPreStartAlt then 
            begin
              MinPreStartAlt := Pilots[i].Fixes[j].AltQnh;
              MinPreStartAltTime := Pilots[i].Fixes[j].TSec;
            end;
            if  Pilots[i].Fixes[j].AltQnh < PreStartAltLimit then 
            begin
              PreStartLimitOK := TRUE;
            end;
            j:=j+1
          end;
          if not(PreStartLimitOK) then 
          begin
            if Pilots[i].Warning <> '' then Pilots[i].Warning := Pilots[i].Warning + #10;
            Pilots[i].warning := Pilots[i].warning + 'Invalid PreStart Alt: ' + FloatToStr(round(MinPreStartAlt)) ;
            Pilots[i].warning := Pilots[i].warning + 'm at time: '  + GetTimestring(MinPreStartAltTime);
          end;
        end;
      end; 
    end;
  end;

  // altitude less than minimum altitude
  if (MinimumAlt <> 0 )  then
  begin
   // showmessage('start minimum alt.  MinAlt=' + FloatToStr(MinimumAlt));
    
    for i:=0 to GetArrayLength(Pilots)-1 do
    begin
        NbrFixes := GetArrayLength(Pilots[i].Fixes);
        if (NbrFixes > 0) then 
        begin
        // walk through until above minimum altitude for > 60 seconds on initial launch
          
          //showmessage('pilot:' + IntToStr(i) + ' NBRFIXES = ' + IntToStr(NbrFixes));
          j:=0;
          FixDuration := 0;
          LastFixTime := Pilots[i].Fixes[j].Tsec;
          while ((j < NbrFixes - 1) and (FixDuration < 60)) do 
          begin
            if (Pilots[i].Fixes[j].AltQnh >= MinimumAlt) then
            begin
              FixDuration := FixDuration + (Pilots[i].Fixes[j].Tsec - LastFixTime); 
            end
            else begin
              FixDuration := 0;
            end;
            LastFixTime := Pilots[i].Fixes[j].Tsec;
            j := j + 1;
          end;
          if (FixDuration >= 60) and (j < NbrFixes - 1) then
          begin
            LaunchAboveAltFix := j;
            //showmessage('pilot:' + IntToStr(i) + ' LaunchAboveAltFix = ' + IntToStr(LaunchAboveAltFix));

            // walk backward through until above minimum altitude for > 60 seconds on final glide
            j:=NbrFixes - 1;
            FixDuration := 0;
            if (j < NbrFixes - 1) then LastFixTime := Pilots[i].Fixes[j].Tsec;
            while ((j > LaunchAboveAltFix) and (FixDuration < 60)) do 
            begin
              if (Pilots[i].Fixes[j].AltQnh >= MinimumAlt) then
              begin
                FixDuration := FixDuration + (LastFixTime - Pilots[i].Fixes[j].Tsec ); 
              end
              else begin
                FixDuration := 0;
              end;
              LastFixTime := Pilots[i].Fixes[j].Tsec;
              j := j - 1;
            end;
            if ((FixDuration >= 60) and (j > LaunchAboveAltFix)) then
            begin
              FGAboveAltFix := j;
              //showmessage('pilot:' + IntToStr(i) + ' FGAboveAltFix = ' + IntToStr(FGAboveAltFix));
              // check between LaunchAboveAltFix to FGAboveAltFix to find points below 

              j := LaunchAboveAltFix;

              LowPoint := Pilots[i].Fixes[j].AltQnh;
              BelowAltFound := FALSE;
              //showmessage('pilot:' + IntToStr(i) + ' InitialLowPoint = ' + FloatToStr(LowPoint));
              while ((j < FGAboveAltFix) and Not(BelowAltFound)) do
              begin
                // showmessage('i:' + inttostr(i));
                // showmessage('j:' + inttostr(j));
                // showmessage('altqnh:' + floattostr(Pilots[i].Fixes[j].AltQnh));
                // showmessage('lowpoint:' + floattostr(LowPoint));
                
                if (j <= 0) or (j >=  NbrFixes - 2 ) then showmessage('pilot:' + IntToStr(i) +' bad j:' + inttostr(j) + ' LaunchAboveAltFix = ' + IntToStr(LaunchAboveAltFix) + ' FGAboveAltFix = ' + IntToStr(FGAboveAltFix) + ' NbrFixes' + IntToStr(NbrFixes));

                if (Pilots[i].Fixes[j].AltQnh < LowPoint) then 
                begin
                  LowPoint := Pilots[i].Fixes[j].AltQnh;
                  LowPointTsec := Pilots[i].Fixes[j].Tsec;
                end;
                if (Pilots[i].Fixes[j].AltQnh < MinimumAlt) then BelowAltFound := TRUE; 
                j := j+1;
              end;

              if (BelowAltFound) then 
              begin
                if Pilots[i].Warning <> '' then Pilots[i].Warning := Pilots[i].Warning + #10;
                Pilots[i].warning := Pilots[i].warning + 'First Below Minimum Alt: ' + FormatFloat('0.0',LowPoint) ;
                Pilots[i].warning := Pilots[i].warning + 'm at time: '  + GetTimestring(LowPointTsec);
              end;
              //showmessage('pilot:' + IntToStr(i) + ' LowPoint = ' + FloatToStr(LowPoint));
            end;
          end;
        end;
    end;  

    // 
  end;
  
end.
