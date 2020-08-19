Program eGlide_Elapsed_time_scoring_with_Distance_Handicapping;

const 
  Rmin = 500;         // Sector radius in meters that will be used by highest handicapped gliders.
  Rfinish = 0;        // Finish ring radius. Use zero if finish line is used.
  UseHandicaps = 2;   // set to: 0 to disable handicapping, 1 to use handicaps, 2 is auto (handicaps only for club and multi-seat)
  PowerTreshold = 20; // In Watts [W]. If Current*Voltage is less than that, it won't count towards consumed energy.
  RefVoltage = 110;   // Fallback if nothing else is known about voltage used when engine is running
  RefCurrent = 200;   // Fallback if nothing is known about current consumption
  FreeAllowance = 2000; // Watt-hours. No penalty if less power was consumed
  EnginePenaltyPerSec = 1000/15/60;    // Penalty in seconds per Watt-hour consumed over Free Allowance. 1000 Wh of energy allows you to cruise for 15 minutes.
  Fa = 1.2;           // Amount of time penalty for next finisher / outlander

var
  Dm, D1,
  Dt, n1, n2, n3, n4, N, D0, Vo, T0, Tm, Hmin,
  Pm, Pdm, Pvm, Pn, F, Fcr, Day: Double;

  D, H, Dh, M, T, Dc, Pd, V, Vh, Pv, S, R_hcap, PilotDis : double;
  
  PmaxDistance, PmaxTime, PilotEnergyConsumption, CurrentPower, PilotEngineTime, EnginePenalty  : double;
  
  i,j, minIdx : integer;
  str : String;
  Interval, NumIntervals, GateIntervalPos, NumIntervalsPos, PilotStartInterval, PilotStartTime, PilotPEVStartTime, StartTimeBuffer, PilotLegs, TaskPoints : Integer;
  AAT, TPRounded : boolean;
  Auto_Hcaps_on : boolean;

function Radius( Hcap:double ):double;
var 
  i : integer;
  R_hcap, Hmax, TaskDis, TaskLegs : double;
begin
  TaskDis := Task.TotalDis;
  TaskLegs := GetArrayLength(Task.Point)-1;

  Hmax := 0;
  for i := 0 to GetArrayLength(Pilots)-1 do 
  begin
    If not Pilots[i].isHC Then
    begin
      If Pilots[i].Hcap > Hmax Then Hmax := Pilots[i].Hcap; // Hightest Handicap of all competitors in the class
    end;
  end;
  If Hmax=0 Then 
  begin
    Info1 := '';
	  Info2 := 'Error: Highest handicap is zero!';
  	Exit;
  end;

  R_hcap := TaskDis/2/(TaskLegs-1)*(1-(Hcap/Hmax))+Hcap/Hmax*Rmin;
  R_hcap := Round(R_hcap/100)*100;

  Radius := R_hcap;
end;

