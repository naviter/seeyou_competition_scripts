Program SC3A_scoring;
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
// Version 4.00, Date 22.03.2017
//   . Support for Designated start scoring (start gate intervals)
//   . Enter "Interval=10" in DayTag to have 10 minute gate time intervals
//   . Enter "NumIntervals=7" in DayTag to have 7 possible start gates (last one is exactly one hour after start gate opens). 
//   . Separate Tags with ; (required)
//   . Example of the above two with 13:00:00 entered as start gate. DayTag: "Inteval=10;NumIntervals=7" gives possible start times at 13:00, 13:10, 13:20, 13:30, 13:40, 13:50 and 14:00
//   . Buffer zone as a script parameter
// Version 3.30, Date 10.01.2013
//   . BugFix: Td exchanged with Task.TaskTime - This fix is critical for all versions of SeeYou later than SeeYou 4.2
// Version 3.20, Date 04.07.2008
// Version 3.0
//   . Added Hmin instead of H0. Score is now calculated using minimum handicap as opposed to maximum handicap as before
// Version 3.01
//   . Changed If Pilots[i].takeoff > 0 to If Pilots[i].takeoff >= 0. It is theoretically possible that one takes off at 00:00:00 UTC
//   . Changed If Pilots[i].start > 0 to If Pilots[i].start >= 0. It is theoretically possible that one starts at 00:00:00 UTC
// Version 3.10
//   . removed line because it doesn't exist in Annex A 2006:
// 			If Pilots[i].dis*Hmin/Pilots[i].Hcap < (2.0/3.0*D0) Then Pd := Pdm*Pilots[i].dis*Hmin/Pilots[i].Hcap/(2.0/3.0*D0);
// Version 3.20
//   . added warnings when Exit 

const UseHandicaps = 2;   // set to: 0 to disable handicapping, 1 to use handicaps, 2 is auto (handicaps only for club and multi-seat)

var
  Dm, D1,
  Dt, n1, n2, n3, n4, N, D0, Vo, T0, Hmin,
  Pm, Pdm, Pvm, Pn, F, Fcr, Day: Double;

  D, H, Dh, M, T, Dc, Pd, V, Vh, Pv, S : double;
  
  PmaxDistance, PmaxTime : double;
  
  i,j : integer;
  str : String;
  Interval, NumIntervals, GateIntervalPos, NumIntervalsPos, PilotStartInterval, PilotStartTime, PilotPEVStartTime, StartTimeBuffer : Integer;
  AAT : boolean;
  Auto_Hcaps_on : boolean;


Function MinValue( a,b,c : double ) : double;
var m : double;
begin
  m := a;
  If b < m Then m := b;
  If c < m Then m := c;

  MinValue := m;