begin
  // initial checks
  if GetArrayLength(Pilots) <= 1 then
    exit; 

  // Calculate Distance flown for each pilot depending Radius(Hcap)
  TaskPoints := GetArrayLength(Task.Point);

  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    PilotDis := 0;
    PilotLegs := GetArrayLength(Pilots[i].Leg);
    Pilots[i].Warning := '';
  
    // Calculate Handicapped turnpoint radius for this particular pilot's Handicap
    R_hcap := Radius(Pilots[i].hcap);

    //! Debug output
    Pilots[i].Warning := Pilots[i].Warning + 'R_hcap: ' + FormatFloat('0',Radius(Pilots[i].hcap))+' m; ';
    Pilots[i].Warning := Pilots[i].Warning + #10 + 'Task points: ' + IntToStr(TaskPoints)+'; ';
    Pilots[i].Warning := Pilots[i].Warning + #10 + 'Pilot legs: ' + IntToStr(GetArrayLength(Pilots[i].Leg))+'; ';
    for j:=0 to GetArrayLength(Pilots[i].Leg)-1 do
    begin
      Pilots[i].Warning := Pilots[i].Warning + #10 + 'Leg['+IntToStr(j)+']: DisToTP = ' + FormatFloat('0',Pilots[i].Leg[j].DisToTp) + '; PilotLegDis = ' + FormatFloat('0',Pilots[i].Leg[j].d) + '; LegDis = ' + FormatFloat('0',Task.Point[j].d);
    end;

    // Set start time for all competitiors to the designated time of the Grand-Prix start gate
    Pilots[i].start := Task.NoStartBeforeTime;

    // Calculate flown distance according to Radius(Pilots[i].hcap)
    TPRounded := true;
    if GetArrayLength(Pilots[i].Leg) > 0 then
    begin
      for j:=0 to GetArrayLength(Pilots[i].Leg)-1 do
      begin
        if TPRounded then
        begin
          case j of
            // Start leg
            0 : 
            begin 
              if (PilotLegs >= j+1) then
              begin
                if Pilots[i].Leg[j].DisToTP <= R_hcap then
                  PilotDis := PilotDis + Pilots[i].Leg[j].d - R_hcap
                else
                begin
                  PilotDis := PilotDis + Pilots[i].Leg[j].d - Pilots[i].Leg[j].DisToTP;
                  TPRounded := false;
                end;
              end
              else
              begin
                PilotDis := PilotDis + Pilots[i].Leg[j].d;
                TPRounded := false;
              end;
              //! Debug output
              Pilots[i].Warning := Pilots[i].Warning + #10 + 'Start';
            end;

            // Finish leg
            (TaskPoints-2)  : 
            begin 
              if Pilots[i].finish > 0 then
              begin
                PilotDis := PilotDis + Pilots[i].Leg[j].d - R_hcap - Rfinish; 
              end
              else
              begin
                PilotDis := PilotDis + Pilots[i].Leg[j].d; 
              end;
              //! Debug output
              Pilots[i].Warning := Pilots[i].Warning + #10 + 'Finish';
            end;
          else
            begin
              // Intermediate legs
              //TODO Must check if R_hcap was reached before adding PilotDis. If not, outland the pilot at that turnpoint.
              if (PilotLegs >= j+1) then
              begin
                PilotDis := PilotDis + Pilots[i].Leg[j].d - 2*R_hcap;
              end
              else
              begin
                PilotDis := PilotDis + Pilots[i].Leg[j].d - R_hcap;
                TPRounded := false;
              end;
              //! Debug output
              Pilots[i].Warning := Pilots[i].Warning + #10 + 'Point';
            end;
          end;
        end;
      end;
    end
    else
    begin
      // Less than 1 leg in Pilots[i].Leg
      //TODO Do we need to handle this case?
    end;

    //! Debug output
    Pilots[i].Warning := Pilots[i].Warning + #10 + 'PilotDis = ' + FormatFloat('0',PilotDis);
  end;


  Hmin := 100000;  // Lowest Handicap of all competitors in the class
  T0 := 10000000;
  Tm := 0; // slowest finisher time
  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    if Pilots[i].finish > 0 Then
    begin
      Pilots[i].speed := Pilots[i].dis / (Pilots[i].finish-Pilots[i].start);
    end;
    If not Pilots[i].isHC Then
    begin
      If Pilots[i].Hcap < Hmin Then Hmin := Pilots[i].Hcap; // Lowest Handicap of all competitors in the class
    end;
  end;
  If Hmin=0 Then 
  begin
    Info1 := '';
	  Info2 := 'Error: Lowest handicap is zero!';
  	Exit;
  end;

  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    If not Pilots[i].isHC Then
    begin
      // Find the lowest task time
      T := (Pilots[i].finish-Pilots[i].start) * Pilots[i].Hcap/Hmin;
      If (T < T0) and (Pilots[i].finish > 0) Then
      begin
        T0 := T;
        minIdx := i;
      end;

      // Find the slowest finisher
      if T > Tm Then
      begin
        Tm := T;
      end;
    end;
  end;













//! TEMPORARY END OF SCRIPT EXECUTION
exit;

  // Energy Consumption by pilot on task
  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    Pilots[i].Warning := '';
    PilotEnergyConsumption := 0;
  	PilotEngineTime := 0;

	for j := 0 to GetArrayLength(Pilots[i].Fixes)-1 do
	begin
	  if (Pilots[i].Fixes[j].Tsec > Pilots[i].start) and (Pilots[i].Fixes[j].Tsec < Pilots[i].finish) Then
	  begin
	    // If pilot has Cur and Vol
		if Pilots[i].HasCur then
		begin
			if not Pilots[i].HasVol Then
				Pilots[i].Fixes[j].Vol := RefVoltage;
			if (Pilots[i].Fixes[j].Cur > 0) and (Pilots[i].Fixes[j].Vol > 0) then
			begin
				CurrentPower := Pilots[i].Fixes[j].Cur * Pilots[i].Fixes[j].Vol;
				If CurrentPower > PowerTreshold then
				begin
					PilotEngineTime := PilotEngineTime + Pilots[i].Fixes[j+1].Tsec - Pilots[i].Fixes[j].Tsec;
	//				Pilots[i].Warning := Pilots[i].Warning + IntToStr(Round(Pilots[i].Fixes[j].Cur))+ ' * ' + IntToStr(Round(Pilots[i].Fixes[j].Vol)) + ' * ' + IntToStr(Pilots[i].Fixes[j+1].Tsec - Pilots[i].Fixes[j].Tsec) + #10;
					PilotEnergyConsumption := PilotEnergyConsumption + CurrentPower * (Pilots[i].Fixes[j+1].Tsec - Pilots[i].Fixes[j].Tsec) / 3600;
					Pilots[i].td1 := PilotEnergyConsumption;
				end;
			end;
		end
		else
		begin
			If Pilots[i].Fixes[j].EngineOn Then
			begin
				CurrentPower := RefCurrent * RefVoltage;
				PilotEngineTime := PilotEngineTime + Pilots[i].Fixes[j+1].Tsec - Pilots[i].Fixes[j].Tsec;