end;

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

  If Task.TaskTime = 0 then
    AAT := false
  else
    AAT := true;

  If (AAT = true) AND (Task.TaskTime < 1800) then
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

  // Handicaps for club and 20m multi-seat class
  Auto_Hcaps_on := false;
  if Task.ClassID = 'club' Then Auto_Hcaps_on := true;
  if Task.ClassID = 'double_seater' Then Auto_Hcaps_on := true;

  // DESIGNATED START PROCEDURE
  // Read Gate Interval info from DayTag. Return zero if Intervals and NumIntervals are unparsable or missing
  
  StartTimeBuffer := 30; // Start time buffer zone. If one starts 30 seconds too early he is scored by his actual start time
  
  GateIntervalPos := Pos('Interval=',DayTag);
  NumIntervalsPos := Pos('NumIntervals=',DayTag);															// One separator is assumed and it is assumed that Interval will be the first parameter in DayTag.

  Interval := StrToInt( Copy(DayTag,GateIntervalPos+9,(NumIntervalsPos-GateIntervalPos-10)), 0 )*60;		// Interval length in seconds. Second parameter in IntToStr is fallback value
  NumIntervals := StrToInt( Copy(DayTag,NumIntervalsPos+13,5), 0 );											// Number of intervals

  if Interval > 0 Then
    Info3 := 'Start time interval = '+IntToStr(Interval div 60)+'min';
  if (Interval > 0) and (NumIntervals > 0) then																					// Only display number of intervals if it is not zero
    Info3 := Info3 + ', number of intervals = '+IntToStr(NumIntervals);
  
  // Adjust Pilot start times and speeds if Start Gate intervals are used
  if Interval > 0 Then
  begin
    for i:=0 to GetArrayLength(Pilots)-1 do
	begin
	  PilotStartInterval := Round(Pilots[i].start - Task.NoStartBeforeTime) div Interval;					// Start interval used by pilot. 0 = first interval = opening of the start line
	  PilotStartTime := Task.NoStartBeforeTime + PilotStartInterval * Interval;

	  If PilotStartInterval > (NumIntervals-1) Then PilotStartInterval := NumIntervals-1;					// Last start interval if pilot started late
	  If (Pilots[i].start > 0) and ((PilotStartTime + Interval - Pilots[i].start) > StartTimeBuffer) Then		// Check for buffer zone to next start interval
	  begin
        Pilots[i].start := PilotStartTime;
		if Pilots[i].speed > 0 Then
		  Pilots[i].speed := Pilots[i].dis / (Pilots[i].finish - Pilots[i].start);
	  end;																									// Else not required. If started in buffer zone actual times are used
	end;
  end;

  // Calculation of basic parameters
  N := 0;  // Number of pilots having had a competition launch
  n1 := 0;  // Number of pilots with Marking distance greater than Dm - normally 100km
  n4 := 0;  // Number of competitors who achieve a Handicapped Distance (Dh) of at least Dm/2
  Hmin := 100000;  // Lowest Handicap of all competitors in the class
  
  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    If UseHandicaps = 0 Then Pilots[i].Hcap := 1;
    If (UseHandicaps = 2) and (Auto_Hcaps_on = false) Then Pilots[i].Hcap := 1;

    If not Pilots[i].isHC Then
    begin
      If Pilots[i].Hcap < Hmin Then Hmin := Pilots[i].Hcap; // Lowest Handicap of all competitors in the class
    end;
  end;
  If Hmin=0 Then begin
          Info1 := '';
	  Info2 := 'Error: Lowest handicap is zero!';
  	Exit;
  end;

  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    If not Pilots[i].isHC Then
    begin
      If Pilots[i].dis*Hmin/Pilots[i].Hcap >= Dm Then n1 := n1+1;  // Competitors who have achieved at least Dm
      If Pilots[i].dis*Hmin/Pilots[i].Hcap >= ( Dm / 2.0) Then n4 := n4+1;  // Number of competitors who achieve a Handicapped Distance (Dh) of at least Dm/2
      If Pilots[i].takeoff >= 0 Then N := N+1;    // Number of competitors in the class having had a competition launch that Day
    end;
  end;
  If N=0 Then begin
          Info1 := '';
	  Info2 := 'Warning: Number of competition pilots launched is zero';
  	Exit;
  end;
  
  D0 := 0;
  T0 := 0;
  Vo := 0;
  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    If not Pilots[i].isHC Then
    begin
      // Find the highest Corrected distance
      If Pilots[i].dis*Hmin/Pilots[i].Hcap > D0 Then D0 := Pilots[i].dis*Hmin/Pilots[i].Hcap;
      
      // Find the highest finisher's speed of the day
      // and corresponding Task Time
      If Pilots[i].speed*Hmin/Pilots[i].Hcap = Vo Then // in case of a tie, lowest Task Time applies
      begin
        If (Pilots[i].finish-Pilots[i].start) < T0 Then
        begin
          Vo := Pilots[i].speed*Hmin/Pilots[i].Hcap;
          T0 := Pilots[i].finish-Pilots[i].start;
        end;
      end
      Else
      begin
        If Pilots[i].speed*Hmin/Pilots[i].Hcap > Vo Then
        begin
          Vo := Pilots[i].speed*Hmin/Pilots[i].Hcap;
          T0 := Pilots[i].finish-Pilots[i].start;
          If (AAT = true) and (T0 < Task.TaskTime) Then       // If marking time is shorter than Task time, Task time must be used for computations
            T0 := Task.TaskTime;
        end;
      end;
    end;
  end;

  If D0=0 Then begin
	  Info1 := '';
          Info2 := 'Warning: Longest handicapped distance is zero';
  	Exit;
  end;
  
  // Maximum available points for the Day
  PmaxDistance := 1250 * (D0/D1) - 250;
  PmaxTime := (400*T0/3600.0)-200;
  If T0 <= 0 Then PmaxTime := 1000;
  Pm := MinValue( PmaxDistance, PmaxTime, 1000.0 );
  
  // Day Factor
  F := 1.25* n1/N;
  If F>1 Then F := 1;
  
  // Number of competitors who have achieved at least 2/3 of best speed for the day Vo
  n2 := 0;
  // Number of finishers, regardless of speed
  n3 := 0;

  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    If not Pilots[i].isHC Then
    begin
      n3 := n3+1;
      If Pilots[i].speed*Hmin/Pilots[i].Hcap > (2.0/3.0*Vo) Then
      begin
        n2 := n2+1;
      end;
    end;
  end;
  
  // Completion Ratio Factor
  Fcr := 1;
  If n1 > 0 then
    Fcr := 1.2*(n2/n1)+0.6;
  If Fcr>1 Then Fcr := 1;

  Pvm := 2.0/3.0 * (n2/N) * Pm;  // maximum available Speed Points for the Day
  Pdm := Pm-Pvm;                 // maximum available Distance Points for the Day
  
  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    // For any finisher
    If Pilots[i].finish > 0 Then
    begin
      Pv := Pvm * (Pilots[i].speed*Hmin/Pilots[i].Hcap - 2.0/3.0*Vo)/(1.0/3.0*Vo);
      If Pilots[i].speed*Hmin/Pilots[i].Hcap < (2.0/3.0*Vo) Then Pv := 0;
      Pd := Pdm;
    end
    Else
    //For any non-finisher
    begin
      Pv := 0;
      Pd := Pdm * (Pilots[i].dis*Hmin/Pilots[i].Hcap/D0);
    end;
    
    // Pilot's score
    Pilots[i].Points := Round( F*Fcr*(Pd+Pv) - Pilots[i].Penalty );
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
  If AAT = true Then
    Info1 := 'Assigned Area Task, '
  else
    Info1 := 'Racing Task, ';

  Info1 := Info1 + 'Maximum Points: '+IntToStr(Round(Pm));
  Info1 := Info1 + ', F = '+FormatFloat('0.000',F);
  Info1 := Info1 + ', Fcr = '+FormatFloat('0.000',Fcr);
  Info1 := Info1 + ', Max speed pts: '+IntToStr(Round(Pvm));

  If (n1/N) < 0.25 then
    Info1 := 'Day not valid - rule 8.2.1b';

  Info2 := 'Dm = ' + IntToStr(Round(Dm/1000.0)) + 'km';
  Info2 := Info2 + ', D1 = ' + IntToStr(Round(D1/1000.0)) + 'km';
  If (UseHandicaps = 0) or ((UseHandicaps = 2) and (Auto_Hcaps_on = false)) Then
    Info2 := Info2 + ', no handicaps'
  else
    Info2 := Info2 + ', handicapping enabled';

  // for debugging:
  Info3 := 'N: ' + IntToStr(Round(N));
  Info3 := Info3 + ', n1: ' + IntToStr(Round(n1));
  Info3 := Info3 + ', n2: ' + IntToStr(Round(n2));
  Info3 := Info3 + ', Do: ' + FormatFloat('0.00',D0/1000.0) + 'km';
  Info3 := Info3 + ', Vo: ' + FormatFloat('0.00',Vo*3.6) + 'km/h';

end.