//				Pilots[i].Warning := Pilots[i].Warning + IntToStr(Round(Pilots[i].Fixes[j].Cur))+ ' * ' + IntToStr(Round(Pilots[i].Fixes[j].Vol)) + ' * ' + IntToStr(Pilots[i].Fixes[j+1].Tsec - Pilots[i].Fixes[j].Tsec) + #10;
				PilotEnergyConsumption := PilotEnergyConsumption + CurrentPower * (Pilots[i].Fixes[j+1].Tsec - Pilots[i].Fixes[j].Tsec) / 3600;
				Pilots[i].td1 := PilotEnergyConsumption;
			end;
		end;
	  end;
	end;

//	// Debug output
//	if Pilots[i].HasCur Then 
//      Pilots[i].Warning := Pilots[i].Warning + 'HasCur = 1'+#10
//	else
//      Pilots[i].Warning := Pilots[i].Warning + 'HasCur = 0'+#10;
//	if Pilots[i].HasVol Then 
//      Pilots[i].Warning := Pilots[i].Warning + 'HasVol = 1'+#10
//	else
//      Pilots[i].Warning := Pilots[i].Warning + 'HasVol = 0'+#10;
//	if Pilots[i].HasEnl Then 
//      Pilots[i].Warning := Pilots[i].Warning + 'HasEnl = 1'+#10
//	else
//      Pilots[i].Warning := Pilots[i].Warning + 'HasEnl = 0'+#10;
//	if Pilots[i].HasMop Then 
//      Pilots[i].Warning := Pilots[i].Warning + 'HasMop = 1'+#10
//	else
//      Pilots[i].Warning := Pilots[i].Warning + 'HasMop = 0'+#10;
	Pilots[i].Warning := Pilots[i].Warning + 'EngineTime = ' + IntToStr(Round(PilotEngineTime)) + ' s' + #10;
	Pilots[i].Warning := Pilots[i].Warning + 'PowerConsumption = ' + IntToStr(Round(PilotEnergyConsumption)) + ' Wh' +#10;
	if PilotEnergyConsumption > FreeAllowance then
	  Pilots[i].Warning := Pilots[i].Warning 
	    + 'Engine Penalty = ' + IntToStr(Round(PilotEnergyConsumption-FreeAllowance)) + ' Wh = ' 
	    + FormatFloat('0.00',((PilotEnergyConsumption - FreeAllowance) * EnginePenaltyPerSec / 60)) + ' minutes' 
		+#10;
  end;

  
  // ELAPSED TIME SCORING
  for i:=0 to GetArrayLength(Pilots)-1 do 
  begin
    if Pilots[i].finish > 0 then
	begin
      Pilots[i].Points := -1.0*((Pilots[i].finish - Pilots[i].start)*Pilots[i].Hcap/Hmin - T0)/60;
	end
	else
	begin
	  // Outlanders get 1.2 x the slowest finisher
      Pilots[i].Points := (-1.0*Tm*Fa + T0)/60;
	end;

    // Engine penalty
    PilotEnergyConsumption := Pilots[i].td1;
    if PilotEnergyConsumption > FreeAllowance then
	begin
	  EnginePenalty := (PilotEnergyConsumption - FreeAllowance) * EnginePenaltyPerSec / 60; // Penalty in minutes
	  Pilots[i].Points := Pilots[i].Points - EnginePenalty;
	end;
	
	//Worst score a pilot can get is 1.2 times the last finisher's time.
	if Pilots[i].Points < (-1.0*Tm*Fa+T0)/60 Then
	  Pilots[i].Points := (-1.0*Tm*Fa+T0)/60;
	  
	Pilots[i].Points := Round((Pilots[i].Points- Pilots[i].Penalty/60)*100)/100; // Expected penalty is in seconds
  end;
  
  // Data which is presented in the score-sheets
  for i:=0 to GetArrayLength(Pilots)-1 do
  begin
    Pilots[i].sstart:=Pilots[i].start;
    Pilots[i].sfinish:=Pilots[i].finish;
    Pilots[i].sdis:=Pilots[i].dis;
    Pilots[i].sspeed:=Pilots[i].speed;
  end;
//  Pilots[minIdx].Points := Round(T0/60*100)/100;
  
  // Info fields, also presented on the Score Sheets
  Info1 := 'Elapsed time race';
  Info1 := Info1 + ', results in minutes behind leader, handicapped'; 

end.